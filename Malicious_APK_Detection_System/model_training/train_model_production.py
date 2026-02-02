"""
Production ML Model Training Script with Real Dataset Support
Supports: Drebin, CICAndMal2017, AndroZoo, and custom datasets
"""
import numpy as np
import pandas as pd
import pickle
import logging
import os
import sys
from pathlib import Path
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.metrics import (classification_report, confusion_matrix, 
                            accuracy_score, precision_score, recall_score, 
                            f1_score, roc_auc_score, roc_curve)
from sklearn.preprocessing import StandardScaler
import joblib

# Create logs directory if it doesn't exist
os.makedirs('logs', exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/model_training.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DatasetLoader:
    """Load various malware datasets"""
    
    @staticmethod
    def load_drebin(csv_path):
        """
        Load Drebin dataset from CSV
        Expected format: features + 'malware' label column
        """
        logger.info(f"Loading Drebin dataset from {csv_path}")
        try:
            df = pd.read_csv(csv_path)
            
            # Separate features and labels
            if 'malware' in df.columns:
                y = df['malware'].values
                X = df.drop('malware', axis=1).values
            elif 'class' in df.columns:
                y = df['class'].values
                X = df.drop('class', axis=1).values
            else:
                logger.error("No label column found. Expected 'malware' or 'class'")
                return None, None
            
            logger.info(f"Loaded {len(X)} samples with {X.shape[1]} features")
            logger.info(f"Malware samples: {sum(y)} ({sum(y)/len(y)*100:.1f}%)")
            return X, y
            
        except Exception as e:
            logger.error(f"Failed to load Drebin dataset: {e}")
            return None, None
    
    @staticmethod
    def load_cicandmal2017(data_dir):
        """
        Load CICAndMal2017 dataset
        Expected structure: data_dir/benign/*.csv and data_dir/malware/*.csv
        """
        logger.info(f"Loading CICAndMal2017 dataset from {data_dir}")
        try:
            benign_files = list(Path(data_dir).glob('benign/*.csv'))
            malware_files = list(Path(data_dir).glob('malware/*.csv'))
            
            benign_data = []
            malware_data = []
            
            for file in benign_files:
                df = pd.read_csv(file)
                benign_data.append(df)
            
            for file in malware_files:
                df = pd.read_csv(file)
                malware_data.append(df)
            
            benign_df = pd.concat(benign_data, ignore_index=True)
            malware_df = pd.concat(malware_data, ignore_index=True)
            
            # Create labels
            benign_df['malware'] = 0
            malware_df['malware'] = 1
            
            # Combine
            full_df = pd.concat([benign_df, malware_df], ignore_index=True)
            
            y = full_df['malware'].values
            X = full_df.drop('malware', axis=1).values
            
            logger.info(f"Loaded {len(X)} samples with {X.shape[1]} features")
            logger.info(f"Malware samples: {sum(y)} ({sum(y)/len(y)*100:.1f}%)")
            return X, y
            
        except Exception as e:
            logger.error(f"Failed to load CICAndMal2017 dataset: {e}")
            return None, None
    
    @staticmethod
    def load_custom_csv(csv_path, label_column='label'):
        """
        Load custom CSV dataset
        Args:
            csv_path: Path to CSV file
            label_column: Name of label column (0=benign, 1=malware)
        """
        logger.info(f"Loading custom dataset from {csv_path}")
        try:
            df = pd.read_csv(csv_path)
            
            if label_column not in df.columns:
                logger.error(f"Label column '{label_column}' not found")
                return None, None
            
            y = df[label_column].values
            X = df.drop(label_column, axis=1).values
            
            logger.info(f"Loaded {len(X)} samples with {X.shape[1]} features")
            logger.info(f"Malware samples: {sum(y)} ({sum(y)/len(y)*100:.1f}%)")
            return X, y
            
        except Exception as e:
            logger.error(f"Failed to load custom dataset: {e}")
            return None, None
    
    @staticmethod
    def generate_synthetic_data(n_samples=5000):
        """Generate synthetic data (fallback for testing)"""
        logger.info(f"Generating {n_samples} synthetic samples...")
        
        np.random.seed(42)
        features = []
        labels = []
        
        for i in range(n_samples):
            is_malicious = np.random.random() < 0.4
            feature_vector = []
            
            # Permission features (40 features)
            for j in range(40):
                if is_malicious:
                    prob = 0.6 if j < 20 else 0.3
                else:
                    prob = 0.2 if j < 20 else 0.1
                feature_vector.append(1 if np.random.random() < prob else 0)
            
            # Component counts (4 features)
            if is_malicious:
                feature_vector.extend([
                    np.random.uniform(0.3, 1.0),
                    np.random.uniform(0.4, 1.0),
                    np.random.uniform(0.5, 1.0),
                    np.random.uniform(0.2, 0.8)
                ])
            else:
                feature_vector.extend([
                    np.random.uniform(0.1, 0.5),
                    np.random.uniform(0.1, 0.4),
                    np.random.uniform(0.1, 0.3),
                    np.random.uniform(0.0, 0.3)
                ])
            
            # Suspicious features (6 features)
            for j in range(6):
                prob = 0.7 if is_malicious else 0.1
                feature_vector.append(1 if np.random.random() < prob else 0)
            
            features.append(feature_vector)
            labels.append(1 if is_malicious else 0)
        
        return np.array(features), np.array(labels)


class ProductionModelTrainer:
    """Train production-grade malware detection model"""
    
    def __init__(self, model_type='random_forest'):
        self.model_type = model_type
        self.model = None
        self.scaler = None
        
    def preprocess_data(self, X, y):
        """Preprocess and validate data"""
        logger.info("Preprocessing data...")
        
        # Handle missing values
        X = np.nan_to_num(X, nan=0.0, posinf=0.0, neginf=0.0)
        
        # Feature scaling for tree-based models (optional but can help)
        self.scaler = StandardScaler()
        X_scaled = self.scaler.fit_transform(X)
        
        logger.info("✓ Preprocessing completed")
        return X_scaled, y
    
    def train_model(self, X, y, hyperparameter_tuning=False):
        """Train the model with optional hyperparameter tuning"""
        logger.info(f"Training {self.model_type} model...")
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        logger.info(f"Training set: {len(X_train)} samples")
        logger.info(f"Test set: {len(X_test)} samples")
        logger.info(f"Malicious: {sum(y_train)} ({sum(y_train)/len(y_train)*100:.1f}%)")
        
        if hyperparameter_tuning:
            self.model = self._train_with_tuning(X_train, y_train)
        else:
            self.model = self._train_default(X_train, y_train)
        
        # Evaluate
        self._evaluate_model(X_test, y_test)
        
        # Cross-validation
        self._cross_validate(X_train, y_train)
        
        return self.model
    
    def _train_default(self, X_train, y_train):
        """Train with default hyperparameters"""
        if self.model_type == 'random_forest':
            model = RandomForestClassifier(
                n_estimators=200,
                max_depth=30,
                min_samples_split=5,
                min_samples_leaf=2,
                max_features='sqrt',
                random_state=42,
                n_jobs=-1,
                class_weight='balanced'
            )
        elif self.model_type == 'gradient_boosting':
            model = GradientBoostingClassifier(
                n_estimators=200,
                max_depth=10,
                learning_rate=0.1,
                random_state=42
            )
        else:
            raise ValueError(f"Unknown model type: {self.model_type}")
        
        model.fit(X_train, y_train)
        logger.info("✓ Model training completed")
        return model
    
    def _train_with_tuning(self, X_train, y_train):
        """Train with hyperparameter tuning (takes longer)"""
        logger.info("Starting hyperparameter tuning (this may take a while)...")
        
        if self.model_type == 'random_forest':
            param_grid = {
                'n_estimators': [100, 200, 300],
                'max_depth': [20, 30, 40],
                'min_samples_split': [2, 5, 10],
                'min_samples_leaf': [1, 2, 4]
            }
            base_model = RandomForestClassifier(random_state=42, n_jobs=-1)
        else:
            param_grid = {
                'n_estimators': [100, 200],
                'max_depth': [5, 10, 15],
                'learning_rate': [0.01, 0.1, 0.2]
            }
            base_model = GradientBoostingClassifier(random_state=42)
        
        grid_search = GridSearchCV(
            base_model, param_grid, cv=3, scoring='f1', n_jobs=-1, verbose=2
        )
        grid_search.fit(X_train, y_train)
        
        logger.info(f"Best parameters: {grid_search.best_params_}")
        logger.info(f"Best CV score: {grid_search.best_score_:.4f}")
        
        return grid_search.best_estimator_
    
    def _evaluate_model(self, X_test, y_test):
        """Comprehensive model evaluation"""
        y_pred = self.model.predict(X_test)
        y_proba = self.model.predict_proba(X_test)[:, 1]
        
        logger.info("\n" + "="*70)
        logger.info("MODEL EVALUATION RESULTS")
        logger.info("="*70)
        
        # Basic metrics
        accuracy = accuracy_score(y_test, y_pred)
        precision = precision_score(y_test, y_pred)
        recall = recall_score(y_test, y_pred)
        f1 = f1_score(y_test, y_pred)
        auc = roc_auc_score(y_test, y_proba)
        
        logger.info(f"\nAccuracy:  {accuracy*100:.2f}%")
        logger.info(f"Precision: {precision*100:.2f}%")
        logger.info(f"Recall:    {recall*100:.2f}%")
        logger.info(f"F1-Score:  {f1*100:.2f}%")
        logger.info(f"AUC-ROC:   {auc*100:.2f}%")
        
        # Classification report
        logger.info(f"\nClassification Report:")
        logger.info("\n" + classification_report(y_test, y_pred, 
                                                 target_names=['Benign', 'Malicious']))
        
        # Confusion matrix
        cm = confusion_matrix(y_test, y_pred)
        logger.info(f"\nConfusion Matrix:")
        logger.info(f"                Predicted")
        logger.info(f"              Benign  Malicious")
        logger.info(f"Actual Benign   {cm[0][0]:5d}    {cm[0][1]:5d}")
        logger.info(f"     Malicious  {cm[1][0]:5d}    {cm[1][1]:5d}")
        
        # Feature importance (for tree-based models)
        if hasattr(self.model, 'feature_importances_'):
            self._log_feature_importance()
    
    def _cross_validate(self, X_train, y_train):
        """Perform cross-validation"""
        logger.info("\nPerforming 5-fold cross-validation...")
        cv_scores = cross_val_score(self.model, X_train, y_train, cv=5, 
                                    scoring='f1', n_jobs=-1)
        logger.info(f"CV F1-Scores: {cv_scores}")
        logger.info(f"Average: {cv_scores.mean()*100:.2f}% (+/- {cv_scores.std()*2*100:.2f}%)")
    
    def _log_feature_importance(self):
        """Log top important features"""
        feature_importance = self.model.feature_importances_
        top_20_idx = np.argsort(feature_importance)[-20:]
        
        logger.info(f"\nTop 20 Important Features:")
        for idx in reversed(top_20_idx):
            logger.info(f"  Feature {idx:3d}: {feature_importance[idx]:.4f}")
    
    def save_model(self, model_path='models/malware_model.pkl'):
        """Save trained model and scaler"""
        os.makedirs(os.path.dirname(model_path), exist_ok=True)
        
        # Save model
        with open(model_path, 'wb') as f:
            pickle.dump(self.model, f)
        logger.info(f"✓ Model saved to {model_path}")
        
        # Save scaler
        scaler_path = model_path.replace('.pkl', '_scaler.pkl')
        with open(scaler_path, 'wb') as f:
            pickle.dump(self.scaler, f)
        logger.info(f"✓ Scaler saved to {scaler_path}")
        
        # Save metadata
        metadata = {
            'model_type': self.model_type,
            'n_features': self.model.n_features_in_ if hasattr(self.model, 'n_features_in_') else None,
            'training_date': pd.Timestamp.now().isoformat()
        }
        metadata_path = model_path.replace('.pkl', '_metadata.pkl')
        with open(metadata_path, 'wb') as f:
            pickle.dump(metadata, f)
        logger.info(f"✓ Metadata saved to {metadata_path}")


def main():
    """Main training pipeline"""
    logger.info("="*70)
    logger.info("PRODUCTION MALWARE DETECTION MODEL TRAINING")
    logger.info("="*70)
    
    # Configuration
    DATASET_TYPE = 'drebin'  # Options: 'drebin', 'cicandmal2017', 'custom', 'synthetic'
    DATASET_PATH = r'datasets\drebin.csv'  # Update with your dataset path
    MODEL_TYPE = 'random_forest'  # Options: 'random_forest', 'gradient_boosting'
    HYPERPARAMETER_TUNING = False  # Set True for production (takes longer)
    
    logger.info(f"\nConfiguration:")
    logger.info(f"  Dataset Type: {DATASET_TYPE}")
    logger.info(f"  Model Type: {MODEL_TYPE}")
    logger.info(f"  Hyperparameter Tuning: {HYPERPARAMETER_TUNING}")
    
    # Load dataset
    loader = DatasetLoader()
    
    if DATASET_TYPE == 'drebin':
        X, y = loader.load_drebin(DATASET_PATH)
    elif DATASET_TYPE == 'cicandmal2017':
        X, y = loader.load_cicandmal2017(DATASET_PATH)
    elif DATASET_TYPE == 'custom':
        X, y = loader.load_custom_csv(DATASET_PATH)
    else:  # synthetic
        X, y = loader.generate_synthetic_data(n_samples=10000)
    
    if X is None or y is None:
        logger.error("Failed to load dataset. Exiting.")
        sys.exit(1)
    
    # Train model
    trainer = ProductionModelTrainer(model_type=MODEL_TYPE)
    X_processed, y_processed = trainer.preprocess_data(X, y)
    model = trainer.train_model(X_processed, y_processed, 
                               hyperparameter_tuning=HYPERPARAMETER_TUNING)
    
    # Save model
    trainer.save_model('models/malwares_model.pkl')
    
    logger.info("\n" + "="*70)
    logger.info("✓ TRAINING COMPLETED SUCCESSFULLY!")
    logger.info("="*70)
    logger.info("\nModel is ready for production use.")
    logger.info("Deploy with: python run.py")


if __name__ == '__main__':
    main()
