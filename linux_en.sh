#!/bin/bash

echo_status() {
    echo -e "\n--- $1 ---\n"
}

echo "Starting Web Panel Server Control installation..."

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Please run this script with sudo: sudo ./install_and_start_webpanel.sh"
    exit 1
fi

echo_status "1. Updating system and installing prerequisites"
apt update && apt upgrade -y
if [ $? -ne 0 ]; then
    echo "ERROR: System update or upgrade failed."
    exit 1
fi
apt install python3 python3-pip python3-venv procps curl -y
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install Python or other prerequisites."
    exit 1
fi

echo_status "2. Preparing application directory"
APP_DIR="/opt/webpanel"
mkdir -p "$APP_DIR"
cp -r "$(dirname "$0")"/* "$APP_DIR"/
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy application files to $APP_DIR."
    exit 1
fi
chmod +x "$APP_DIR"/examples/*.py

echo_status "3. Setting up virtual environment and installing dependencies"
cd "$APP_DIR" || { echo "ERROR: Failed to change directory to $APP_DIR"; exit 1; }
python3 -m venv venv
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create virtual environment."
    exit 1
fi
./venv/bin/pip install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to install all dependencies. Web Panel might not function correctly."
    echo "Please check requirements.txt and your internet connection."
fi
chown -R www-data:www-data "$APP_DIR"
chmod +x "$APP_DIR"/venv/bin/python

echo_status "4. Installing systemd service"
cp webpanel.service /etc/systemd/system/webpanel.service
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to copy webpanel.service file."
    exit 1
fi
systemctl daemon-reload
systemctl enable webpanel
systemctl start webpanel
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to enable or start webpanel service."
    echo "Please check 'sudo journalctl -u webpanel -f' for details."
fi
echo "Web Panel service installed and started."

echo_status "5. Configuring Nginx reverse proxy (Optional)"
read -p "Do you want to install Nginx reverse proxy for Web Panel? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    apt install nginx -y
    if [ $? -ne 0 ]; then
        echo "WARNING: Failed to install Nginx. Skipping Nginx configuration."
    else
        tee /etc/nginx/sites-available/webpanel > /dev/null <<EOF
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
        ln -sf /etc/nginx/sites-available/webpanel /etc/nginx/sites-enabled/
        rm -f /etc/nginx/sites-enabled/default
        systemctl restart nginx
        if [ $? -ne 0 ]; then
            echo "WARNING: Nginx installed but failed to configure or restart."
        else
            echo "Nginx configured successfully."
        fi
    fi
else
    echo "Skipping Nginx installation."
fi

echo_status "6. Configuring firewall"
ufw allow 22
ufw allow 80
ufw allow 5000
ufw --force enable
if [ $? -ne 0 ]; then
    echo "WARNING: Failed to configure UFW firewall. Please check manually."
fi
echo "Firewall configured."

echo_status "Installation completed!"
echo "Web Panel is running on http://your_server_ip:5000"
echo "Or http://your_server_ip if Nginx was installed."
echo ""
echo "Useful commands:"
echo "  sudo systemctl status webpanel    - Check service status"
echo "  sudo systemctl restart webpanel   - Restart service"
echo "  sudo journalctl -u webpanel -f    - View logs"
echo "To stop the panel, use 'sudo systemctl stop webpanel'"
echo "" 