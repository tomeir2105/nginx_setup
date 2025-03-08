# NGINX SCRIPTS

# **Nginx Virtual Host Automation Script**  

## **Description**  
This script automates the process of setting up a virtual host in Nginx on Ubuntu/Debian systems. It creates the necessary directory structure, generates an Nginx configuration file, enables the site, and updates the local `/etc/hosts` file for easy local development.  

## **Features**  
✅ Automatically checks for Nginx installation and running status  
✅ Creates a virtual host directory and sets proper permissions  
✅ Generates a default `index.html` file for the new site  
✅ Configures and enables the virtual host in Nginx  
✅ Tests Nginx configuration before restarting the service  
✅ Updates `/etc/hosts` for local access  
✅ Cleans up if something goes wrong  

## **Remarks**
- The script allows you to remove existant virtual-host.
- I used the tee command, to echo files and solve permissions problem.
- when the script finishes,it opens up firefox with the new site.
   
## **Requirements**  
- Ubuntu/Debian-based Linux distribution  
- Nginx installed (`sudo apt update && sudo apt install nginx -y`)  
- Sudo privileges to modify system files  

## **Installation**  
Clone the repository and navigate into the project directory:  
```bash  
git clone https://github.com/your-username/nginx-vhost-script.git  
cd nginx-vhost-script  
chmod +x vhost.sh  # Make the script executable  
```

## **Usage**  
Run the script with a domain name as an argument:  
```bash  
./vhost.sh example.com  
```
This will:  
1. Check if Nginx is installed and running  
2. Create a directory `/var/www/example.com/html`  
3. Generate an Nginx virtual host configuration file  
4. Enable the new site and restart Nginx  
5. Add `127.0.0.1 example.com` to `/etc/hosts`  
6. Open the site in Firefox (if available)  

To remove an existing virtual host, run the script with the same domain name and follow the prompts.  

## **Script Details**  

### **1. Initial Setup & Validation**  
- Checks if the user provided a domain name  
- Displays help information if `-h` or `--help` is passed  

### **2. Nginx Installation & Status Check**  
- Verifies if `nginx-common` is installed  
- Checks if Nginx is running  

### **3. Virtual Host Setup**  
- Creates the necessary directory structure  
- Assigns the correct permissions  
- Generates an Nginx configuration file  

### **4. Enabling the Site**  
- Creates a symbolic link in `/etc/nginx/sites-enabled/`  
- Tests the Nginx configuration for errors  
- Restarts Nginx to apply changes  

### **5. Cleanup on Failure**  
- If anything goes wrong, the script removes all created files and directories  

# **Nginx Modules Install Script**
## Overview
This script automates the installation and configuration of various Nginx modules, including authentication, CGI, PAM, and user directory support. It ensures that required packages are installed and properly configured.

## Features
- Installs required modules for Nginx.
- Supports authentication with user credentials.
- Enables CGI functionality.
- Configures PAM authentication.
- Adds user directory support (`~/public_html`).

## Requirements
- A working installation of Nginx.
- A Debian-based system with `apt` package manager.
- Sudo privileges.

## Usage
Run the script with the required parameters:

```bash
./nginx_modules.sh -d <domain> [-u] [-a <nginx_username>] [-c] [-p]
```

### Arguments:
- `-d <domain>` (Required): The domain name for Nginx configuration.
- `-a <nginx_username>`: Enable authentication with the specified username.

### Options:
- `-u`: Enable user directory feature (`~/public_html`).
- `-p`: Enable PAM authentication.
- `-c`: Enable CGI functionality.
- `-h, --help`: Show help message.

### Example:
```bash
./nginx_modules.sh -d example.com -a admin -u -c
```

## Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/nginx-modules-installer.git
   cd nginx-modules-installer
   ```
2. Make the script executable:
   ```bash
   chmod +x nginx_modules.sh
   ```
3. Run the script with appropriate options.

## Functionality
The script performs the following:
1. Checks for Nginx installation.
2. Installs required packages.
3. Configures selected features based on user input.
4. Reloads Nginx to apply changes.

## Troubleshooting
- Ensure you are not running the script as root.
- Verify Nginx is installed by running `nginx -v`.
- Check Nginx configuration with:
  ```bash
  sudo nginx -t
  ```
- View logs for debugging:
  ```bash
  sudo journalctl -xe
  ```

## License
The scripts is free to use for anyone.




