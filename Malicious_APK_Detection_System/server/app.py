"""
Malicious APK Detection System - Main Flask Application
"""
from flask import Flask, render_template, request, jsonify, send_from_directory
from werkzeug.utils import secure_filename
import os
import hashlib
import logging
from datetime import datetime
from analyzer.apk_analyzer import APKAnalyzer
from analyzer.ml_predictor import MalwarePredictor
from analyzer.virustotal_checker import VirusTotalChecker
from database.db_manager import DatabaseManager

# Initialize Flask app
app = Flask(__name__, 
            template_folder='../frontend/templates',
            static_folder='../frontend/static')

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100 MB max file size
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['ALLOWED_EXTENSIONS'] = {'apk'}
app.config['SECRET_KEY'] = 'cybersecurity-hackathon-2026'

# Create necessary directories
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
os.makedirs('logs', exist_ok=True)
os.makedirs('models', exist_ok=True)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/app.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Initialize components
apk_analyzer = APKAnalyzer()
ml_predictor = MalwarePredictor()
vt_checker = VirusTotalChecker()
db_manager = DatabaseManager()


def allowed_file(filename):
    """Check if file has allowed extension"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']


def calculate_file_hash(filepath):
    """Calculate SHA256 hash of file"""
    sha256_hash = hashlib.sha256()
    with open(filepath, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()


@app.route('/')
def index():
    """Home page"""
    return render_template('index.html')


@app.route('/upload', methods=['GET'])
def upload_page():
    """Upload page"""
    return render_template('upload.html')


@app.route('/history')
def history():
    """Scan history page"""
    scans = db_manager.get_recent_scans(limit=50)
    return render_template('history.html', scans=scans)


@app.route('/api/scan', methods=['POST'])
def scan_apk():
    """
    Main endpoint to scan uploaded APK file
    """
    try:
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Only APK files are allowed'}), 400
        
        # Save uploaded file
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"{timestamp}_{filename}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(filepath)
        
        logger.info(f"File uploaded: {unique_filename}")
        
        # Calculate file hash
        file_hash = calculate_file_hash(filepath)
        logger.info(f"File hash: {file_hash}")
        
        # Check if already scanned
        cached_result = db_manager.get_scan_by_hash(file_hash)
        if cached_result:
            logger.info("Returning cached result")
            return jsonify({
                'status': 'success',
                'cached': True,
                'result': cached_result
            })
        
        # Phase 1: Static Analysis with Androguard
        logger.info("Starting APK analysis...")
        analysis_result = apk_analyzer.analyze(filepath)
        
        if not analysis_result['success']:
            return jsonify({
                'error': 'Failed to analyze APK',
                'details': analysis_result.get('error', 'Unknown error')
            }), 500
        
        # Phase 2: ML-based Malware Detection
        logger.info("Running ML prediction...")
        ml_result = ml_predictor.predict(analysis_result['features'])
        
        # Phase 3: VirusTotal Check
        logger.info("Checking VirusTotal...")
        vt_result = vt_checker.check_hash(file_hash)
        
        # Calculate overall risk score
        risk_score = calculate_risk_score(analysis_result, ml_result, vt_result)
        
        # Determine verdict
        verdict = determine_verdict(risk_score, ml_result)
        
        # Compile final result
        scan_result = {
            'scan_id': unique_filename,
            'filename': filename,
            'file_hash': file_hash,
            'timestamp': timestamp,
            'verdict': verdict,
            'risk_score': risk_score,
            'apk_info': {
                'package_name': analysis_result.get('package_name', 'Unknown'),
                'app_name': analysis_result.get('app_name', 'Unknown'),
                'version_name': analysis_result.get('version_name', 'Unknown'),
                'version_code': analysis_result.get('version_code', 'Unknown'),
                'min_sdk': analysis_result.get('min_sdk', 'Unknown'),
                'target_sdk': analysis_result.get('target_sdk', 'Unknown'),
            },
            'permissions': analysis_result.get('permissions', []),
            'dangerous_permissions': analysis_result.get('dangerous_permissions', []),
            'suspicious_features': analysis_result.get('suspicious_features', []),
            'ml_prediction': {
                'is_malware': ml_result.get('is_malware', False),
                'confidence': ml_result.get('confidence', 0),
                'malware_type': ml_result.get('malware_type', 'Unknown')
            },
            'virustotal': vt_result,
            'recommendations': generate_recommendations(verdict, analysis_result, ml_result)
        }
        
        # Save to database
        db_manager.save_scan(scan_result)
        
        # Clean up uploaded file
        try:
            os.remove(filepath)
        except:
            pass
        
        logger.info(f"Scan completed: {verdict}")
        
        return jsonify({
            'status': 'success',
            'cached': False,
            'result': scan_result
        })
    
    except Exception as e:
        logger.error(f"Error during scan: {str(e)}", exc_info=True)
        return jsonify({
            'error': 'Internal server error',
            'details': str(e)
        }), 500


def calculate_risk_score(analysis_result, ml_result, vt_result):
    """
    Calculate overall risk score (0-100)
    """
    score = 0
    
    # ML model prediction weight (40%)
    if ml_result.get('is_malware'):
        score += ml_result.get('confidence', 0) * 40
    
    # Dangerous permissions weight (20%)
    dangerous_perms = len(analysis_result.get('dangerous_permissions', []))
    score += min(dangerous_perms * 4, 20)
    
    # Suspicious features weight (20%)
    suspicious_features = len(analysis_result.get('suspicious_features', []))
    score += min(suspicious_features * 5, 20)
    
    # VirusTotal detections weight (20%)
    if vt_result.get('detected'):
        detection_ratio = vt_result.get('positives', 0) / max(vt_result.get('total', 1), 1)
        score += detection_ratio * 20
    
    return min(int(score), 100)


def determine_verdict(risk_score, ml_result):
    """
    Determine final verdict based on risk score
    """
    if risk_score >= 70:
        return 'Malicious'
    elif risk_score >= 40:
        return 'Suspicious'
    else:
        return 'Safe'


def generate_recommendations(verdict, analysis_result, ml_result):
    """
    Generate security recommendations
    """
    recommendations = []
    
    if verdict == 'Malicious':
        recommendations.append('🚨 DO NOT INSTALL this application')
        recommendations.append('Delete this APK file immediately')
        recommendations.append('This app exhibits clear malicious behavior')
    elif verdict == 'Suspicious':
        recommendations.append('⚠️ Exercise caution with this application')
        recommendations.append('Review permissions carefully before installing')
        recommendations.append('Consider alternatives from trusted sources')
    else:
        recommendations.append('✅ No immediate threats detected')
        recommendations.append('Always download apps from official sources')
        recommendations.append('Review permissions before installation')
    
    # Permission-based recommendations
    dangerous_perms = analysis_result.get('dangerous_permissions', [])
    if 'SEND_SMS' in dangerous_perms or 'RECEIVE_SMS' in dangerous_perms:
        recommendations.append('App can send/receive SMS - potential premium SMS fraud risk')
    
    if 'READ_CONTACTS' in dangerous_perms:
        recommendations.append('App can access your contacts - privacy concern')
    
    if 'ACCESS_FINE_LOCATION' in dangerous_perms:
        recommendations.append('App tracks your precise location')
    
    if 'RECORD_AUDIO' in dangerous_perms:
        recommendations.append('App can record audio - potential eavesdropping risk')
    
    return recommendations


@app.route('/api/stats')
def get_stats():
    """Get statistics"""
    stats = db_manager.get_statistics()
    return jsonify(stats)


@app.errorhandler(413)
def request_entity_too_large(error):
    """Handle file too large error"""
    return jsonify({'error': 'File too large. Maximum size is 100 MB'}), 413


@app.errorhandler(500)
def internal_error(error):
    """Handle internal server error"""
    logger.error(f"Internal error: {str(error)}")
    return jsonify({'error': 'Internal server error'}), 500


if __name__ == '__main__':
    logger.info("Starting Malicious APK Detection System...")
    app.run(debug=True, host='0.0.0.0', port=5000)
