/**
 * Upload page JavaScript - handles file upload and scanning
 */

const uploadArea = document.getElementById('uploadArea');
const uploadBox = document.getElementById('uploadBox');
const fileInput = document.getElementById('fileInput');
const filePreview = document.getElementById('filePreview');
const fileName = document.getElementById('fileName');
const fileSize = document.getElementById('fileSize');
const scanButton = document.getElementById('scanButton');
const removeFile = document.getElementById('removeFile');
const scanningStatus = document.getElementById('scanningStatus');
const scanResult = document.getElementById('scanResult');
const uploadForm = document.getElementById('uploadForm');

let selectedFile = null;

// Drag and drop handlers
uploadArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    uploadBox.style.borderColor = 'var(--primary-color)';
    uploadBox.style.background = 'rgba(37, 99, 235, 0.05)';
});

uploadArea.addEventListener('dragleave', (e) => {
    e.preventDefault();
    uploadBox.style.borderColor = 'var(--dark-border)';
    uploadBox.style.background = 'var(--dark-surface)';
});

uploadArea.addEventListener('drop', (e) => {
    e.preventDefault();
    uploadBox.style.borderColor = 'var(--dark-border)';
    uploadBox.style.background = 'var(--dark-surface)';
    
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        handleFileSelect(files[0]);
    }
});

// File input handler
fileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
        handleFileSelect(e.target.files[0]);
    }
});

// Handle file selection
function handleFileSelect(file) {
    // Validate file type
    if (!file.name.endsWith('.apk')) {
        alert('Please select a valid APK file');
        return;
    }
    
    // Validate file size (100 MB max)
    const maxSize = 100 * 1024 * 1024;
    if (file.size > maxSize) {
        alert('File size exceeds 100 MB limit');
        return;
    }
    
    selectedFile = file;
    
    // Update UI
    fileName.textContent = file.name;
    fileSize.textContent = formatFileSize(file.size);
    
    uploadArea.style.display = 'none';
    filePreview.style.display = 'flex';
    scanButton.style.display = 'block';
}

// Remove file handler
removeFile.addEventListener('click', () => {
    selectedFile = null;
    fileInput.value = '';
    
    uploadArea.style.display = 'block';
    filePreview.style.display = 'none';
    scanButton.style.display = 'none';
});

// Form submit handler
uploadForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    if (!selectedFile) {
        alert('Please select a file first');
        return;
    }
    
    // Hide upload form, show scanning status
    uploadBox.style.display = 'none';
    scanningStatus.style.display = 'block';
    scanResult.style.display = 'none';
    
    // Simulate scanning progress
    simulateScanProgress();
    
    // Upload and scan file
    await uploadAndScan(selectedFile);
});

// Simulate scan progress animation
function simulateScanProgress() {
    const steps = ['step1', 'step2', 'step3', 'step4'];
    const texts = [
        'Extracting APK...',
        'Analyzing permissions and components...',
        'Running AI malware detection...',
        'Checking VirusTotal database...'
    ];
    const progressFill = document.getElementById('progressFill');
    const progressText = document.getElementById('progressText');
    
    let currentStep = 0;
    
    const interval = setInterval(() => {
        if (currentStep < steps.length) {
            // Update active step
            steps.forEach((step, index) => {
                const element = document.getElementById(step);
                if (index <= currentStep) {
                    element.classList.add('active');
                } else {
                    element.classList.remove('active');
                }
            });
            
            // Update progress bar
            progressFill.style.width = `${(currentStep + 1) * 25}%`;
            progressText.textContent = texts[currentStep];
            
            currentStep++;
        } else {
            clearInterval(interval);
        }
    }, 1500);
}

// Upload and scan file
async function uploadAndScan(file) {
    const formData = new FormData();
    formData.append('file', file);
    
    try {
        const response = await fetch('/api/scan', {
            method: 'POST',
            body: formData
        });
        
        if (!response.ok) {
            throw new Error('Scan failed');
        }
        
        const data = await response.json();
        
        // Small delay for better UX
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // Display results
        displayResults(data.result, data.cached);
        
    } catch (error) {
        console.error('Scan error:', error);
        displayError(error.message);
    }
}

// Display scan results
function displayResults(result, cached) {
    scanningStatus.style.display = 'none';
    scanResult.style.display = 'block';
    
    const verdictClass = result.verdict.toLowerCase();
    const riskClass = result.risk_score >= 70 ? 'high' : result.risk_score >= 40 ? 'medium' : 'low';
    
    const verdictIcon = {
        'Malicious': 'fa-exclamation-triangle',
        'Suspicious': 'fa-exclamation-circle',
        'Safe': 'fa-check-circle'
    }[result.verdict] || 'fa-question-circle';
    
    let html = `
        <div class="result-header">
            <div>
                <h2>Scan Results</h2>
                ${cached ? '<p style="color: var(--text-muted)"><i class="fas fa-database"></i> Cached result</p>' : ''}
            </div>
            <div style="display: flex; gap: 2rem; align-items: center;">
                <span class="verdict-badge verdict-${verdictClass}">
                    <i class="fas ${verdictIcon}"></i>
                    ${result.verdict}
                </span>
                <div class="risk-score-circle risk-${riskClass}">
                    ${result.risk_score}
                </div>
            </div>
        </div>
        
        <div class="result-section">
            <h3><i class="fas fa-info-circle"></i> APK Information</h3>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">File Name</div>
                    <div class="info-value">${result.filename}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">App Name</div>
                    <div class="info-value">${result.apk_info.app_name}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Package Name</div>
                    <div class="info-value"><code>${result.apk_info.package_name}</code></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Version</div>
                    <div class="info-value">${result.apk_info.version_name} (${result.apk_info.version_code})</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Target SDK</div>
                    <div class="info-value">${result.apk_info.target_sdk}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Min SDK</div>
                    <div class="info-value">${result.apk_info.min_sdk}</div>
                </div>
            </div>
        </div>
    `;
    
    // Source Verification Section (NEW)
    if (result.source_verification) {
        const sv = result.source_verification;
        const verifiedColor = sv.verified ? 'var(--success-color)' : 'var(--danger-color)';
        const verifiedIcon = sv.verified ? 'fa-check-circle' : 'fa-exclamation-triangle';
        const trustPercentage = Math.round((sv.trust_score || 0) * 100);
        
        html += `
            <div class="result-section">
                <h3><i class="fas fa-shield-alt"></i> Source Verification</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">Source</div>
                        <div class="info-value">${sv.source || 'Unknown'}</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Verified</div>
                        <div class="info-value" style="color: ${verifiedColor}">
                            <i class="fas ${verifiedIcon}"></i> ${sv.verified ? 'Yes' : 'No'}
                        </div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Trust Score</div>
                        <div class="info-value">${trustPercentage}%</div>
                    </div>
                </div>
                
                ${sv.certificate ? `
                    <div class="certificate-info" style="margin-top: 1rem; padding: 1rem; background: rgba(255,255,255,0.02); border-radius: 0.5rem;">
                        <strong style="color: var(--primary-color);">Certificate Details:</strong>
                        <div class="info-grid" style="margin-top: 0.5rem;">
                            ${sv.certificate.organization ? `
                                <div class="info-item">
                                    <div class="info-label">Organization</div>
                                    <div class="info-value">${sv.certificate.organization}</div>
                                </div>
                            ` : ''}
                            <div class="info-item">
                                <div class="info-label">Valid Until</div>
                                <div class="info-value">${new Date(sv.certificate.valid_until).toLocaleDateString()}</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Self-Signed</div>
                                <div class="info-value">${sv.certificate.is_self_signed ? 'Yes ⚠️' : 'No ✓'}</div>
                            </div>
                        </div>
                    </div>
                ` : ''}
                
                ${sv.warnings && sv.warnings.length > 0 ? `
                    <div class="warnings" style="margin-top: 1rem; padding: 1rem; background: rgba(239, 68, 68, 0.1); border-left: 3px solid var(--danger-color); border-radius: 0.3rem;">
                        <strong style="color: var(--danger-color);"><i class="fas fa-exclamation-triangle"></i> Certificate Warnings:</strong>
                        <ul style="margin: 0.5rem 0 0 1.5rem; color: var(--text-secondary);">
                            ${sv.warnings.map(w => `<li>${w}</li>`).join('')}
                        </ul>
                    </div>
                ` : ''}
            </div>
        `;
    }
    
    html += `
        
        <div class="result-section">
            <h3><i class="fas fa-brain"></i> AI Detection</h3>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Malware Detected</div>
                    <div class="info-value">${result.ml_prediction.is_malware ? '🔴 Yes' : '🟢 No'}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Confidence</div>
                    <div class="info-value">${(result.ml_prediction.confidence * 100).toFixed(0)}%</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Malware Type</div>
                    <div class="info-value">${result.ml_prediction.malware_type}</div>
                </div>
            </div>
        </div>
    `;
    
    // Dangerous permissions
    if (result.dangerous_permissions && result.dangerous_permissions.length > 0) {
        html += `
            <div class="result-section">
                <h3><i class="fas fa-exclamation-triangle"></i> Dangerous Permissions (${result.dangerous_permissions.length})</h3>
                <div class="permission-list">
                    ${result.dangerous_permissions.map(perm => `
                        <span class="permission-tag"><i class="fas fa-key"></i> ${perm}</span>
                    `).join('')}
                </div>
            </div>
        `;
    }
    
    // Suspicious features
    if (result.suspicious_features && result.suspicious_features.length > 0) {
        html += `
            <div class="result-section">
                <h3><i class="fas fa-flag"></i> Suspicious Features</h3>
                <ul class="recommendation-list">
                    ${result.suspicious_features.map(feature => `
                        <li><i class="fas fa-exclamation-circle"></i> ${feature}</li>
                    `).join('')}
                </ul>
            </div>
        `;
    }
    
    // VirusTotal results
    if (result.virustotal && result.virustotal.available) {
        const vtColor = result.virustotal.detected ? 'var(--danger-color)' : 'var(--success-color)';
        html += `
            <div class="result-section">
                <h3><i class="fas fa-virus"></i> VirusTotal Analysis</h3>
                <div class="info-grid">
                    <div class="info-item">
                        <div class="info-label">Detection Ratio</div>
                        <div class="info-value" style="color: ${vtColor}">
                            ${result.virustotal.positives || 0} / ${result.virustotal.total || 0}
                        </div>
                    </div>
                    ${result.virustotal.scan_date ? `
                    <div class="info-item">
                        <div class="info-label">Scan Date</div>
                        <div class="info-value">${result.virustotal.scan_date}</div>
                    </div>
                    ` : ''}
                </div>
            </div>
        `;
    }
    
    // Recommendations
    if (result.recommendations && result.recommendations.length > 0) {
        html += `
            <div class="result-section">
                <h3><i class="fas fa-lightbulb"></i> Recommendations</h3>
                <ul class="recommendation-list">
                    ${result.recommendations.map(rec => `<li>${rec}</li>`).join('')}
                </ul>
            </div>
        `;
    }
    
    // Scan another file button
    html += `
        <div style="text-align: center; margin-top: 2rem;">
            <button onclick="resetScan()" class="btn btn-primary">
                <i class="fas fa-redo"></i> Scan Another File
            </button>
        </div>
    `;
    
    scanResult.innerHTML = html;
    
    // Scroll to results
    scanResult.scrollIntoView({ behavior: 'smooth' });
}

// Display error
function displayError(message) {
    scanningStatus.style.display = 'none';
    scanResult.style.display = 'block';
    
    scanResult.innerHTML = `
        <div class="result-header" style="border-color: var(--danger-color);">
            <h2><i class="fas fa-exclamation-triangle"></i> Scan Failed</h2>
        </div>
        <div class="result-section">
            <p style="color: var(--danger-color); text-align: center;">
                ${message || 'An error occurred during scanning. Please try again.'}
            </p>
            <div style="text-align: center; margin-top: 2rem;">
                <button onclick="resetScan()" class="btn btn-primary">
                    <i class="fas fa-redo"></i> Try Again
                </button>
            </div>
        </div>
    `;
}

// Reset scan
function resetScan() {
    selectedFile = null;
    fileInput.value = '';
    
    uploadBox.style.display = 'block';
    uploadArea.style.display = 'block';
    filePreview.style.display = 'none';
    scanButton.style.display = 'none';
    scanningStatus.style.display = 'none';
    scanResult.style.display = 'none';
    
    // Scroll to upload box
    uploadBox.scrollIntoView({ behavior: 'smooth' });
}

// Helper function to format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
}
