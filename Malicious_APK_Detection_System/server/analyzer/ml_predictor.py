"""
Machine Learning based Malware Prediction
"""
import logging
import os
import pickle
import numpy as np
from typing import Dict, List, Any

logger = logging.getLogger(__name__)


class MalwarePredictor:
    """ML-based malware detection using trained model"""
    
    def __init__(self, model_path='models/malware_model.pkl'):
        self.model = None
        self.model_path = model_path
        self.model_available = False
        self._load_model()
    
    def _load_model(self):
        """Load trained ML model"""
        try:
            if os.path.exists(self.model_path):
                with open(self.model_path, 'rb') as f:
                    self.model = pickle.load(f)
                self.model_available = True
                logger.info(f"ML model loaded from {self.model_path}")
            else:
                logger.warning(f"ML model not found at {self.model_path}")
                logger.info("Using rule-based fallback prediction")
        except Exception as e:
            logger.error(f"Failed to load ML model: {str(e)}")
    
    def predict(self, features: List[float]) -> Dict[str, Any]:
        """
        Predict if APK is malicious
        """
        try:
            if self.model_available and self.model:
                return self._predict_with_model(features)
            else:
                return self._predict_rule_based(features)
        except Exception as e:
            logger.error(f"Prediction failed: {str(e)}")
            return {
                'is_malware': False,
                'confidence': 0.0,
                'malware_type': 'Unknown',
                'error': str(e)
            }
    
    def _predict_with_model(self, features: List[float]) -> Dict[str, Any]:
        """Predict using trained ML model"""
        try:
            # Ensure features is numpy array with correct shape
            features_array = np.array(features).reshape(1, -1)
            
            # Get prediction
            prediction = self.model.predict(features_array)[0]
            
            # Get probability if available
            if hasattr(self.model, 'predict_proba'):
                probabilities = self.model.predict_proba(features_array)[0]
                confidence = float(max(probabilities))
            else:
                confidence = 0.85 if prediction == 1 else 0.15
            
            # Determine malware type based on features
            malware_type = self._determine_malware_type(features, prediction)
            
            return {
                'is_malware': bool(prediction),
                'confidence': round(confidence, 2),
                'malware_type': malware_type,
                'method': 'ml_model'
            }
        except Exception as e:
            logger.error(f"ML prediction failed: {str(e)}")
            return self._predict_rule_based(features)
    
    def _predict_rule_based(self, features: List[float]) -> Dict[str, Any]:
        """
        Fallback rule-based prediction
        Analyzes feature vector using heuristic rules
        """
        risk_score = 0
        indicators = []
        
        # Check dangerous permissions (first 40 features)
        dangerous_perms = sum(features[:40])
        
        # SMS permissions (high risk)
        if features[1] or features[2] or features[3]:  # SEND_SMS, RECEIVE_SMS, READ_SMS
            risk_score += 15
            indicators.append('SMS access')
        
        # Contact/location permissions
        if features[4] or features[5]:  # READ_CONTACTS, WRITE_CONTACTS
            risk_score += 8
            indicators.append('Contact access')
        
        if features[6] or features[7]:  # Location permissions
            risk_score += 5
            indicators.append('Location tracking')
        
        # Phone state and calls
        if features[10] or features[11]:  # READ_PHONE_STATE, CALL_PHONE
            risk_score += 10
            indicators.append('Phone state access')
        
        # Installation permissions (very high risk)
        if features[14] or features[15] or features[19]:  # Install/delete packages
            risk_score += 20
            indicators.append('Package installation capability')
        
        # Device admin (high risk)
        if features[20]:  # BIND_DEVICE_ADMIN
            risk_score += 18
            indicators.append('Device admin privileges')
        
        # Boot receiver (persistence)
        if features[21]:  # RECEIVE_BOOT_COMPLETED
            risk_score += 10
            indicators.append('Auto-start capability')
        
        # Suspicious features (features 44-49)
        if features[44]:  # Dynamic code loading
            risk_score += 12
            indicators.append('Dynamic code loading')
        
        if features[46]:  # Native code
            risk_score += 8
            indicators.append('Native code')
        
        if features[47]:  # Reflection
            risk_score += 7
            indicators.append('Code reflection')
        
        # Check for dangerous combinations
        if features[1] and features[10]:  # SMS + Phone state
            risk_score += 15
            indicators.append('Premium SMS fraud pattern')
        
        if features[0] and features[4] and features[6]:  # Internet + Contacts + Location
            risk_score += 10
            indicators.append('Data exfiltration pattern')
        
        # Determine result
        is_malware = risk_score >= 30
        confidence = min(risk_score / 100.0, 0.95)
        
        # Determine malware type
        malware_type = self._determine_malware_type(features, is_malware)
        
        return {
            'is_malware': is_malware,
            'confidence': round(confidence, 2),
            'malware_type': malware_type,
            'risk_indicators': indicators,
            'method': 'rule_based'
        }
    
    def _determine_malware_type(self, features: List[float], is_malware: bool) -> str:
        """Determine type of malware based on features"""
        if not is_malware:
            return 'Benign'
        
        # SMS-based malware
        if features[1] or features[2]:  # SMS permissions
            return 'SMS Trojan / Premium SMS Fraud'
        
        # Banking trojan indicators
        if features[16] and features[20]:  # Overlay + Device admin
            return 'Banking Trojan'
        
        # Spyware indicators
        if (features[4] or features[6] or features[8]) and features[0]:  # Contact/Location/Audio + Internet
            return 'Spyware / Information Stealer'
        
        # Ransomware indicators
        if features[20] and features[16]:  # Device admin + Overlay
            return 'Ransomware'
        
        # Adware indicators
        if features[0] and not any(features[1:10]):  # Only internet permission
            return 'Adware'
        
        # Backdoor/RAT indicators
        if features[44] or features[47]:  # Dynamic loading or reflection
            return 'Backdoor / Remote Access Trojan'
        
        # Generic malware
        return 'Generic Malware'
