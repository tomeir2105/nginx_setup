#!/usr/bin/env bash
######################################
# Created by : Meir
# Purpose : nginx modules install script
# Date : 7/3/25
# Version : 1
#set -x
set -o errexit
set -o pipefail
set -o nounset
#####################################

NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}' | sed 's/ .*//')
HTPASSWD_FILE="/etc/nginx/.htpasswd"
PAM_PACKAGES=(
    'libpam0g-dev'
    'libpam-modules'
)
AUTH_PACKAGES=(
    'apache2-utils' 
    'nginx-extras'
)
CGI_PACKAGES=(
    'fcgiwrap'
)

ENABLE_USER_DIR=false
ENABLE_AUTH=false
ENABLE_CGI=false
DOMAIN=""
NGINX_USERNAME=""
CONF_FILE=""

show_help() {
    echo "Usage: $0 -d <domain> [-u] [-a <nginx_username>] [-c]"
    echo "Installs required modules for NGINX."
    echo
    echo "Arguments:"
    echo "  -d <domain>       The domain name for NGINX configuration (required)."
    echo "  -a <nginx_username> Enable authentication feature with specified username."
    echo
    echo "Options:"
    echo "  -u                Enable userdir feature to ~/public_html."
    echo "  -p                Enable PAM for domain."
    echo "  -c                Enable CGI feature."
    echo "  -h, --help        Show this help message and exit."
    exit 0
}

if [[ $# -eq 0 ]]; then
    echo "Error: Missing arguments."
    show_help
    exit 1
fi

while getopts ":d:a:ucp" opt; do
    case ${opt} in
        d) DOMAIN="$OPTARG" ;;
        u) ENABLE_USER_DIR=true ;;
        a) ENABLE_AUTH=true; NGINX_USERNAME="$OPTARG" ;;
        c) ENABLE_CGI=true ;;
        p) ENABLE_PAM=true ;;
        *) show_help ;;
    esac
done

main_script() {
    startup_checks
    echo "This tool will install selected modules on NGINX"
    echo "NGINX Version $NGINX_VERSION"
    echo "Installing packages in background... have patience"
    check_nginx_common
    update_apt
    if $ENABLE_USER_DIR; then 
        install_utilities "${PAM_PACKAGES[@]}"
        check_user_dir_module 
        add_userdir_to_nginx
    fi
    if $ENABLE_AUTH; then 
        install_utilities "${AUTH_PACKAGES[@]}"
        create_new_user_password
        add_auth_to_nginx
    fi
    if $ENABLE_PAM; then
        install_utilities "${PAM_PACKAGES[@]}"
        add_pam_to_nginx
        add_pam_to_pamd
    fi
    if $ENABLE_CGI; then 
        install_utilities "${CGI_PACKAGES[@]}"
        add_cgi_to_nginx
    fi
    echo "Setup complete."
}

startup_checks() {
    if [[ -z "$DOMAIN" ]]; then
        echo "Error: Domain name is required."
        show_help
        exit 1
    fi
    CONF_FILE="/etc/nginx/sites-available/$DOMAIN"
    if [ ! -f "$CONF_FILE" ]; then
        echo "Error: $DOMAIN does not exist."
        exit 1
    fi

    if $ENABLE_AUTH && [[ -z "$NGINX_USERNAME" ]]; then
        echo "Error: Authentication requires a username."
        show_help
        exit 1
    fi

    if [ "$(id -u)" -eq 0 ]; then
        echo "Run script with non-root user."
        exit 1
    fi
}

check_nginx_common() {
    if ! dpkg -s 'nginx-common' &>/dev/null; then
        echo "nginx-common is missing"
        echo "Install nginx with - sudo apt update && sudo apt install nginx -y"
        exit 1
    fi
}

update_apt(){
    sudo apt-get update > /dev/null 2>&1
}

install_utilities(){
    for UTIL in "$@"; do
        sudo apt-get install -y $UTIL > /dev/null 2>&1
        if dpkg -s $UTIL &>/dev/null; then
            echo "$UTIL installed successfully."
        else
            echo "$UTIL installation failed."
            exit 1
        fi
    done
}

add_pam_to_pamd(){
    if [ ! -f /etc/pam.d/nginx ]; then
        echo -e "auth       include      common-auth\naccount    include      common-account" | sudo tee -a /etc/pam.d/nginx > /dev/null
        sudo usermod -aG shadow www-data
        sudo systemctl reload nginx 
        sudo mkdir /var/www/$DOMAIN/auth-pam
        echo -E "<!DOCTYPE html>
    <html>
        <body>
            Site is up and running!
        </body>
    </html>" | sudo tee /var/www/$DOMAIN/auth-pam/index.html > /dev/null
        echo "Finished setting pam config."
        echo "Added index.html to pam folder."
        echo "Reloading NGINX to apply the auth changes..."
        sudo systemctl restart nginx
    fi
}

add_pam_to_nginx(){
    if grep -q "location /auth-pam" "$CONF_FILE"; then
        echo "Error: The location /auth-pam block already exists in the configuration file."
        exit 1
    fi
       
    echo "Adding the authentication block for /auth-pam to $CONF_FILE"
    sudo sed -i '$s/}$//' $CONF_FILE # Inline REMOVE LAST }
    echo "        location /auth-pam {
            auth_pam \"PAM Authentication\";
            auth_pam_service_name \"nginx\";
        }
    }" | sudo tee -a "$CONF_FILE" > /dev/null
    echo "Testing the NGINX configuration for errors..."
    sudo nginx -t
    if [ $? -ne 0 ]; then
        echo "Error: NGINX configuration test failed. Please fix the errors above."
        exit 1
    fi
}

add_userdir_to_nginx() {
    if grep -q "location ~ ^/~" "$CONF_FILE"; then
        echo "Error: userdir already exists in the configuration file."
        exit 1
    fi
    
    if [ ! -d "$HOME/public_html" ]; then 
        echo "Creating public_html folder"
        mkdir -p "$HOME/public_html"
    fi
    
    echo "Adding userdir configuration to $CONF_FILE"
    sudo sed -i '$s/}$//' "$CONF_FILE" # Inline REMOVE LAST }
    echo "        location ~ ^/~([^/]+)(/.*)?$ {
           alias /home/\$1/public_html\$2;
           autoindex on;
       }
    }" | sudo tee -a "$CONF_FILE"
    
    echo "Testing the NGINX configuration for syntax errors..."
    sudo nginx -t
    if [ $? -ne 0 ]; then
        echo "Error: NGINX configuration test failed. Please fix the errors above."
        exit 1
    fi
    
    echo "Reloading NGINX to apply the changes..."
    sudo systemctl restart nginx
}



create_new_user_password(){
    echo "Enter password for nginx user"
    sudo htpasswd -c $HTPASSWD_FILE $NGINX_USERNAME
}

add_auth_to_nginx() {   
    if grep -q "location /secure" "$CONF_FILE"; then
        echo "Error: The location /secure block already exists in the configuration file."
        exit 1
    fi
    
    if [ ! -d  "/var/www/$DOMAIN/html/secure" ]; then 
        echo "Creating secure folder"
        sudo mkdir -p "/var/www/$DOMAIN/html/secure"
        echo "This is the secure area" | sudo tee "/var/www/$DOMAIN/html/secure/index.html"
    fi
    
    echo "Adding the authentication block for /secure to $CONF_FILE"
    sudo sed -i '$s/}$//' $CONF_FILE # Inline REMOVE LAST }
    echo "        location /secure {
            auth_basic \"Restricted Access\";
            auth_basic_user_file /etc/nginx/.htpasswd;
            root /var/www/$DOMAIN/html;
            index index.html; 
        }
    }" | sudo tee -a "$CONF_FILE"
    echo "Testing the NGINX configuration for errors..."
    sudo nginx -t
    if [ $? -ne 0 ]; then
        echo "Error: NGINX configuration test failed. Please fix the errors above."
        exit 1
    fi
    
    echo "Reloading NGINX to apply the auth changes..."
    sudo systemctl restart nginx
}

add_cgi_to_nginx() {
    CONF_FILE="/etc/nginx/sites-available/$DOMAIN"
    echo "        location /cgi-bin/ {
        root /usr/lib;
        fastcgi_pass unix:/run/fcgiwrap.socket;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        }
    }" | sudo tee -a "$CONF_FILE"
    sudo systemctl restart fcgiwrap
    sudo systemctl restart nginx
    sudo mkdir -p /usr/lib/cgi-bin
    echo -e '#!/bin/bash\necho "Content-type: text/plain"\necho\necho "Hello, CGI!"' | sudo tee /usr/lib/cgi-bin/test.cgi
    sudo chmod +x /usr/lib/cgi-bin/test.cgi
}

check_user_dir_module(){
    minimum_version="1.7.4"
    nginx_min_version_number=$(echo "$NGINX_VERSION" | tr -d '.')
    minimum_version_number=$(echo "$minimum_version" | tr -d '.')
    if [[ "$nginx_min_version_number" -lt "$minimum_version_number" ]]; then
        echo "Your NGINX version $NGINX_VERSION is not supported."
        exit 1
    fi
}

main_script
