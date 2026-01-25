"""
Quick start script to run the application
"""
import os
import sys

# Add server directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'server'))

# Import and run the Flask app
from app import app

if __name__ == '__main__':
    print("="*60)
    print("🛡️  APK Malware Detection System")
    print("="*60)
    print("\n🌐 Server starting at: http://localhost:5000")
    print("📊 API endpoint: http://localhost:5000/api/scan")
    print("\n✋ Press CTRL+C to stop the server\n")
    
    # Run the app
    app.run(debug=True, host='0.0.0.0', port=5000)
