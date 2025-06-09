#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=`tput setab 2`
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`


echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}         Solution from Curio Bytes     ${RESET_FORMAT}"
echo "${GREEN_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

# Display initiation message
echo "${BACKGROUND_RED}${BOLD_TEXT}... Initiating Execution...${RESET_FORMAT}"

# Prompt the user for the region in yellow bold color
echo -e "${YELLOW_COLOR}${BOLD_TEXT}-> Enter the region: ${NO_COLOR}${RESET_FORMAT}"
read REGION

# Authenticate with gcloud
gcloud auth list

# Enable the App Engine API
gcloud services enable appengine.googleapis.com

# Clone the repository
git clone https://github.com/GoogleCloudPlatform/php-docs-samples.git

# Navigate to the helloworld directory
cd php-docs-samples/appengine/standard/helloworld

# Wait for 30 seconds
sleep 30

# Create the App Engine app
gcloud app create --region=$REGION

# Deploy the app
gcloud app deploy --quiet

# Completion message
echo
echo -e "${RED_TEXT}${BOLD_TEXT}Congratulations for Completing the Lab!!!${RESET_FORMAT}"
