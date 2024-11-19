#!/bin/bash

# Set timezone
sudo timedatectl set-timezone 'Asia/Singapore'

echo "Updating package lists"
sudo apt-get update

# Install packages and handle prompts
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl nginx

# Update gcloud components without prompts
sudo gcloud components update --quiet

echo "Installing additional packages"

# Import the Google Cloud public key
sudo rm -rf /usr/share/keyrings/cloud.google.gpg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

# Update and install Google Cloud SDK and Kubernetes CLI without prompting
sudo apt-get update
sudo apt-get install -y google-cloud-cli kubectl google-cloud-sdk-gke-gcloud-auth-plugin

# Disable gcloud usage reporting prompt by setting the configuration
sudo gcloud config set disable_usage_reporting true --quiet



