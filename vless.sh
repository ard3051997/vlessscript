#!/bin/bash

# Introduction
echo "*******************************************************"
echo "Welcome to the XRay Deployment Initialization Script"
echo "*******************************************************"

# Attempt to install X-UI and fix missing dependencies
sudo apt-get update  # Update package lists 
sudo apt install certbot
if ! sudo apt-get install -y x-ui; then
    echo "X-UI installation failed initially. Attempting to fix dependencies..."
    sudo apt-get install -f -y  # Attempt to fix dependencies
    echo "Retrying X-UI installation..."
    sudo apt-get install -y x-ui
fi


echo ""
echo "This script will guide you through the XRay setup process." 
echo "Please have the following information ready:"
echo "- A domain name pointing to your server's IP address."
echo "- Your email address (for Let's Encrypt certificate)."
echo ""

# Input prompts
read -p "Enter your domain name (e.g., t89.uStellvia.com): " domain_name
read -p "Enter your email address for Let's Encrypt: " email_address

# TLS certificate setup
echo ""
echo "************ Setting up TLS Certificate ************"
echo "Do you have a web daemon running on your server? (yes/no): "
read -p "" has_web_daemon

if [[ $has_web_daemon == "yes" ]]; then
    read -p "Enter your web root directory (e.g., /var/www/html): " web_root
    sudo certbot certonly --webroot --agree-tos --email $email_address -d $domain_name -w $web_root
else 
    sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email $email_address -d $domain_name
fi

# Record certificate paths
echo ""
echo "************ Certificate Information ************"
echo "Please record the following certificate paths:"
echo "Public Key Path: " 
read -p "" public_key_path
echo "Private Key Path: "
read -p "" private_key_path

# X-UI Installation
echo ""
echo "************ Installing X-UI ************"
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# X-UI Configuration
echo ""
echo "************ Configuring X-UI ************"
read -p "Enter your desired X-UI panel access port (e.g., 17897): " panel_port

# Modify XUI config for HTTPS (adjust paths if necessary)
sed -i "s|http://127.0.0.1|https://$domain_name|g" /etc/x-ui/x-ui.json 
sed -i "s|/etc/letsencrypt/live/example.com/fullchain.pem|/etc/letsencrypt/live/$domain_name/fullchain.pem|g" /etc/x-ui/x-ui.json
sed -i "s|/etc/letsencrypt/live/example.com/privkey.pem|/etc/letsencrypt/live/$domain_name/privkey.pem|g" /etc/x-ui/x-ui.json

# Restart X-UI
systemctl restart x-ui

echo ""
echo "************ Setup Complete! ************"
echo "You can now access the X-UI panel at https://$domain_name:$panel_port"
echo "Please refer to the X-UI documentation for further configuration." 

# Automatic Renewal Setup
echo ""
echo "************ Setting Up Automatic Renewal ************"

# Create a cron job for renewal (adjust if needed)
echo "0 0 * * 1 certbot renew --quiet" | sudo tee -a /etc/crontab > /dev/null 

echo ""
echo "************ Setup Complete! ************"
echo "Your Let's Encrypt certificate will now renew automatically."
echo "You can now access the X-UI panel at https://$domain_name:$panel_port"
echo "Please refer to the X-UI documentation for further configuration."