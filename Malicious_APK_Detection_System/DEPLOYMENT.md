# Deployment Guide

## 🌐 Deployment Options

### 1. Local Development

**Default setup** - Already configured

```bash
python run.py
```

Access at: `http://localhost:5000`

---

### 2. Production with Gunicorn

**For Linux/Mac production servers**

#### Install Gunicorn
```bash
pip install gunicorn
```

#### Run with Gunicorn
```bash
gunicorn -w 4 -b 0.0.0.0:5000 server.app:app
```

Options:
- `-w 4`: 4 worker processes
- `-b 0.0.0.0:5000`: Bind to all interfaces on port 5000
- `--timeout 300`: Increase timeout for large APK files

#### With systemd (Linux)
Create `/etc/systemd/system/apk-scanner.service`:

```ini
[Unit]
Description=APK Malware Detection System
After=network.target

[Service]
User=www-data
WorkingDirectory=/var/www/CyberSecurity_Hackathon
Environment="PATH=/var/www/CyberSecurity_Hackathon/venv/bin"
ExecStart=/var/www/CyberSecurity_Hackathon/venv/bin/gunicorn -w 4 -b 0.0.0.0:5000 server.app:app

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable apk-scanner
sudo systemctl start apk-scanner
```

---

### 3. Nginx Reverse Proxy

**Recommended for production**

#### Install Nginx
```bash
sudo apt install nginx
```

#### Configure Nginx
Edit `/etc/nginx/sites-available/apk-scanner`:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    client_max_body_size 100M;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 300s;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/apk-scanner /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

#### Add SSL with Let's Encrypt
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

### 4. Docker Deployment

#### Create Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create necessary directories
RUN mkdir -p server/uploads server/logs server/models server/database

# Expose port
EXPOSE 5000

# Run application
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "--timeout", "300", "server.app:app"]
```

#### Create docker-compose.yml
```yaml
version: '3.8'

services:
  apk-scanner:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./server/database:/app/server/database
      - ./server/logs:/app/server/logs
      - ./server/models:/app/server/models
    environment:
      - VIRUSTOTAL_API_KEY=${VIRUSTOTAL_API_KEY}
    restart: unless-stopped
```

#### Build and Run
```bash
docker-compose up -d
```

---

### 5. Heroku Deployment

#### Create Procfile
```
web: gunicorn server.app:app
```

#### Create runtime.txt
```
python-3.9.18
```

#### Deploy
```bash
heroku create apk-scanner-demo
heroku config:set VIRUSTOTAL_API_KEY=your-key
git push heroku main
```

---

### 6. AWS EC2 Deployment

#### Launch EC2 Instance
- Ubuntu Server 22.04 LTS
- t2.medium or larger
- Security Group: Allow ports 22, 80, 443

#### Setup Script
```bash
#!/bin/bash

# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and dependencies
sudo apt install python3-pip python3-venv nginx -y

# Clone repository
git clone <your-repo>
cd CyberSecurity_Hackathon

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install gunicorn

# Run setup
python setup.py

# Configure environment
cp .env.example .env
nano .env  # Add VirusTotal key

# Setup systemd and nginx
# (Follow steps from section 2 and 3)
```

---

### 7. Google Cloud Platform

#### Using App Engine

Create `app.yaml`:
```yaml
runtime: python39

instance_class: F2

entrypoint: gunicorn -b :$PORT server.app:app

env_variables:
  VIRUSTOTAL_API_KEY: "your-key"
```

Deploy:
```bash
gcloud app deploy
```

---

### 8. Azure App Service

#### Using Azure CLI
```bash
az webapp up --name apk-scanner --runtime "PYTHON:3.9"
az webapp config appsettings set --name apk-scanner --settings VIRUSTOTAL_API_KEY=your-key
```

---

### 9. Ngrok (Quick Demo)

**Perfect for hackathon presentations**

#### Install Ngrok
Download from: https://ngrok.com/download

#### Run Application
```bash
python run.py
```

#### Expose with Ngrok
```bash
ngrok http 5000
```

You'll get a public URL like: `https://abc123.ngrok.io`

---

## 🔒 Production Checklist

Before deploying to production:

- [ ] Change `SECRET_KEY` in `.env`
- [ ] Set `FLASK_ENV=production`
- [ ] Disable Flask debug mode
- [ ] Configure proper logging
- [ ] Set up HTTPS/SSL
- [ ] Add rate limiting
- [ ] Implement authentication (if needed)
- [ ] Configure firewall rules
- [ ] Set up backup for database
- [ ] Monitor server resources
- [ ] Add error tracking (e.g., Sentry)

---

## 📊 Performance Tuning

### For High Traffic

1. **Increase Workers**
   ```bash
   gunicorn -w 8 server.app:app
   ```

2. **Use Redis for Caching**
   ```bash
   pip install redis
   ```

3. **Database Optimization**
   - Add more indexes
   - Use connection pooling

4. **Load Balancing**
   - Multiple server instances
   - Nginx load balancer

---

## 🔍 Monitoring

### Application Logs
```bash
tail -f server/logs/app.log
```

### System Resources
```bash
htop  # CPU and memory
df -h  # Disk space
```

### Nginx Logs
```bash
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

---

## 🆘 Troubleshooting

### Application won't start
- Check logs: `server/logs/app.log`
- Verify Python version: `python --version`
- Check dependencies: `pip list`

### Upload fails
- Check file size limit
- Verify upload directory permissions
- Check disk space

### Slow performance
- Increase worker count
- Add more server resources
- Optimize ML model

---

**Need help? Check README.md or create an issue**
