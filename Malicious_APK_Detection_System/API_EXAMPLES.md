# API Testing with cURL

## Upload and Scan APK

### Basic Scan
```bash
curl -X POST http://localhost:5000/api/scan \
  -F "file=@/path/to/your/app.apk"
```

### Save Response to File
```bash
curl -X POST http://localhost:5000/api/scan \
  -F "file=@app.apk" \
  -o scan_result.json
```

## Get Statistics

```bash
curl http://localhost:5000/api/stats
```

## Response Format

### Success Response
```json
{
  "status": "success",
  "cached": false,
  "result": {
    "scan_id": "20260112_143025_app.apk",
    "filename": "app.apk",
    "file_hash": "abc123...",
    "verdict": "Suspicious",
    "risk_score": 65,
    "apk_info": {...},
    "permissions": [...],
    "dangerous_permissions": [...],
    "ml_prediction": {...},
    "virustotal": {...},
    "recommendations": [...]
  }
}
```

### Error Response
```json
{
  "error": "Error message",
  "details": "Additional details"
}
```

## Python Example

```python
import requests

# Upload and scan
with open('app.apk', 'rb') as f:
    files = {'file': f}
    response = requests.post('http://localhost:5000/api/scan', files=files)
    result = response.json()
    
print(f"Verdict: {result['result']['verdict']}")
print(f"Risk Score: {result['result']['risk_score']}")
```

## JavaScript Example

```javascript
const formData = new FormData();
formData.append('file', fileInput.files[0]);

fetch('http://localhost:5000/api/scan', {
    method: 'POST',
    body: formData
})
.then(response => response.json())
.then(data => {
    console.log('Verdict:', data.result.verdict);
    console.log('Risk Score:', data.result.risk_score);
});
```
