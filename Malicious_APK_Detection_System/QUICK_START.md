# ✅ Quick Start Checklist

## Before Running the Application

### 1️⃣ System Check
```powershell
# Navigate to project
cd d:\Projects\Malicious_APK_Detection_System

# Check Python version (must be 3.8+)
python --version
```
Expected: `Python 3.11.x` ✅

---

### 2️⃣ Activate Virtual Environment
```powershell
.\cyber\Scripts\Activate.ps1
```
Expected: Terminal shows `(cyber)` prefix ✅

---

### 3️⃣ Verify Dependencies
```powershell
pip list | Select-String "flask|androguard|scikit-learn"
```
Expected output should include:
- ✅ flask (3.0.0)
- ✅ androguard (4.1.0)
- ✅ scikit-learn (1.3.2)

**If missing:**
```powershell
pip install -r requirements.txt
```

---

### 4️⃣ Check Model Files
```powershell
Get-ChildItem model_training\models\ -Name
```
Expected files:
- ✅ malwares_model.pkl (13.9 MB)
- ✅ malwares_model_scaler.pkl (5.6 KB)
- ✅ malwares_model_metadata.pkl (105 bytes)

**Status:** ✅ All 3 model files present

---

### 5️⃣ Verify Configuration
```powershell
Get-Content .env | Select-String "VIRUSTOTAL"
```
**Current status:** ✅ VirusTotal API key configured

---

## 🚀 Launch Application

### Simple Method:
```powershell
python run.py
```

### Alternative Method:
```powershell
cd server
python app.py
```

---

## 📊 Expected Console Output

When server starts successfully:
```
============================================================
🛡️  APK Malware Detection System
============================================================

🌐 Server starting at: http://localhost:5000
📊 API endpoint: http://localhost:5000/api/scan

✋ Press CTRL+C to stop the server

2026-01-14 16:00:00 - INFO - ✓ ML model loaded from ../model_training/models/malwares_model.pkl
2026-01-14 16:00:00 - INFO - ✓ Scaler loaded
2026-01-14 16:00:00 - INFO - ✓ Metadata loaded
2026-01-14 16:00:00 - INFO - ML prediction system ready
2026-01-14 16:00:00 - INFO - VirusTotal integration enabled
2026-01-14 16:00:00 - INFO - Database initialized at database/scans.db
2026-01-14 16:00:00 - INFO - Starting Malicious APK Detection System...
 * Running on http://0.0.0.0:5000
```

✅ **If you see this, the system is ready!**

---

## 🌐 Access the Application

Open your browser and go to:
- **Home Page:** http://localhost:5000
- **Upload Page:** http://localhost:5000/upload
- **History Page:** http://localhost:5000/history

---

## 📱 What You Need to Scan

### Input: APK File

**Where to get APK files:**

#### Option 1: From Your Android Device
1. Install "APK Extractor" app from Play Store
2. Open APK Extractor → Select any installed app
3. Tap "Extract" → Save APK
4. Transfer APK to your computer (USB/Email/Cloud)

#### Option 2: Download from Internet
- **APKPure:** https://apkpure.com/
- **APKMirror:** https://www.apkmirror.com/
- **F-Droid (Open Source):** https://f-droid.org/

#### Option 3: Your Own Apps
If you're an Android developer:
1. Build your project in Android Studio
2. Find APK at: `app/build/outputs/apk/debug/app-debug.apk`

---

## 🎯 How to Use

### Method 1: Web Interface

1. Open http://localhost:5000/upload
2. Click "Choose File" button
3. Select your .apk file
4. Click "Upload & Scan"
5. Wait 5-30 seconds for analysis
6. View detailed results

### Method 2: API (Command Line)

```powershell
# Upload APK via API
curl -X POST http://localhost:5000/api/scan -F "file=@C:\path\to\your\app.apk"
```

Or using PowerShell:
```powershell
$apkPath = "C:\path\to\your\app.apk"
$uri = "http://localhost:5000/api/scan"
$form = @{
    file = Get-Item -Path $apkPath
}
Invoke-RestMethod -Uri $uri -Method Post -Form $form
```

---

## 📋 Understanding Results

### The system provides:

1. **Verdict:** 
   - ✅ Safe (Risk score 0-39)
   - ⚠️ Suspicious (Risk score 40-69)
   - 🚨 Malicious (Risk score 70-100)

2. **Risk Score:** 0-100 calculated from:
   - ML model prediction (40%)
   - Dangerous permissions (20%)
   - Suspicious features (20%)
   - VirusTotal detections (20%)

3. **APK Information:**
   - Package name (e.g., com.example.app)
   - App name
   - Version
   - SDK versions

4. **Permissions Analysis:**
   - All permissions requested
   - Dangerous permissions highlighted
   - Privacy concerns

5. **ML Prediction:**
   - Malware/Benign classification
   - Confidence score (0.00-1.00)
   - Malware type identification

6. **VirusTotal Results:**
   - Detection ratio (X/70+ engines)
   - Link to full report
   - Individual AV detections

7. **Recommendations:**
   - Security advice
   - Installation warnings
   - Privacy concerns

---

## 🔄 System Workflow

```
Upload APK File (.apk)
        ↓
Calculate SHA256 Hash
        ↓
Check Database (Cache)
        ↓
  Found? → Return Instant Result ✅
    ↓ Not Found
Static Analysis (Androguard)
  - Extract APK info
  - Parse AndroidManifest.xml
  - List permissions
  - Analyze components
        ↓
Feature Extraction (50 features)
  - 40 permission features
  - 4 component features  
  - 6 suspicious pattern features
        ↓
ML Prediction (Random Forest)
  - Scale features
  - Predict: Malware/Benign
  - Calculate confidence
        ↓
VirusTotal Check (Online)
  - Query file hash
  - Get detection ratio
        ↓
Risk Score Calculation
  - Combine all signals
  - Generate 0-100 score
        ↓
Save to Database
  - Store complete results
  - Enable future caching
        ↓
Return Results (JSON/Web)
```

---

## 🧪 Test Examples

### Test 1: Upload a Safe App
```powershell
# Example with a legitimate app
curl -X POST http://localhost:5000/api/scan -F "file=@gmail.apk"
```
Expected: Verdict = "Safe", Risk Score < 40

### Test 2: Check Statistics
```powershell
curl http://localhost:5000/api/stats
```
Expected: JSON with total scans and counts

### Test 3: View Scan History
Open: http://localhost:5000/history

---

## ⚠️ Common Issues & Solutions

### Issue 1: "Address already in use"
**Problem:** Port 5000 is occupied
**Solution:**
```powershell
# Find and kill process on port 5000
Stop-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess -Force
```

### Issue 2: "Module not found: androguard"
**Problem:** Dependencies not installed
**Solution:**
```powershell
pip install -r requirements.txt
```

### Issue 3: "ML model not found"
**Problem:** Model path incorrect or files missing
**Solution:** Already fixed! Models are at: `model_training/models/`

### Issue 4: "VirusTotal not available"
**Problem:** API key missing or invalid
**Solution:** 
- Check `.env` file has valid `VIRUSTOTAL_API_KEY`
- System works without it (uses ML only)

### Issue 5: APK analysis fails
**Problem:** Corrupted or invalid APK file
**Solution:**
- Verify APK is not corrupted
- Try with a different APK file
- Check file size (must be < 100 MB)

---

## 📊 Performance Expectations

| Metric | Expected Value |
|--------|---------------|
| Scan time | 5-30 seconds |
| Max file size | 100 MB |
| ML accuracy | ~85-95% |
| Database response | < 1 second (cached) |
| VirusTotal query | 2-5 seconds |

---

## 🛑 Stop the Server

Press `CTRL+C` in the terminal running the server

---

## 📝 Summary

**You're ready to start!**

**Quick commands:**
```powershell
# 1. Activate environment
.\cyber\Scripts\Activate.ps1

# 2. Start server
python run.py

# 3. Open browser
start http://localhost:5000/upload

# 4. Upload APK and scan!
```

**Required Input:**
- ✅ APK file (.apk extension)
- ✅ Size: < 100 MB
- ✅ Format: Valid Android APK

**Optional:**
- VirusTotal API key (already configured ✅)

---

## 🎉 Ready to Scan!

Your system is **100% configured and ready to use**!

1. ✅ Virtual environment: cyber/
2. ✅ Dependencies: Installed
3. ✅ ML Models: All 3 files present
4. ✅ Database: Auto-created on first run
5. ✅ VirusTotal: API key configured
6. ✅ Server code: Updated to use models

**Just run:** `python run.py` **and start scanning!**
