"""
ML Model Training Script
Train Random Forest model for malware detection
"""
import numpy as np
import pandas as pd
import pickle
import logging
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import os

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def generate_synthetic_data(n_samples=5000):
    """
    Generate synthetic training data for demonstration
    In production, use real datasets like Drebin or CICAndMal2017
    """
    logger.info(f"Generating {n_samples} synthetic samples...")
    
    np.random.seed(42)
    
    # Generate features (50 features as per our feature vector)
    features = []
    labels = []
    
    for i in range(n_samples):
        # Decide if malicious (40% malicious, 60% benign)
        is_malicious = np.random.random() < 0.4
        
        feature_vector = []
        
        # Permission features (40 features)
        for j in range(40):
            if is_malicious:
                # Malicious apps tend to have more dangerous permissions
                if j < 20:  # More dangerous permissions
                    prob = 0.6
                else:
                    prob = 0.3
            else:
                # Benign apps have fewer dangerous permissions
                if j < 20:
                    prob = 0.2
                else:
                    prob = 0.1
            
            feature_vector.append(1 if np.random.random() < prob else 0)
        
        # Component counts (4 features - normalized 0-1)
        if is_malicious:
            feature_vector.extend([
                np.random.uniform(0.3, 1.0),  # More activities
                np.random.uniform(0.4, 1.0),  # More services
                np.random.uniform(0.5, 1.0),  # More receivers
                np.random.uniform(0.2, 0.8)   # Providers
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
            if is_malicious:
                prob = 0.7
            else:
                prob = 0.1
            feature_vector.append(1 if np.random.random() < prob else 0)
        
        features.append(feature_vector)
        labels.append(1 if is_malicious else 0)
    
    return np.array(features), np.array(labels)


def train_model(X, y, model_path='models/malware_model.pkl'):
    """Train Random Forest classifier"""
    logger.info("Training Random Forest model...")
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    logger.info(f"Training set: {len(X_train)} samples")
    logger.info(f"Test set: {len(X_test)} samples")
    logger.info(f"Malicious samples: {sum(y_train)} ({sum(y_train)/len(y_train)*100:.1f}%)")
    
    # Train Random Forest
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=20,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train)
    logger.info("Model training completed")
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    logger.info(f"\n{'='*50}")
    logger.info("MODEL EVALUATION")
    logger.info(f"{'='*50}")
    logger.info(f"Accuracy: {accuracy*100:.2f}%")
    logger.info(f"\nClassification Report:")
    logger.info(f"\n{classification_report(y_test, y_pred, target_names=['Benign', 'Malicious'])}")
    logger.info(f"\nConfusion Matrix:")
    logger.info(f"\n{confusion_matrix(y_test, y_pred)}")
    
    # Cross-validation
    cv_scores = cross_val_score(model, X_train, y_train, cv=5)
    logger.info(f"\nCross-validation scores: {cv_scores}")
    logger.info(f"Average CV score: {cv_scores.mean()*100:.2f}% (+/- {cv_scores.std()*2*100:.2f}%)")
    
    # Feature importance
    feature_importance = model.feature_importances_
    top_10_idx = np.argsort(feature_importance)[-10:]
    logger.info(f"\nTop 10 Important Features:")
    for idx in reversed(top_10_idx):
        logger.info(f"Feature {idx}: {feature_importance[idx]:.4f}")
    
    # Save model
    os.makedirs(os.path.dirname(model_path), exist_ok=True)
    with open(model_path, 'wb') as f:
        pickle.dump(model, f)
    logger.info(f"\nModel saved to {model_path}")
    
    return model


def main():
    """Main training function"""
    logger.info("="*50)
    logger.info("MALWARE DETECTION MODEL TRAINING")
    logger.info("="*50)
    
    # Generate or load data
    # In production, load real dataset:
    # X, y = load_drebin_dataset()
    X, y = generate_synthetic_data(n_samples=5000)
    
    # Train model
    model = train_model(X, y)
    
    logger.info("\nTraining completed successfully!")
    logger.info("You can now use this model for malware detection.")


if __name__ == '__main__':
    main()
