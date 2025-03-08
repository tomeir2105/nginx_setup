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

## **Script Breakdown**  

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

## **Contributing**  
Feel free to fork this repository and submit pull requests with improvements!  

## **License**  
This script is licensed under the MIT License.  


