#!/bin/bash
set -e

echo "🚀 Starting ATS environment setup..."

echo "🔹 Updating and installing required packages..."
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip postgresql postgresql-contrib nginx nodejs npm git curl

echo "📁 Creating project directories..."
sudo mkdir -p /var/www/ats /var/www/ats-backups
sudo chown -R ubuntu:www-data /var/www/ats /var/www/ats-backups

echo "🧠 Configuring PostgreSQL..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='ak_user';" | grep -q 1 || \
sudo -u postgres psql -c "CREATE USER ak_user WITH PASSWORD 'navat';"
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='ak_db';" | grep -q 1 || \
sudo -u postgres psql -c "CREATE DATABASE ak_db OWNER ak_user;"

echo "🌐 Configuring Nginx..."
sudo bash -c "cat > /etc/nginx/sites-available/ats.conf" <<EOF
server {
    listen 80;
    server_name ${HOST};

    root /var/www/ats/frontend/dist;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    location /backend/ {
        rewrite ^/backend/?(.*)$ /$1 break;
        proxy_pass http://127.0.0.1:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/ats.conf /etc/nginx/sites-enabled/ats.conf
sudo nginx -t

echo "⚙️ Creating FastAPI systemd service..."
sudo bash -c "cat > /etc/systemd/system/fastapi.service" <<EOF
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
EOF

echo "✅ Environment setup complete (services not started yet)."
