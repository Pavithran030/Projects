"""
Setup and Installation Script
"""
import os
import sys
import subprocess


def create_directories():
    """Create necessary directories"""
    directories = [
        'server/uploads',
        'server/logs',
        'server/models',
        'server/database',
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        # Create .gitkeep files
        gitkeep_path = os.path.join(directory, '.gitkeep')
        if not os.path.exists(gitkeep_path):
            open(gitkeep_path, 'a').close()
    
    print("✓ Directories created")


def check_python_version():
    """Check if Python version is 3.8 or higher"""
    if sys.version_info < (3, 8):
        print("✗ Python 3.8 or higher is required")
        print(f"  Current version: {sys.version}")
        return False
    print(f"✓ Python version: {sys.version_info.major}.{sys.version_info.minor}")
    return True


def install_dependencies():
    """Install Python dependencies"""
    print("\nInstalling dependencies...")
    try:
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', '-r', 'requirements.txt'])
        print("✓ Dependencies installed")
        return True
    except subprocess.CalledProcessError:
        print("✗ Failed to install dependencies")
        return False


def train_initial_model():
    """Train initial ML model"""
    print("\nTraining initial ML model...")
    try:
        subprocess.check_call([sys.executable, 'server/train_model.py'])
        print("✓ Model trained successfully")
        return True
    except subprocess.CalledProcessError:
        print("✗ Failed to train model")
        return False


def create_env_file():
    """Create .env file from example"""
    if not os.path.exists('.env'):
        if os.path.exists('.env.example'):
            with open('.env.example', 'r') as src:
                with open('.env', 'w') as dst:
                    dst.write(src.read())
            print("✓ Created .env file (please configure it)")
        else:
            print("⚠ .env.example not found")
    else:
        print("✓ .env file already exists")


def main():
    """Main setup function"""
    print("="*60)
    print("APK Malware Detection System - Setup")
    print("="*60)
    
    # Check Python version
    if not check_python_version():
        sys.exit(1)
    
    # Create directories
    create_directories()
    
    # Create .env file
    create_env_file()
    
    # Install dependencies
    if not install_dependencies():
        print("\n✗ Setup failed: Could not install dependencies")
        sys.exit(1)
    
    # Train model
    if not train_initial_model():
        print("\n⚠ Warning: Model training failed")
        print("  You can train it later by running: python server/train_model.py")
    
    print("\n" + "="*60)
    print("✓ Setup completed successfully!")
    print("="*60)
    print("\nNext steps:")
    print("1. Configure .env file (especially VIRUSTOTAL_API_KEY)")
    print("2. Run the application: python server/app.py")
    print("3. Open browser: http://localhost:5000")
    print("\nFor more information, see README.md")


if __name__ == '__main__':
    main()
