# 🛡️ APK Malware Detection System

**An AI-Powered Web-Based Android APK Security Analysis Platform**

Built for CyberSecurity Hackathon 2026

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Installation](#installation)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [ML Model](#ml-model)
- [Screenshots](#screenshots)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

The **APK Malware Detection System** is a comprehensive web-based security platform that analyzes Android APK files for potential malicious behavior using advanced machine learning techniques, static code analysis, and VirusTotal integration.

### Key Capabilities:
- ✅ Static APK analysis using Androguard
- 🧠 AI-powered malware detection with Random Forest
- 🔍 Permission and component analysis
- 🌐 VirusTotal API integration
- 📊 Risk scoring and threat classification
- 📝 Detailed security reports with recommendations

---

## ✨ Features

### 1. **Upload & Scan**
- Drag & drop APK file upload
- Maximum file size: 100 MB
- Real-time progress tracking
- Beautiful animations and UX

### 2. **Comprehensive Analysis**
- **Static Analysis**: Extract permissions, activities, services, receivers
- **Dangerous Permission Detection**: Identify high-risk permissions
- **Suspicious Feature Detection**: Dynamic code loading, obfuscation, native libraries
- **URL Extraction**: Find embedded URLs in APK

### 3. **AI-Powered Detection**
- Random Forest classifier trained on malware patterns
- 50-feature vector representation
- Malware type classification:
  - SMS Trojan
  - Banking Trojan
  - Spyware
  - Ransomware
  - Adware
  - Backdoor/RAT

### 4. **VirusTotal Integration**
- Cross-reference with 70+ antivirus engines
- Check file hash against VT database
- Display detection ratios

### 5. **Risk Scoring**
- 0-100 risk score based on multiple factors
- Verdict: Safe / Suspicious / Malicious
- Weighted scoring:
  - ML prediction: 40%
  - Dangerous permissions: 20%
  - Suspicious features: 20%
  - VirusTotal detections: 20%

### 6. **Scan History**
- SQLite database for scan results
- View past scans with filtering
- Cached results for previously scanned files

---

## 🏗️ Architecture

```
User Browser
     ↓
Web UI (HTML/CSS/JS)
     ↓
Flask Backend (REST API)
     ↓
┌────────────────────────────────┐
│  APK Analysis Pipeline         │
├────────────────────────────────┤
│ 1. APK Analyzer (Androguard)   │
│ 2. ML Predictor (Random Forest)│
│ 3. VirusTotal Checker          │
│ 4. Risk Scoring Engine         │
└────────────────────────────────┘
     ↓
SQLite Database
     ↓
JSON Response → User
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | HTML5, CSS3, JavaScript (Vanilla) |
| **Backend** | Python 3.8+, Flask 3.0 |
| **APK Analysis** | Androguard 4.1 |
| **Machine Learning** | Scikit-learn, Random Forest, NumPy, Pandas |
| **Database** | SQLite3 |
| **API Integration** | VirusTotal API v2 |
| **Deployment** | Local / Ngrok (for demos) |

---

## 📦 Installation

### Prerequisites
- Python 3.8 or higher
- pip (Python package manager)
- Git

### Step 1: Clone Repository
```bash
git clone <your-repo-url>
cd CyberSecurity_Hackathon
```

### Step 2: Run Setup Script
```bash
python setup.py
```

This will:
- Create necessary directories
- Install all dependencies
- Train the initial ML model
- Create configuration file

### Step 3: Configure Environment (Optional)
Edit `.env` file and add your VirusTotal API key:
```bash
VIRUSTOTAL_API_KEY=your-api-key-here
```

Get your free API key from: https://www.virustotal.com/gui/my-apikey

### Manual Installation (Alternative)
```bash
# Create directories
mkdir -p server/{uploads,logs,models,database}

# Install dependencies
pip install -r requirements.txt

# Train model
python server/train_model.py

# Copy environment file
cp .env.example .env
```

---

## 🚀 Usage

### Start the Application
```bash
python run.py
```

Or directly:
```bash
python server/app.py
```

The server will start at: **http://localhost:5000**

### Access the Web Interface
1. Open browser: `http://localhost:5000`
2. Click "Scan APK Now"
3. Upload an APK file (drag & drop or browse)
4. Click "Start Scanning"
5. View detailed results

### For Public Demo (Optional)
Use ngrok to expose your local server:
```bash
ngrok http 5000
```

---

## 📡 API Documentation

### POST `/api/scan`

**Upload and scan APK file**

**Request:**
- Method: `POST`
- Content-Type: `multipart/form-data`
- Body: `file` (APK file)

**Response:**
```json
{
  "status": "success",
  "cached": false,
  "result": {
    "scan_id": "20260112_143025_app.apk",
    "filename": "app.apk",
    "file_hash": "a1b2c3d4...",
    "verdict": "Suspicious",
    "risk_score": 65,
    "apk_info": {
      "package_name": "com.example.app",
      "app_name": "Example App",
      "version_name": "1.0.0",
      "target_sdk": "30"
    },
    "permissions": [...],
    "dangerous_permissions": [...],
    "suspicious_features": [...],
    "ml_prediction": {
      "is_malware": true,
      "confidence": 0.85,
      "malware_type": "Spyware"
    },
    "virustotal": {...},
    "recommendations": [...]
  }
}
```

### GET `/api/stats`

**Get scanning statistics**

**Response:**
```json
{
  "total_scans": 150,
  "malicious": 45,
  "suspicious": 30,
  "safe": 75,
  "average_risk_score": 42.5
}
```

---

## 🧠 ML Model

### Feature Vector (50 features)

**Permission Features (40)**
- INTERNET, SEND_SMS, RECEIVE_SMS, READ_SMS
- READ_CONTACTS, WRITE_CONTACTS
- ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION
- RECORD_AUDIO, CAMERA
- READ_PHONE_STATE, CALL_PHONE
- And 28 more...

**Component Features (4)**
- Activity count (normalized)
- Service count (normalized)
- Receiver count (normalized)
- Provider count (normalized)

**Suspicious Features (6)**
- Dynamic code loading
- Encryption usage
- Native code
- Reflection usage
- Boot receiver
- SMS receiver

### Training

Train your own model:
```bash
python server/train_model.py
```

**Model Details:**
- Algorithm: Random Forest Classifier
- Estimators: 100 trees
- Max Depth: 20
- Training samples: 5000 (synthetic demo data)
- Accuracy: ~95% (on demo data)

**For Production:**
Replace synthetic data with real datasets:
- [Drebin Dataset](https://www.sec.cs.tu-bs.de/~danarp/drebin/)
- [CICAndMal2017](https://www.unb.ca/cic/datasets/andmal2017.html)
- [AndroZoo](https://androzoo.uni.lu/)

---

## 📸 Screenshots

### Home Page
![Home Page](docs/screenshots/home.png)

### Upload & Scan
![Upload Page](docs/screenshots/upload.png)

### Scan Results
![Results Page](docs/screenshots/results.png)

### Scan History
![History Page](docs/screenshots/history.png)

---

## 📁 Project Structure

```
CyberSecurity_Hackathon/
├── server/
│   ├── app.py                    # Main Flask application
│   ├── train_model.py            # ML model training script
│   ├── analyzer/
│   │   ├── __init__.py
│   │   ├── apk_analyzer.py       # Androguard static analysis
│   │   ├── ml_predictor.py       # ML-based prediction
│   │   └── virustotal_checker.py # VirusTotal integration
│   ├── database/
│   │   ├── __init__.py
│   │   ├── db_manager.py         # SQLite database manager
│   │   └── scans.db             # SQLite database (auto-created)
│   ├── models/
│   │   └── malware_model.pkl    # Trained ML model
│   ├── uploads/                 # Temporary APK uploads
│   └── logs/                    # Application logs
├── frontend/
│   ├── templates/
│   │   ├── index.html           # Home page
│   │   ├── upload.html          # Upload page
│   │   └── history.html         # History page
│   └── static/
│       ├── css/
│       │   └── style.css        # All styles
│       └── js/
│           ├── main.js          # Home page JS
│           └── upload.js        # Upload page JS
├── requirements.txt              # Python dependencies
├── setup.py                      # Setup script
├── run.py                        # Quick start script
├── .env.example                  # Environment config template
├── .gitignore                   # Git ignore rules
└── README.md                     # This file
```

---

## 🎓 How It Works

### Scanning Pipeline

1. **Upload**: User uploads APK file via web interface
2. **Hash Calculation**: SHA256 hash computed for file
3. **Cache Check**: Check if file was scanned before
4. **Static Analysis**: 
   - Extract APK with Androguard
   - Parse manifest, permissions, components
   - Identify dangerous patterns
5. **Feature Extraction**: Build 50-feature vector
6. **ML Prediction**: Run through Random Forest model
7. **VirusTotal Check**: Query VT API for hash
8. **Risk Scoring**: Calculate overall risk (0-100)
9. **Verdict**: Classify as Safe/Suspicious/Malicious
10. **Report Generation**: Compile results with recommendations
11. **Database Storage**: Save results for history
12. **Response**: Return JSON to frontend

---

## 🔒 Security Considerations

- ✅ Files are deleted after analysis
- ✅ Uploaded files stored temporarily only
- ✅ No code execution on server
- ✅ Input validation and file type checking
- ✅ SQL injection prevention (parameterized queries)
- ✅ XSS protection in templates
- ⚠️ For production: Add authentication, rate limiting, HTTPS

---

## 🚀 Deployment Options

### Local Development
```bash
python run.py
```

### Production with Gunicorn
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 server.app:app
```

### Docker (Create Dockerfile)
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "run.py"]
```

### Cloud Deployment
- Heroku
- AWS EC2
- Google Cloud Platform
- Azure App Service

---

## 🎯 Hackathon Presentation Tips

### Demo Flow
1. Show homepage with features
2. Upload a clean APK → Safe result
3. Upload a malicious sample → Malicious detection
4. Show detailed analysis report
5. Demonstrate scan history
6. Explain ML model and architecture

### Key Talking Points
- ✨ **AI-Powered**: Machine learning for detection
- 🔒 **Comprehensive**: Multiple analysis layers
- 🎨 **User-Friendly**: Beautiful, intuitive interface
- 📊 **Detailed Reports**: Actionable security insights
- 🌐 **VirusTotal**: Cross-validation with 70+ engines
- ⚡ **Fast**: Results in under 30 seconds

---

## 🐛 Troubleshooting

### Androguard Import Error
```bash
pip install --upgrade androguard
```

### Permission Denied on Windows
Run Command Prompt as Administrator

### Port Already in Use
Change port in `run.py`:
```python
app.run(debug=True, host='0.0.0.0', port=8080)
```

### Model Not Found
```bash
python server/train_model.py
```

---

## 📚 Resources

- [Androguard Documentation](https://androguard.readthedocs.io/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Scikit-learn Documentation](https://scikit-learn.org/)
- [VirusTotal API](https://developers.virustotal.com/reference)
- [Android Security](https://source.android.com/security)

---

## 👥 Team

**CyberSecurity Hackathon 2026**
- Your Name
- Team Members

---

## 📝 License

MIT License - Feel free to use this for educational purposes

---

## 🙏 Acknowledgments

- Androguard team for APK analysis tools
- Scikit-learn for ML framework
- VirusTotal for API access
- CyberSecurity Hackathon organizers

---

## 📞 Support

For issues or questions:
- Create an issue on GitHub
- Email: your-email@example.com

---

**Built with ❤️ for CyberSecurity Hackathon 2026**

*Protecting users from mobile threats, one APK at a time* 🛡️
