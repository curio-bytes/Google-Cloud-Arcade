#!/bin/bash

# Exit on error
set -e

# Define ANSI color codes
CYAN_TEXT="\033[0;36m"
YELLOW="\033[1;33m"
BOLD_TEXT="\033[1m"
RESET_FORMAT="\033[0m"
NC="\033[0m"

# Intro banner
echo
echo -e "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}            Solution From Curio Bytes         ${RESET_FORMAT}"
echo -e "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

# Prompt for regions
read -p "Enter region for group1 (e.g., us-west1): " GROUP1_REGION
read -p "Enter region for group2 (e.g., us-central1): " GROUP2_REGION
read -p "Enter region for group3 (e.g., us-east1): " GROUP3_REGION

# Get current project ID
PROJECT_ID=$(gcloud config get-value project)

# Clone repo
git clone https://github.com/terraform-google-modules/terraform-google-lb-http.git
cd terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb

# Modify main.tf to enable SSL
sed -i '/gce-lb-https {/a \ \ create_ssl_certificate = true\n \ \ managed_ssl_certificate_domains = ["example.com"]' main.tf

# Update region values in variables.tf
sed -i "s|group1_region.*|group1_region = \"$GROUP1_REGION\"|" variables.tf
sed -i "s|group2_region.*|group2_region = \"$GROUP2_REGION\"|" variables.tf
sed -i "s|group3_region.*|group3_region = \"$GROUP3_REGION\"|" variables.tf

# Terraform operations
terraform init
terraform plan -out=tfplan -var "project=$PROJECT_ID"
terraform apply -auto-approve tfplan

# Get external IP and show URLs
EXTERNAL_IP=$(terraform output -raw load-balancer-ip)

echo
echo "✅ Load Balancer IP: $EXTERNAL_IP"
echo "🌐 Group1 URL: https://${EXTERNAL_IP}/group1"
echo "🌐 Group2 URL: https://${EXTERNAL_IP}/group2"
echo "🌐 Group3 URL: https://${EXTERNAL_IP}/group3"

# Final congratulatory message
echo
echo -e "${YELLOW}---- Congratulations for Completing the Lab!!!${NC}"
