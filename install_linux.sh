#!/bin/bash

echo "Installing Web Panel Server Control..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install Python and pip
sudo apt install python3 python3-pip python3-venv -y

# Create application directory
sudo mkdir -p /opt/webpanel
sudo cp -r . /opt/webpanel/

# Create virtual environment
cd /opt/webpanel
sudo python3 -m venv venv
sudo ./venv/bin/pip install -r requirements.txt

# Set permissions
sudo chown -R www-data:www-data /opt/webpanel
sudo chmod +x /opt/webpanel/venv/bin/python

# Install systemd service
sudo cp webpanel.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable webpanel
sudo systemctl start webpanel

# Install nginx (optional)
read -p "Install Nginx reverse proxy? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    sudo apt install nginx -y
    
    # Create nginx config
    sudo tee /etc/nginx/sites-available/webpanel > /dev/null <<EOF
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
    
    sudo ln -s /etc/nginx/sites-available/webpanel /etc/nginx/sites-enabled/
    sudo rm /etc/nginx/sites-enabled/default
    sudo systemctl restart nginx
fi

# Configure firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 5000
sudo ufw --force enable

echo "Installation completed!"
echo "Web Panel is running on http://your_server_ip:5000"
echo "Or http://your_server_ip if nginx was installed"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status webpanel    - Check service status"
echo "  sudo systemctl restart webpanel   - Restart service"
echo "  sudo journalctl -u webpanel -f    - View logs" 