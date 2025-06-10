#!/bin/bash

CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

# Exit on error
set -e

# Echo each command
set -x

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}            Solution From Curio Bytes         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

# Prompt user for dynamic region input
read -p ">> Enter region for group1 (e.g., us-west1): " GROUP1_REGION
read -p ">> Enter region for group2 (e.g., us-central1): " GROUP2_REGION
read -p ">> Enter region for group3 (e.g., us-east1): " GROUP3_REGION

# Get the current project ID from gcloud
PROJECT_ID=$(gcloud config get-value project)

# Clone the Terraform module repo
git clone https://github.com/terraform-google-modules/terraform-google-lb-http.git
cd terraform-google-lb-http/examples/multi-backend-multi-mig-bucket-https-lb

# Modify main.tf to enable SSL certificate creation
sed -i '/gce-lb-https {/a \ \ create_ssl_certificate = true\n \ \ managed_ssl_certificate_domains = ["example.com"]' main.tf

# Update variables.tf with user-provided regions
sed -i "s|group1_region.*|group1_region = \"$GROUP1_REGION\"|" variables.tf
sed -i "s|group2_region.*|group2_region = \"$GROUP2_REGION\"|" variables.tf
sed -i "s|group3_region.*|group3_region = \"$GROUP3_REGION\"|" variables.tf

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan -var "project=$PROJECT_ID"

# Apply the Terraform plan
terraform apply -auto-approve tfplan

# Retrieve the external IP of the load balancer
EXTERNAL_IP=$(terraform output -raw load-balancer-ip)

# Output the generated URLs
echo
echo "✅ Base Load Balancer URL: https://${EXTERNAL_IP}"
echo "🌐 Group1 URL (Region: $GROUP1_REGION): https://${EXTERNAL_IP}/group1"
echo "🌐 Group2 URL (Region: $GROUP2_REGION): https://${EXTERNAL_IP}/group2"
echo "🌐 Group3 URL (Region: $GROUP3_REGION): https://${EXTERNAL_IP}/group3"

# Optional: open the base URL in a browser (only works in Cloud Shell browser)
if command -v xdg-open &> /dev/null; then
  xdg-open "https://${EXTERNAL_IP}"
fi
