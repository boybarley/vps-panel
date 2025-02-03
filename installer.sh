#!/bin/bash
set -ex

# Konfigurasi dasar
APP_DIR="/opt/vps-panel"
GIT_REPO="https://github.com/username/vps-panel.git"  # Ganti dengan repo Anda

# Update sistem
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl ufw nginx python3 python3-pip python3-venv certbot

# Buat direktori aplikasi
sudo mkdir -p $APP_DIR
sudo chown -R $USER:$USER $APP_DIR

# Clone repositori
git clone $GIT_REPO $APP_DIR

# Setup virtual environment
python3 -m venv $APP_DIR/venv
source $APP_DIR/venv/bin/activate
pip install -r $APP_DIR/backend/requirements.txt

# Konfigurasi Nginx
read -p "Masukkan domain Anda (kosongkan untuk menggunakan IP): " DOMAIN

if [ -z "$DOMAIN" ]; then
    DOMAIN=$(curl -s ifconfig.me)
    sudo cp $APP_DIR/nginx/panel.conf /etc/nginx/sites-available/vps-panel
else
    sudo cp $APP_DIR/nginx/ssl.conf /etc/nginx/sites-available/vps-panel
fi

sudo sed -i "s/your_domain_or_ip/$DOMAIN/g" /etc/nginx/sites-available/vps-panel
sudo ln -sf /etc/nginx/sites-available/vps-panel /etc/nginx/sites-enabled/
sudo systemctl reload nginx

# Setup SSL jika menggunakan domain
if [ -n "$DOMAIN" ]; then
    sudo certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN --redirect
fi

# Firewall configuration
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw --force enable

# Systemd service setup
sudo cp $APP_DIR/systemd/vps-panel.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable vps-panel
sudo systemctl start vps-panel

echo "===================================="
echo "Installasi Berhasil!"
echo "Akses Panel: http://$DOMAIN"
echo "===================================="
