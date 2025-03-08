#!/usr/bin/env bash
######################################
# Created by : Meir
# Purpose : nginx create virtual host script
# Date : 7/3/25
# Version : 1
#set -x
set -o errexit
set -o pipefail
set -o nounset
#####################################

# This script is for Ubuntu / Debian Systems only
nginx_root="/var/www"

# Display help function
display_help() {
    echo "Usage: $0 [domain_name]"
    echo
    echo "Options:"
    echo "  domain_name       The name of the virtual host (e.g., example.com)"
    echo "  -h, --help        Display this help message and exit"
    echo
    exit 0
}

if [ -z "${1:-}" ]; then
    echo "Missing required domain name (site.com)"
    echo "Use -h or --help for usage information."
    exit 1
fi

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
fi

check_nginx_common() {
    if ! dpkg -s 'nginx-common' &>/dev/null; then
        echo "nginx-common is missing"
        echo "Install nginx with - sudo apt update && sudo apt install nginx -y"
        exit 1
    fi
}

# check if nginx is running
check_nginx_running() {
    if systemctl is-active --quiet nginx; then
        echo "nginx Installed and Running"
    else
        echo "nginx Installed and not Running"
    fi
}

# check nginx installation and status
check_nginx() {
    check_nginx_common
    check_nginx_running
}

# create domain folder and set permissions
create_domain_folder() {
    full_domain_folder="$nginx_root/$1"
    sudo mkdir -p $full_domain_folder
    sudo mkdir -p $full_domain_folder/html
    sudo chown -R $USER:$USER $full_domain_folder/html
    sudo chmod -R 755 $nginx_root
    echo "Domain folder created and permissions granted."
}

# copy and configure domain config
create_domain_config() {
    echo "server {
        listen 80;
        server_name $1 www.$1;
        root /var/www/$1/html;
        index index.html;
        location / { 
            index index.html; 
            }
    }" | sudo tee "/etc/nginx/sites-available/$1" > /dev/null

    if [ $? -ne 0 ]; then
        echo "Failed writing configuration to sites-available."
        cleanup_after_failure $1
        exit 1
    fi

    echo "Successfully created configuration file for $1"
}

# create a symlink to site
enable_virtual_host() {
    if [ -L "/etc/nginx/sites-enabled/$1" ]; then
        echo "Symlink already exists. Removing it..."
        sudo rm "/etc/nginx/sites-enabled/$1"
    fi

    sudo ln -s "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/"
    if [ $? -ne 0 ]; then
        echo "Failed creating link to site."
        cleanup_after_failure $1
        exit 1
    fi

    echo "Virtual host linked in sites-enabled"
    sudo systemctl restart nginx
    sudo nginx -t
}

copy_index_html() {
    echo -E "<!DOCTYPE html>
    <html>
        <body>
            Site is up and running!
        </body>
    </html>" | sudo tee $nginx_root/$1/html/index.html > /dev/null
    echo "Created index.html file in - $nginx_root/$1/html"
}

test_nginx_configuration() {
    test_site=$(sudo nginx -t 2>&1)
    if echo $test_site | grep -q "test failed"; then
        echo "Configuration error, check /etc/nginx/sites-available/$1"
        echo "Process failed, try again with a different virtual host name"
        cleanup_after_failure $1
        exit 1
    else
        echo "Configuration checks successful"
    fi
}

cleanup_after_failure() {
    echo "Removing all files added. Start again"
    sudo rm -rf /etc/nginx/sites-enabled/$1
    sudo rm -rf /etc/nginx/sites-available/$1
    sudo rm -rf $nginx_root/$1
    sudo systemctl restart nginx
    echo "Virtual host removed."
}

finalize_nginx_local_setup() {
    sudo systemctl restart nginx
    echo "127.0.0.1 $1" | sudo tee -a "/etc/hosts" > /dev/null
    echo "Domain added to /etc/hosts"
    firefox "http://$1/"
}

handle_existing_virtual_host() {
    echo "$1 Exists. Do you want to remove this virtual host (yes/no)?"
    read remove_domain
    if [[ $remove_domain == "yes" ]]; then
        cleanup_after_failure $1
        exit 1
    fi
}

create_virtual_host() {
    full_domain_folder="$nginx_root/$1"
    
    if [ ! -d "$full_domain_folder" ]; then
        create_domain_folder $1
        create_domain_config $1
        enable_virtual_host $1
        copy_index_html $1
        test_nginx_configuration $1
        finalize_nginx_local_setup $1
    else
        handle_existing_virtual_host $1
    fi
}

main() {
    check_nginx
    create_virtual_host $1
}

main $1
