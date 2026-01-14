# 🚀 Malicious APK Detection System - Complete Setup Guide

## 📋 Prerequisites

### Required Software:
1. **Python 3.8+** (Recommended: Python 3.11)
2. **pip** (Python package installer)
3. **Virtual Environment** (Already created as `cyber/`)
4. **Git** (for version control)
5. **Android SDK Tools** (Optional - only for advanced APK analysis)

---

## 🔧 Step-by-Step Setup

### 1. Activate Virtual Environment

**Windows (PowerShell):**
```powershell
cd d:\Projects\Malicious_APK_Detection_System
.\cyber\Scripts\Activate.ps1
```

**Windows (Command Prompt):**
```cmd
cd d:\Projects\Malicious_APK_Detection_System
cyber\Scripts\activate.bat
```

**Linux/Mac:**
```bash
cd /path/to/Malicious_APK_Detection_System
source cyber/bin/activate
```

✅ You should see `(cyber)` prefix in your terminal

---

### 2. Install Dependencies

```powershell
pip install -r requirements.txt
```

**Key packages installed:**
- ✅ Flask (Web framework)
- ✅ Androguard (APK analysis)
- ✅ Scikit-learn (Machine learning)
- ✅ NumPy, Pandas (Data processing)
- ✅ Requests (API calls)

---

### 3. Setup Configuration (Optional)

Create `.env` file from template:
```powershell
Copy-Item .env.example .env
```

Edit `.env` and configure:
```env
# VirusTotal API Key (Optional but recommended)
VIRUSTOTAL_API_KEY=your-api-key-here
```

**Get VirusTotal API Key:**
1. Go to https://www.virustotal.com/
2. Sign up for free account
3. Navigate to: Profile → API Key
4. Copy your API key and paste in `.env`

⚠️ **Note:** Without VirusTotal API key, the system will still work but won't have online threat intelligence.

---

### 4. Verify Model Files

Check that your trained models exist:
```powershell
Get-ChildItem model_training\models\
```

**Required files:**
- ✅ `malwares_model.pkl` (13.9 MB) - Main ML model
- ✅ `malwares_model_scaler.pkl` (5.6 KB) - Feature scaler
- ✅ `malwares_model_metadata.pkl` (105 bytes) - Model metadata

**If models are missing:**
Run the training script:
```powershell
cd model_training
python train_model_production.py
```

---

### 5. Initialize Database

Database will be created automatically on first run, but you can verify:
```powershell
# Database will be created at: server/database/scans.db
# No manual setup needed!
```

---

## ▶️ Running the Application

### Start the Server

**Development Mode:**
```powershell
python run.py
```

Or directly:
```powershell
cd server
python app.py
```

**Expected output:**
```
2026-01-14 16:00:00 - INFO - ✓ ML model loaded from ../model_training/models/malwares_model.pkl
2026-01-14 16:00:00 - INFO - ✓ Scaler loaded from ../model_training/models/malwares_model_scaler.pkl
2026-01-14 16:00:00 - INFO - ✓ Metadata loaded: {...}
2026-01-14 16:00:00 - INFO - ML prediction system ready
2026-01-14 16:00:00 - INFO - VirusTotal API key not configured - checks disabled
2026-01-14 16:00:00 - INFO - Database initialized at database/scans.db
2026-01-14 16:00:00 - INFO - Starting Malicious APK Detection System...
 * Running on http://0.0.0.0:5000
```

✅ **Server is ready!** Access at: http://localhost:5000

---

## 🎯 Using the Application

### Web Interface

#### 1. **Home Page** - http://localhost:5000
- Welcome page with system overview
- Quick start instructions

#### 2. **Upload APK** - http://localhost:5000/upload
- Click "Choose File" → Select .apk file
- Click "Upload & Scan"
- Wait for analysis (typically 5-30 seconds)

#### 3. **View Results**
The system will show:
- ✅ **Verdict**: Safe / Suspicious / Malicious
- 📊 **Risk Score**: 0-100
- 📱 **APK Info**: Package name, version, SDK versions
- 🔐 **Permissions**: All permissions with dangerous ones highlighted
- 🤖 **ML Prediction**: Model confidence and malware type
- 🌐 **VirusTotal**: Detection ratio (if API key configured)
- 💡 **Recommendations**: Security advice

#### 4. **Scan History** - http://localhost:5000/history
- View all previously scanned APKs
- Quick reference to past results
- Filter by verdict

---

### API Endpoints

#### POST `/api/scan` - Scan APK File

**Request:**
```bash
curl -X POST http://localhost:5000/api/scan \
  -F "file=@/path/to/app.apk"
```

**Response:**
```json
{
  "status": "success",
  "cached": false,
  "result": {
    "scan_id": "20260114_160000_app.apk",
    "filename": "app.apk",
    "file_hash": "abc123...",
    "verdict": "Safe",
    "risk_score": 25,
    "apk_info": {...},
    "permissions": [...],
    "ml_prediction": {
      "is_malware": false,
      "confidence": 0.92,
      "malware_type": "Benign"
    },
    "virustotal": {...},
    "recommendations": [...]
  }
}
```

#### GET `/api/stats` - Get Statistics

**Request:**
```bash
curl http://localhost:5000/api/stats
```

**Response:**
```json
{
  "total_scans": 45,
  "malicious": 12,
  "suspicious": 8,
  "safe": 25,
  "average_risk_score": 34.5
}
```

---

## 📥 Input Requirements

### What You Need to Provide:

#### 1. **APK File** (Required)
- **Format**: `.apk` file only
- **Size**: Maximum 100 MB
- **Source**: Can be from:
  - Google Play Store (download via tools like APK Extractor)
  - Third-party app stores
  - Direct APK files
  - Your own developed apps

**How to Get APK Files:**

**From Installed Android App:**
1. Install "APK Extractor" on Android device
2. Select app → Extract APK
3. Transfer APK to computer

**From Google Play:**
1. Use APK download tools:
   - APKPure.com
   - APKMirror.com
   - Evozi APK Downloader

**From Development:**
1. Build your Android project
2. Find APK in: `app/build/outputs/apk/`

#### 2. **VirusTotal API Key** (Optional)
- Free tier: 4 requests/minute
- Sign up at: https://www.virustotal.com/
- Provides online threat intelligence
- Adds detection from 70+ antivirus engines

---

## 🧪 Testing the System

### Test with Sample APKs

**Safe Apps (for testing):**
- Download any legitimate app from F-Droid: https://f-droid.org/
- Google's sample apps: https://github.com/android/

**Malware Samples (for research only - USE CAUTION):**
- AndroZoo: https://androzoo.uni.lu/ (requires academic access)
- Drebin dataset: Request from authors
- Use only in isolated/VM environments!

### Quick Test Command:
```powershell
# Upload a test APK
curl -X POST http://localhost:5000/api/scan -F "file=@test_app.apk"
```

---

## 📊 Understanding the Results

### Risk Score Breakdown (0-100):

- **0-39**: ✅ **Safe** - Low risk, no significant threats
- **40-69**: ⚠️ **Suspicious** - Moderate risk, exercise caution
- **70-100**: 🚨 **Malicious** - High risk, do not install

### Score Components:
1. **ML Model (40%)**: Machine learning prediction confidence
2. **Dangerous Permissions (20%)**: Count of risky permissions
3. **Suspicious Features (20%)**: Code patterns like reflection, dynamic loading
4. **VirusTotal (20%)**: Detection ratio from antivirus engines

---

## 🔍 System Architecture

```
User uploads APK
       ↓
[1] Static Analysis (Androguard)
    - Extract APK info
    - Parse permissions
    - Analyze components
    - Detect suspicious patterns
       ↓
[2] Feature Extraction
    - 50 features: permissions, components, patterns
       ↓
[3] ML Prediction (Random Forest)
    - Scale features (StandardScaler)
    - Predict: Malware/Benign
    - Calculate confidence
       ↓
[4] VirusTotal Check (Optional)
    - Query hash against VT database
    - Get detection ratio
       ↓
[5] Risk Calculation
    - Combine all signals
    - Generate risk score (0-100)
       ↓
[6] Database Storage
    - Save results (SQLite)
    - Enable caching
       ↓
[7] Return Results
    - JSON response
    - Web interface display
```

---

## 🐛 Troubleshooting

### Issue: "Module not found" error
**Solution:**
```powershell
pip install -r requirements.txt --force-reinstall
```

### Issue: "ML model not found"
**Solution:**
```powershell
cd model_training
python train_model_production.py
```

### Issue: Port 5000 already in use
**Solution:**
```powershell
# Find process using port 5000
Get-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess

# Kill the process or change port in server/app.py:
app.run(debug=True, host='0.0.0.0', port=8080)
```

### Issue: Androguard analysis fails
**Solution:**
- Ensure APK file is not corrupted
- Try with a different APK
- Check file permissions

### Issue: VirusTotal always shows "not available"
**Solution:**
- Add API key to `.env` file
- Verify API key is correct
- Check rate limits (4 req/min for free tier)

---

## 📁 Project Structure

```
Malicious_APK_Detection_System/
├── server/                    # Main application
│   ├── app.py                # Flask web server
│   ├── analyzer/             # Analysis modules
│   │   ├── apk_analyzer.py   # APK static analysis
│   │   ├── ml_predictor.py   # ML-based detection
│   │   └── virustotal_checker.py
│   ├── database/             # Database management
│   │   ├── db_manager.py     # SQLite operations
│   │   └── scans.db          # Scan results (created at runtime)
│   ├── logs/                 # Application logs
│   ├── models/               # (Empty - models are in model_training/)
│   └── uploads/              # Temporary APK storage
│
├── model_training/           # ML model training
│   ├── train_model_production.py
│   ├── train_model_production.ipynb
│   ├── download_datasets.py
│   └── models/               # ✅ TRAINED MODELS HERE
│       ├── malwares_model.pkl
│       ├── malwares_model_scaler.pkl
│       └── malwares_model_metadata.pkl
│
├── frontend/                 # Web interface
│   ├── templates/            # HTML pages
│   │   ├── index.html
│   │   ├── upload.html
│   │   └── history.html
│   └── static/               # CSS, JavaScript
│
├── datasets/                 # Training datasets
│   └── drebin.csv
│
├── cyber/                    # Virtual environment
├── requirements.txt          # Python dependencies
├── .env.example             # Configuration template
└── run.py                   # Application launcher
```

---

## 🚀 Production Deployment (Optional)

### Using Gunicorn (Linux/Mac):
```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 server.app:app
```

### Using Waitress (Windows):
```powershell
pip install waitress
waitress-serve --host=0.0.0.0 --port=5000 server.app:app
```

### Docker Deployment:
```dockerfile
# Future: Create Dockerfile for containerized deployment
```

---

## 📝 Maintenance

### Clear Old Scans:
```python
from server.database.db_manager import DatabaseManager
db = DatabaseManager()
db.delete_old_scans(days=30)  # Delete scans older than 30 days
```

### Update Models:
```powershell
cd model_training
python train_model_production.py
```

### View Logs:
```powershell
Get-Content server\logs\app.log -Tail 50
```

---

## 🎓 Learning Resources

- **Androguard Documentation**: https://androguard.readthedocs.io/
- **Malware Analysis**: https://github.com/rshipp/awesome-malware-analysis
- **Android Security**: https://developer.android.com/topic/security
- **Machine Learning**: https://scikit-learn.org/stable/

---

## ⚠️ Important Disclaimers

1. **Research/Educational Purpose**: This tool is for research and educational purposes
2. **Malware Handling**: Handle malware samples only in isolated environments
3. **Accuracy**: No detection system is 100% accurate - use as one signal among many
4. **Legal Compliance**: Ensure compliance with local laws regarding malware analysis
5. **Privacy**: Do not upload APKs containing sensitive user data to third-party services

---

## 💡 Quick Reference Card

| Task | Command |
|------|---------|
| Activate venv | `.\cyber\Scripts\Activate.ps1` |
| Start server | `python run.py` |
| Access web UI | http://localhost:5000 |
| View logs | `Get-Content server\logs\app.log -Tail 20` |
| Train model | `python model_training\train_model_production.py` |
| Check stats | `curl http://localhost:5000/api/stats` |

---

## 📞 Support

For issues or questions:
1. Check logs: `server/logs/app.log`
2. Review this setup guide
3. Check troubleshooting section
4. Verify all dependencies are installed

**System Status Check:**
- ✅ Virtual environment activated?
- ✅ Dependencies installed?
- ✅ Model files exist?
- ✅ Port 5000 available?
- ✅ APK file valid?

---

**🎉 You're all set! Start scanning APKs for malware! 🎉**
