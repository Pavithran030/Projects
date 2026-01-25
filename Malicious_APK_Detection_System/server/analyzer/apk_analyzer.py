"""
APK Static Analysis Engine using Androguard
"""
import logging
from typing import Dict, List, Any
import re
import hashlib
from datetime import datetime

logger = logging.getLogger(__name__)


class APKAnalyzer:
    """Analyzes APK files for malicious indicators"""
    
    # Dangerous permissions that require attention
    DANGEROUS_PERMISSIONS = {
        'SEND_SMS', 'RECEIVE_SMS', 'READ_SMS', 'WRITE_SMS',
        'READ_CONTACTS', 'WRITE_CONTACTS',
        'ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION',
        'RECORD_AUDIO', 'CAMERA',
        'READ_PHONE_STATE', 'CALL_PHONE',
        'READ_CALL_LOG', 'WRITE_CALL_LOG',
        'INSTALL_PACKAGES', 'DELETE_PACKAGES',
        'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
        'SYSTEM_ALERT_WINDOW',
        'REQUEST_INSTALL_PACKAGES',
        'BIND_DEVICE_ADMIN',
        'MOUNT_UNMOUNT_FILESYSTEMS',
        'WRITE_SETTINGS'
    }
    
    # Suspicious API calls
    SUSPICIOUS_APIS = [
        'getDeviceId', 'getSubscriberId', 'getSimSerialNumber',
        'sendTextMessage', 'sendDataMessage',
        'Runtime.exec', 'ProcessBuilder',
        'DexClassLoader', 'PathClassLoader',
        'HttpURLConnection', 'HttpClient',
        'TelephonyManager', 'SmsManager',
        'getInstalledPackages', 'getRunningProcesses',
        'KeyStore', 'Cipher'
    ]
    
    def __init__(self):
        self.androguard_available = False
        try:
            from androguard.core.bytecodes.apk import APK
            from androguard.core.bytecodes.dvm import DalvikVMFormat
            from androguard.core.analysis.analysis import Analysis
            self.APK = APK
            self.DalvikVMFormat = DalvikVMFormat
            self.Analysis = Analysis
            self.androguard_available = True
            logger.info("Androguard loaded successfully")
        except ImportError:
            logger.warning("Androguard not available - using fallback analysis")
    
    def analyze(self, apk_path: str) -> Dict[str, Any]:
        """
        Perform comprehensive static analysis on APK
        """
        try:
            if self.androguard_available:
                return self._analyze_with_androguard(apk_path)
            else:
                return self._analyze_fallback(apk_path)
        except Exception as e:
            logger.error(f"Analysis failed: {str(e)}", exc_info=True)
            return {
                'success': False,
                'error': str(e)
            }
    
    def _analyze_with_androguard(self, apk_path: str) -> Dict[str, Any]:
        """Full analysis using Androguard"""
        try:
            # Load APK
            apk = self.APK(apk_path)
            
            # Extract basic information
            package_name = apk.get_package()
            app_name = apk.get_app_name()
            version_name = apk.get_androidversion_name()
            version_code = apk.get_androidversion_code()
            min_sdk = apk.get_min_sdk_version()
            target_sdk = apk.get_target_sdk_version()
            
            # Extract permissions
            permissions = apk.get_permissions()
            dangerous_permissions = self._identify_dangerous_permissions(permissions)
            
            # Extract components
            activities = apk.get_activities()
            services = apk.get_services()
            receivers = apk.get_receivers()
            providers = apk.get_providers()
            
            # Look for suspicious features
            suspicious_features = self._identify_suspicious_features(apk)
            
            # Extract URLs
            urls = self._extract_urls(apk)
            
            # Verify source and certificate
            source_verification = self.verify_source(apk)
            
            # Build feature vector for ML
            feature_vector = self._build_feature_vector(
                permissions, activities, services, receivers, 
                providers, suspicious_features
            )
            
            return {
                'success': True,
                'package_name': package_name,
                'app_name': app_name,
                'version_name': version_name,
                'version_code': version_code,
                'min_sdk': min_sdk,
                'target_sdk': target_sdk,
                'permissions': permissions,
                'dangerous_permissions': dangerous_permissions,
                'activities': activities[:10],  # Limit for response size
                'services': services[:10],
                'receivers': receivers[:10],
                'providers': providers,
                'suspicious_features': suspicious_features,
                'urls': urls[:20],  # Limit URLs
                'source_verification': source_verification,  # NEW
                'features': feature_vector,
                'total_activities': len(activities),
                'total_services': len(services),
                'total_receivers': len(receivers),
            }
        except Exception as e:
            logger.error(f"Androguard analysis failed: {str(e)}")
            return self._analyze_fallback(apk_path)
    
    def _analyze_fallback(self, apk_path: str) -> Dict[str, Any]:
        """
        Fallback analysis when Androguard is not available
        Uses basic file analysis
        """
        import zipfile
        import os
        
        try:
            file_size = os.path.getsize(apk_path)
            
            # Try to open as ZIP
            with zipfile.ZipFile(apk_path, 'r') as zip_ref:
                file_list = zip_ref.namelist()
                
                # Look for suspicious files
                suspicious_files = []
                if any('native' in f.lower() for f in file_list):
                    suspicious_files.append('Native libraries detected')
                if any('.so' in f for f in file_list):
                    suspicious_files.append('Compiled native code (.so files)')
                if any('assets' in f.lower() for f in file_list):
                    suspicious_files.append('Asset files present')
                
                # Build minimal feature vector
                feature_vector = self._build_minimal_feature_vector(file_list)
                
                return {
                    'success': True,
                    'package_name': 'Unknown (Androguard not available)',
                    'app_name': 'Unknown',
                    'version_name': 'Unknown',
                    'version_code': 'Unknown',
                    'min_sdk': 'Unknown',
                    'target_sdk': 'Unknown',
                    'file_size': file_size,
                    'total_files': len(file_list),
                    'permissions': [],
                    'dangerous_permissions': [],
                    'suspicious_features': suspicious_files,
                    'features': feature_vector,
                    'note': 'Limited analysis - Androguard not available'
                }
        except Exception as e:
            logger.error(f"Fallback analysis failed: {str(e)}")
            return {
                'success': False,
                'error': f"Could not analyze APK: {str(e)}"
            }
    
    def _identify_dangerous_permissions(self, permissions: List[str]) -> List[str]:
        """Identify dangerous permissions"""
        dangerous = []
        for perm in permissions:
            # Extract permission name (remove android.permission prefix)
            perm_name = perm.split('.')[-1]
            if perm_name in self.DANGEROUS_PERMISSIONS:
                dangerous.append(perm_name)
        return dangerous
    
    def _identify_suspicious_features(self, apk) -> List[str]:
        """Identify suspicious features in APK"""
        suspicious = []
        
        try:
            # Check for dynamic code loading
            if 'DexClassLoader' in str(apk.get_files()):
                suspicious.append('Dynamic code loading detected')
            
            # Check for encryption/obfuscation
            if any('cipher' in str(f).lower() for f in apk.get_files()):
                suspicious.append('Encryption/cipher usage detected')
            
            # Check for native code
            if any('.so' in str(f) for f in apk.get_files()):
                suspicious.append('Native code libraries present')
            
            # Check for reflection
            if 'reflect' in str(apk.get_files()).lower():
                suspicious.append('Java reflection usage detected')
            
            # Check receivers for suspicious actions
            receivers = apk.get_receivers()
            boot_receivers = [r for r in receivers if 'boot' in r.lower()]
            if boot_receivers:
                suspicious.append('Boot receiver detected (auto-start capability)')
            
            # Check for SMS receivers
            sms_receivers = [r for r in receivers if 'sms' in r.lower()]
            if sms_receivers:
                suspicious.append('SMS receiver detected')
            
        except Exception as e:
            logger.warning(f"Error identifying suspicious features: {str(e)}")
        
        return suspicious
    
    def _extract_urls(self, apk) -> List[str]:
        """Extract URLs from APK"""
        urls = []
        url_pattern = re.compile(r'https?://[^\s<>"{}|\\^`\[\]]+')
        
        try:
            for file_name in apk.get_files():
                if file_name.endswith('.xml') or file_name.endswith('.txt'):
                    try:
                        content = apk.get_file(file_name).decode('utf-8', errors='ignore')
                        found_urls = url_pattern.findall(content)
                        urls.extend(found_urls)
                    except:
                        pass
        except Exception as e:
            logger.warning(f"Error extracting URLs: {str(e)}")
        
        return list(set(urls))  # Remove duplicates
    
    def _build_feature_vector(self, permissions, activities, services, 
                               receivers, providers, suspicious_features) -> List[float]:
        """
        Build feature vector for ML model
        Feature vector includes binary flags for various indicators
        """
        features = []
        
        # Permission-based features (40 features)
        perm_features = [
            'INTERNET', 'SEND_SMS', 'RECEIVE_SMS', 'READ_SMS',
            'READ_CONTACTS', 'WRITE_CONTACTS', 'ACCESS_FINE_LOCATION',
            'ACCESS_COARSE_LOCATION', 'RECORD_AUDIO', 'CAMERA',
            'READ_PHONE_STATE', 'CALL_PHONE', 'READ_CALL_LOG',
            'WRITE_CALL_LOG', 'INSTALL_PACKAGES', 'DELETE_PACKAGES',
            'READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE',
            'SYSTEM_ALERT_WINDOW', 'REQUEST_INSTALL_PACKAGES',
            'BIND_DEVICE_ADMIN', 'RECEIVE_BOOT_COMPLETED',
            'WAKE_LOCK', 'DISABLE_KEYGUARD', 'GET_TASKS',
            'BLUETOOTH', 'BLUETOOTH_ADMIN', 'NFC',
            'VIBRATE', 'ACCESS_WIFI_STATE', 'CHANGE_WIFI_STATE',
            'ACCESS_NETWORK_STATE', 'CHANGE_NETWORK_STATE',
            'WRITE_SETTINGS', 'EXPAND_STATUS_BAR', 'FLASHLIGHT',
            'KILL_BACKGROUND_PROCESSES', 'REBOOT', 'SET_WALLPAPER',
            'USE_CREDENTIALS'
        ]
        
        for perm in perm_features:
            has_perm = any(perm in str(p).upper() for p in permissions)
            features.append(1 if has_perm else 0)
        
        # Component count features (4 features - normalized)
        features.append(min(len(activities) / 50.0, 1.0))
        features.append(min(len(services) / 20.0, 1.0))
        features.append(min(len(receivers) / 20.0, 1.0))
        features.append(min(len(providers) / 10.0, 1.0))
        
        # Suspicious feature flags (6 features)
        susp_flags = [
            'dynamic code loading',
            'encryption',
            'native code',
            'reflection',
            'boot receiver',
            'sms receiver'
        ]
        
        for flag in susp_flags:
            has_flag = any(flag in str(s).lower() for s in suspicious_features)
            features.append(1 if has_flag else 0)
        
        return features
    
    def verify_source(self, apk) -> Dict[str, Any]:
        """
        Enhanced source and certificate verification
        Analyzes APK signing certificate to determine trustworthiness
        """
        try:
            # Import cryptography library
            from cryptography import x509
            from cryptography.hazmat.backends import default_backend
            
            # Get certificate from APK
            cert_der = apk.get_certificate_der()
            if not cert_der:
                return {
                    'source': 'Unknown',
                    'verified': False,
                    'trust_score': 0.0,
                    'error': 'No certificate found in APK'
                }
            
            # Parse certificate
            cert = x509.load_der_x509_certificate(cert_der, default_backend())
            
            # Extract basic information
            issuer = cert.issuer.rfc4514_string()
            subject = cert.subject.rfc4514_string()
            
            # Validity checks
            now = datetime.utcnow()
            is_expired = now > cert.not_valid_after
            is_not_yet_valid = now < cert.not_valid_before
            validity_days = (cert.not_valid_after - cert.not_valid_before).days
            
            # Self-signed check
            is_self_signed = issuer == subject
            
            # Calculate certificate hash
            cert_hash = hashlib.sha256(cert_der).hexdigest()
            
            # Check against known certificate patterns
            is_play_store = self._check_play_store_cert(cert_hash, issuer, subject)
            is_known_publisher = self._check_known_publisher(issuer, subject)
            
            # Determine source and trust level
            warnings = []
            
            if is_expired:
                warnings.append('Certificate expired')
            if is_not_yet_valid:
                warnings.append('Certificate not yet valid')
            if is_self_signed:
                warnings.append('Self-signed certificate (not from trusted authority)')
            if validity_days < 365:
                warnings.append(f'Short validity period ({validity_days} days)')
            if validity_days > 3650:  # > 10 years
                warnings.append('Unusually long validity period')
            
            # Determine source
            if is_play_store:
                source = 'Google Play Store'
                verified = True
                trust_score = 1.0
            elif is_known_publisher:
                source = 'Known Publisher'
                verified = True
                trust_score = 0.85
            elif not is_self_signed and validity_days >= 365 and not is_expired:
                source = 'Third-party (Valid Certificate)'
                verified = True
                trust_score = 0.7
            elif not is_self_signed:
                source = 'Third-party (Certificate Issues)'
                verified = False
                trust_score = 0.4
            else:
                source = 'Unknown / Untrusted'
                verified = False
                trust_score = 0.2
            
            # Extract organization info if available
            org_name = None
            try:
                for attr in cert.subject:
                    if attr.oid._name == 'organizationName':
                        org_name = attr.value
                        break
            except:
                pass
            
            return {
                'source': source,
                'verified': verified,
                'trust_score': trust_score,
                'certificate': {
                    'issuer': issuer,
                    'subject': subject,
                    'organization': org_name,
                    'valid_from': cert.not_valid_before.isoformat(),
                    'valid_until': cert.not_valid_after.isoformat(),
                    'is_expired': is_expired,
                    'is_not_yet_valid': is_not_yet_valid,
                    'is_self_signed': is_self_signed,
                    'validity_days': validity_days,
                    'signature_algorithm': cert.signature_algorithm_oid._name,
                    'serial_number': str(cert.serial_number),
                    'fingerprint_sha256': cert_hash
                },
                'warnings': warnings
            }
            
        except ImportError:
            logger.warning("cryptography library not installed - source verification disabled")
            return {
                'source': 'Unknown (Verification Unavailable)',
                'verified': False,
                'trust_score': 0.5,
                'error': 'Certificate verification library not installed'
            }
        except Exception as e:
            logger.error(f"Source verification failed: {str(e)}")
            return {
                'source': 'Unknown',
                'verified': False,
                'trust_score': 0.3,
                'error': str(e)
            }
    
    def _check_play_store_cert(self, cert_hash: str, issuer: str, subject: str) -> bool:
        """
        Check if certificate matches known Google Play Store patterns
        Note: Google Play certificates vary, but have certain patterns
        """
        # Google Play Store apps are typically signed by developers
        # but distributed through Play Store with additional verification
        # This is a simplified check - in production, maintain a database
        
        # Known Google certificate patterns
        google_patterns = [
            'CN=Android',
            'CN=Google Inc',
            'O=Google Inc',
            'OU=Android'
        ]
        
        # Check if any Google patterns match
        cert_string = f"{issuer} {subject}".upper()
        for pattern in google_patterns:
            if pattern.upper() in cert_string:
                return True
        
        # You can add specific certificate hashes of known Google certificates here
        # GOOGLE_PLAY_CERTS = {'hash1', 'hash2', ...}
        # return cert_hash in GOOGLE_PLAY_CERTS
        
        return False
    
    def _check_known_publisher(self, issuer: str, subject: str) -> bool:
        """
        Check if certificate is from a known reputable publisher
        """
        # List of known reputable publishers/organizations
        known_publishers = [
            'CN=Facebook',
            'CN=Twitter',
            'CN=Microsoft',
            'CN=Amazon',
            'CN=WhatsApp',
            'O=Facebook',
            'O=Microsoft Corporation',
            'O=Amazon',
            'O=Samsung',
            'O=Xiaomi',
            'O=Huawei'
        ]
        
        cert_string = f"{issuer} {subject}".upper()
        for publisher in known_publishers:
            if publisher.upper() in cert_string:
                return True
        
        return False
    
    def _build_minimal_feature_vector(self, file_list: List[str]) -> List[float]:
        """Build minimal feature vector when Androguard is not available"""
        # Create 50 features (same length as full analysis)
        features = [0.0] * 50
        
        # Set some basic features based on files
        if any('classes.dex' in f for f in file_list):
            features[0] = 1
        if any('.so' in f for f in file_list):
            features[1] = 1
        if any('assets' in f for f in file_list):
            features[2] = 1
        
        return features
