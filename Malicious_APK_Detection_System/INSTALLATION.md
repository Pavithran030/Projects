# 🚀 Complete Installation & Testing Guide

## Step-by-Step Setup

### ✅ Prerequisites Check

Before starting, ensure you have:

```powershell
# Check Python version (must be 3.8+)
python --version

# Check pip
pip --version

# Check git (optional)
git --version
```

**Required**: Python 3.8 or higher

---

## 📦 Installation Methods

### Method 1: Automatic Setup (Recommended)

The easiest way - one command does everything!

```powershell
# Navigate to project directory
cd d:\Projects\CyberSecurity_Hackathon

# Run automated setup
python setup.py
```

**What this does:**
1. ✅ Creates necessary directories
2. ✅ Installs all Python dependencies
3. ✅ Trains the ML model
4. ✅ Creates .env configuration file

**Expected output:**
```
============================================================
APK Malware Detection System - Setup
============================================================
✓ Python version: 3.x
✓ Directories created
✓ .env file created (please configure it)

Installing dependencies...
[Installation progress...]
✓ Dependencies installed

Training initial ML model...
[Training progress...]
✓ Model trained successfully

============================================================
✓ Setup completed successfully!
============================================================
```

**Time**: 5-10 minutes (depending on internet speed)

---

### Method 2: Manual Setup

If automatic setup fails or you prefer manual control:

#### Step 1: Create Directories
```powershell
# Ensure all required directories exist
mkdir -Force server\uploads
mkdir -Force server\logs
mkdir -Force server\models
mkdir -Force server\database
```

#### Step 2: Install Dependencies
```powershell
# Install Python packages
pip install -r requirements.txt
```

**If installation fails**, try:
```powershell
# Upgrade pip first
python -m pip install --upgrade pip

# Then retry
pip install -r requirements.txt
```

#### Step 3: Train ML Model
```powershell
# Train the Random Forest model
python server\train_model.py
```

**Expected output:**
```
==================================================
MALWARE DETECTION MODEL TRAINING
==================================================
Generating 5000 synthetic samples...
Training Random Forest model...
Training set: 4000 samples
Test set: 1000 samples

==================================================
MODEL EVALUATION
==================================================
Accuracy: 95.20%

Classification Report:
              precision    recall  f1-score
Benign           0.96      0.97      0.96
Malicious        0.94      0.93      0.93

✓ Model saved to server/models/malware_model.pkl
```

#### Step 4: Configure Environment
```powershell
# Copy environment template
copy .env.example .env

# Edit .env file (optional - for VirusTotal)
notepad .env
```

---

## 🔧 Configuration

### Basic Configuration (Works out of the box)

The system works without any configuration changes!

### Advanced Configuration (Optional)

#### VirusTotal API Key

To enable VirusTotal scanning:

1. **Get free API key**: https://www.virustotal.com/gui/my-apikey
   - Sign up for free account
   - Copy your API key

2. **Add to .env file**:
   ```
   VIRUSTOTAL_API_KEY=your-actual-api-key-here
   ```

3. **Save and restart application**

**Note**: VirusTotal free tier allows 4 requests/minute

---

## ▶️ Running the Application

### Start the Server

```powershell
# Quick start
python run.py
```

**Expected output:**
```
============================================================
🛡️  APK Malware Detection System
============================================================

🌐 Server starting at: http://localhost:5000
📊 API endpoint: http://localhost:5000/api/scan

✋ Press CTRL+C to stop the server

 * Serving Flask app 'server.app'
 * Debug mode: on
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.1.x:5000
```

### Access the Application

Open your browser and navigate to:
- **Local**: http://localhost:5000
- **Network**: http://YOUR-IP:5000 (for other devices)

---

## 🧪 Testing the Application

### Test 1: Home Page

1. Open http://localhost:5000
2. **Verify**:
   - ✅ Page loads correctly
   - ✅ Navigation menu works
   - ✅ Statistics display (may show 0 initially)
   - ✅ "Scan APK Now" button present

### Test 2: Upload Page

1. Click "Scan APK Now" or navigate to http://localhost:5000/upload
2. **Verify**:
   - ✅ Upload area visible
   - ✅ Drag & drop zone active
   - ✅ "Browse Files" button works

### Test 3: APK Scanning

Since you likely don't have APK files ready, here's how to test:

#### Option A: Download Sample APK (Recommended)

Download a clean APK for testing:
- **F-Droid** (open source): https://f-droid.org/F-Droid.apk
- **Signal**: https://signal.org/android/apk/
- Any APK from APKMirror: https://www.apkmirror.com/

#### Option B: Create Test APK (Advanced)

Use Android Studio to build a simple APK or download from GitHub projects.

#### Perform Scan Test:

1. **Upload APK**:
   - Drag APK file to upload area, or
   - Click "Browse Files" and select APK

2. **Verify Upload**:
   - ✅ File preview shows
   - ✅ File name displayed
   - ✅ File size shown
   - ✅ "Start Scanning" button appears

3. **Start Scan**:
   - Click "Start Scanning"
   - **Verify**:
     - ✅ Scanning animation appears
     - ✅ Progress bar animates
     - ✅ Steps update (1→2→3→4)

4. **Check Results** (after ~15-30 seconds):
   - ✅ Results page displays
   - ✅ Verdict badge shown (Safe/Suspicious/Malicious)
   - ✅ Risk score displayed (0-100)
   - ✅ APK information shown
   - ✅ Permissions listed
   - ✅ ML prediction shown
   - ✅ Recommendations provided

### Test 4: Scan History

1. Navigate to http://localhost:5000/history
2. **Verify**:
   - ✅ Previous scans listed in table
   - ✅ File names shown
   - ✅ Verdicts displayed with colored badges
   - ✅ Risk scores visible

### Test 5: API Testing

#### Using cURL (Windows PowerShell):

```powershell
# Test statistics endpoint
curl http://localhost:5000/api/stats

# Expected output:
# {"total_scans": 1, "malicious": 0, "suspicious": 0, "safe": 1, ...}
```

#### Upload APK via API:

```powershell
# Upload APK file
curl -X POST http://localhost:5000/api/scan -F "file=@C:\path\to\your\app.apk"
```

### Test 6: Error Handling

Test error cases to ensure robustness:

1. **Upload wrong file type**:
   - Try uploading .txt or .jpg file
   - **Expected**: Error message "Only APK files are allowed"

2. **Upload without file**:
   - Click "Start Scanning" without selecting file
   - **Expected**: Error message

3. **Large file** (if you have one > 100 MB):
   - Try uploading
   - **Expected**: "File too large" error

---

## 🐛 Troubleshooting

### Issue 1: Port Already in Use

**Error**: `Address already in use`

**Solution**:
```powershell
# Option A: Kill process using port 5000
netstat -ano | findstr :5000
taskkill /PID [PID_NUMBER] /F

# Option B: Use different port
# Edit run.py, change:
app.run(debug=True, host='0.0.0.0', port=8080)
```

### Issue 2: Module Not Found

**Error**: `ModuleNotFoundError: No module named 'flask'`

**Solution**:
```powershell
# Reinstall dependencies
pip install -r requirements.txt
```

### Issue 3: Androguard Import Error

**Error**: `ImportError: cannot import name 'AnalyzeAPK'`

**Solution**:
```powershell
# Reinstall Androguard
pip uninstall androguard
pip install androguard==4.1.0
```

### Issue 4: ML Model Not Found

**Error**: `Model file not found`

**Solution**:
```powershell
# Train the model
python server\train_model.py
```

### Issue 5: Permission Denied

**Error**: `PermissionError: [Errno 13]`

**Solution**:
```powershell
# Run PowerShell as Administrator
# Or check file permissions
```

### Issue 6: Page Not Loading

**Symptoms**: Blank page or 404 error

**Solution**:
```powershell
# Check if server is running
# Look for "Running on http://127.0.0.1:5000" message

# Try accessing directly:
# http://127.0.0.1:5000 instead of http://localhost:5000
```

### Issue 7: Slow Scanning

**Symptoms**: Scanning takes > 2 minutes

**Possible causes**:
- Large APK file (50+ MB)
- Slow CPU
- Androguard processing time

**Solutions**:
- Test with smaller APK (< 20 MB)
- Check CPU usage
- Normal for first scan (model loading)

---

## 📊 Verification Checklist

After installation and testing, verify:

### Backend
- [ ] Server starts without errors
- [ ] Port 5000 accessible
- [ ] Logs directory created
- [ ] Database file created (after first scan)
- [ ] ML model file exists

### Frontend
- [ ] Home page loads
- [ ] Upload page loads
- [ ] History page loads
- [ ] CSS styles applied
- [ ] JavaScript functions work

### Functionality
- [ ] File upload works
- [ ] APK analysis completes
- [ ] Results display correctly
- [ ] Database stores scans
- [ ] History shows past scans

### API
- [ ] POST /api/scan works
- [ ] GET /api/stats works
- [ ] JSON responses valid

---

## 🎯 Performance Benchmarks

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| Server startup | 2-5 sec | First time may take longer |
| Page load | < 1 sec | Home/Upload/History |
| File upload | 1-5 sec | Depends on file size |
| APK analysis | 15-30 sec | First scan per file |
| Cached scan | < 1 sec | Repeat same file |
| Database query | < 100 ms | History page |

### System Requirements

**Minimum**:
- CPU: Dual-core 2.0 GHz
- RAM: 2 GB
- Storage: 500 MB
- OS: Windows 10/11, Linux, macOS

**Recommended**:
- CPU: Quad-core 2.5 GHz+
- RAM: 4 GB+
- Storage: 1 GB
- SSD for faster I/O

---

## 🔍 Log Files

### Application Logs

Location: `server/logs/app.log`

```powershell
# View logs
Get-Content server\logs\app.log -Tail 50

# Watch logs in real-time
Get-Content server\logs\app.log -Wait -Tail 50
```

### What to look for:
- INFO: Normal operations
- WARNING: Non-critical issues
- ERROR: Problems requiring attention

---

## 📈 Next Steps

### After Successful Installation:

1. **Test with multiple APKs**
   - Download various apps
   - Test clean apps (should be "Safe")
   - Test apps with many permissions

2. **Configure VirusTotal** (Optional)
   - Add API key to .env
   - Restart server
   - Verify VT results appear

3. **Customize** (Optional)
   - Change colors in CSS
   - Modify ML model parameters
   - Add more features

4. **Prepare for Demo**
   - Have 2-3 test APKs ready
   - Practice demo flow
   - Clear scan history if needed

5. **Deploy** (Optional)
   - See DEPLOYMENT.md
   - Use ngrok for quick demo
   - Cloud deployment for production

---

## 💡 Tips for Best Experience

### Performance Tips
1. Use smaller APK files for demos (< 30 MB)
2. Close unnecessary applications
3. Clear browser cache regularly
4. Restart server if slow

### Demo Tips
1. Pre-scan APKs before demo
2. Have backup APKs ready
3. Test internet connection
4. Keep terminal visible (shows progress)

### Development Tips
1. Enable debug mode (already on)
2. Check logs frequently
3. Use browser DevTools (F12)
4. Test on different browsers

---

## 🆘 Getting Help

### Self-Help Resources

1. **Check Documentation**:
   - README.md - Complete guide
   - QUICKSTART.md - Quick reference
   - DEPLOYMENT.md - Deployment help
   - PROJECT_OVERVIEW.md - Technical details

2. **Check Logs**:
   - `server/logs/app.log` - Application logs
   - Browser console (F12) - Frontend errors

3. **Common Issues**: See Troubleshooting section above

### External Resources

- **Androguard**: https://androguard.readthedocs.io/
- **Flask**: https://flask.palletsprojects.com/
- **Scikit-learn**: https://scikit-learn.org/

---

## ✅ Installation Complete!

If you've followed all steps and completed testing, you now have:

✅ **Working backend** with Flask, Androguard, and ML model
✅ **Beautiful frontend** with modern UI
✅ **Complete database** for scan history
✅ **API endpoints** for integration
✅ **Comprehensive logging** for debugging

### You're ready to:
- 🎯 Demo the application
- 🏆 Present at hackathon
- 🚀 Deploy to production
- 🔧 Customize and extend

---

## 🎊 Congratulations!

Your APK Malware Detection System is fully operational!

**Happy Scanning! 🛡️**

---

## Quick Command Reference

```powershell
# Install
python setup.py

# Run
python run.py

# Train model
python server\train_model.py

# View logs
Get-Content server\logs\app.log -Tail 50

# Test API
curl http://localhost:5000/api/stats

# Stop server
Ctrl+C
```

---

*For more help, see README.md or check the logs!*
