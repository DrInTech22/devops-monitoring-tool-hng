#!/bin/bash

# Check if the script is run as root
if [[ $UID != 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

# Perform a single update
echo "Updating package lists..."
apt-get update

# Function to install Docker
install_docker() {
  if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    usermod -aG docker $USER
    echo "Docker installation completed."
  else
    echo "Docker is already installed."
  fi
}

# Function to install Nginx
install_nginx() {
  if ! command -v nginx &> /dev/null; then
    echo "Nginx is not installed. Installing Nginx..."
    apt-get install -y nginx
    echo "Nginx installation completed."
  else
    echo "Nginx is already installed."
  fi
}

# Function to install net-tools
install_net_tools() {
  if ! command -v netstat &> /dev/null; then
    echo "Net-tools is not installed. Installing net-tools..."
    apt-get install -y net-tools
    echo "Net-tools installation completed."
  else
    echo "Net-tools is already installed."
  fi
}

# Function to jq
install_jq() {
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing jq..."
    apt-get install -y jq
    echo "jq installation completed."
  else
    echo "jq is already installed."
  fi
}

# Install necessary dependencies
install_docker
install_nginx
install_net_tools
install_jq


