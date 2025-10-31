#!/bin/bash
set -e

echo "🚀 Starting ATS environment setup..."

# ---------- Variables ----------
APP_DIR="/var/www/ats"
BACKUP_DIR="/var/www/ats-backups/backend"
DB_USER="ak_user"
DB_PASS="navat"
DB_NAME="ak_db"

# ---------- Update & Install dependencies ----------
echo "🔹 Updating system packages..."
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip postgresql postgresql-contrib nginx nodejs npm git curl

# ---------- Create directories ----------
echo "📁 Creating application directories..."
sudo mkdir -p ${APP_DIR}/backend ${APP_DIR}/frontend ${BACKUP_DIR}
sudo chown -R ubuntu:www-data ${APP_DIR} /var/www/ats-backups
sudo chmod -R 775 ${APP_DIR}

# ---------- PostgreSQL Configuration ----------
echo "🧠 Configuring PostgreSQL..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}';" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';"

sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}';" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"

# ---------- Nginx Configuration ----------
echo "⚙️ Setting up Nginx configuration..."
sudo bash -c "cat > /etc/nginx/sites-available/ats.conf" <<'NGINXCONF'
server {
    listen 80;
    server_name REPLACE_WITH_IP;

    # Frontend
    root /var/www/ats/frontend/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Backend
    location /backend/ {
        rewrite ^/backend/?(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINXCONF

sudo ln -sf /etc/nginx/sites-available/ats.conf /etc/nginx/sites-enabled/ats.conf

# ---------- FastAPI Systemd Service ----------
echo "🧩 Creating FastAPI systemd service..."
sudo bash -c "cat > /etc/systemd/system/fastapi.service" <<'SERVICE'
[Unit]
Description=FastAPI Backend
After=network.target

[Service]
User=ubuntu
Group=www-data
WorkingDirectory=/var/www/ats/backend
EnvironmentFile=/var/www/ats/backend/.env
ExecStart=/var/www/ats/backend/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
Restart=always
StandardOutput=append:/var/log/fastapi.log
StandardError=append:/var/log/fastapi.log

[Install]
WantedBy=multi-user.target
SERVICE

echo "✅ ATS environment setup completed successfully (services not started)."
