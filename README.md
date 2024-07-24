# Devopsfetch Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation-and-configuration)
4. [Usage](#usage)
5. [Monitoring](#monitoring)
6. [Log Management](#log-management)

## Introduction
Devopsfetch is a cli-based tool designed for DevOps professionals to collect and display system information, including active ports, user logins, Nginx configurations, Docker images, container statuses and system logs. It is written in bash and it includes a systemd service to monitor and log these activities continuously.

## Prerequisites
- Ubuntu machine


## Installation 

1. Clone the Repository
   ```bash
   git clone https://github.com/yourusername/devopsfetch-hng.git
   cd devopsfetch
   ```
2. Make the installation script executable
   ```bash
   chmod +x install.sh
   ``` 
3.  Install Necessary Dependencies

      ```bash
      sudo ./install.sh
      ```

      The script updates the system and checks if the following dependencies are installed. If not, it installs them.
      ```bash
      docker 
      nginx
      netstat
      jq 
      ```

## Usage
The main script devopsfetch.sh provides various options to retrieve and display system information.

1. Make the script executable
   ```bash
   chmod +x devopsfetch.sh
   ```
2. Run the script with elevated privileges
   ```bash
   sudo ./devopsfetch.sh <option> <argument>
   ```
3. Detailed info about options
   ```bash
      Options:
   -p, --port [PORT_NUMBER]         -p                Display all active ports and services.                       
                                    -p <port_number>  Provide detailed information about a specific port.

   -d, --docker [CONTAINER_NAME]    -d                List all Docker images and containers.                                 
                                    -d <container_name> Provide detailed information about a specific container.

   -n, --nginx [DOMAIN]             -n                Display all Nginx domains and their ports.
                                    -n <domain>       Provide detailed configuration information for a specific domain.

   -u, --users [USERNAME]           -u                List all users and their last login times.                    
                                    -u <username>     Provide detailed information about a specific user.

   -t, --time [TIME_RANGE]          -t <date>         Display activities for a specific date (e.g., 2024-07-23).
                                    -t <start_date> <end_date> Display activities within the specified date range 
                                                            (e.g., 2024-07-18 2024-07-24).

   -h, --help                                           Display this help message and exit.
  
4. Detailed example
   ```bash
   sudo ./devopsfetch.sh -p                 Display all active ports and services.
   sudo ./devopsfetch.sh -p 80              Display detailed information about port 80.
   sudo ./devopsfetch.sh -d                 List all Docker images and containers.
   sudo ./devopsfetch.sh -d my_container    Provide detailed information about 'my_container'.
   ```
   ![Screenshot (340)](https://github.com/user-attachments/assets/3d362e8e-a697-4e28-b783-769c598512b2)

## Monitoring
Devopsfetch implements a systemd service that runs continuously to monitor and log activities of certain services. To activate continuous monitoring, follow these steps:
1. Make the monitoring script executable
   ```bash
   chmod +x fetch_monitor.sh
   ```
2. Modify `fetch_monitor.service` to point to your executable script
   ```service
   [Unit]
   Description=Monitoring Script
   After=network.target

   [Service]
   ExecStart=/absolute/path/to/fetch_monitor.sh # include the right absolute path to the script
   Restart=always
   User=root

   [Install]
   WantedBy=multi-user.target
   ```
3. Copy to `fetch_monitor.service` to the systemd directory
   ```bash
   sudo cp fetch_monitor.service /etc/systemd/system/fetch_monitor.service
   ```
4. Reload the systemd daemon
   ```bash
   sudo systemctl daemon-reload
   ```
5. Start the service
   ```bash
   sudo systemctl start fetch_monitor
   ```
6. Enable the service to start on boot
   ```
   sudo systemctl enable fetch_monitor
   ```
`fetch_monitor.sh` continuously logs the status of Users, docker images, containers and active ports. The `fetch_monitor.service` ensure the script is always running and automatically restarts it, if it fails for any reason (failure, or unexpected termination).

## Log Management
The monitoring script is responsible for logging activities to the log file `/var/log/fetch_monitor.log`. The script runs service check every one hour and logs the result. 

![Screenshot (344)](https://github.com/user-attachments/assets/e92819d0-c879-45d4-a252-40b0f02e0fc3)
![Screenshot (343)](https://github.com/user-attachments/assets/b3ac160a-a162-4c66-82bf-8d2b77e970d3)

Here, we'll effectively manage the log files by leveraging log rotation.

1. Stream or view the log file
   ```bash
   sudo tail -f /var/log/fetch_monitor.log
   ```
2. Create a new config file for log rotation
   ```bash
   sudo vim /etc/logrotate.d/fetch_monitor
   ```
3. Update the configuration
   ```
   /var/log/fetch_monitor.log {
      daily
      rotate 7
      compress
      delaycompress
      missingok
      notifempty
      create 0640 root adm
   }
   ```
The configuration above creates daily compressed backups, keeping a maximum of 7 rotated files, and erases older ones. This approach cleans up old logs and preserves recent ones for troubleshooting.

After a successful set up and configuration, you can now use the devopsfetch tool to monitor services status and collect more information on them. Use the main script to access verbose info and the monitoring service to access instant checks. 
