#!/bin/bash

BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'

BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         STARTING EXECUTION...  ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo


read -p "$(echo -e ${WHITE_TEXT}${BOLD_TEXT}Enter Zone: ${RESET_FORMAT})" ZONE

echo "${YELLOW_TEXT}${BOLD_TEXT}Enabling services...${RESET_FORMAT}"
gcloud services enable notebooks.googleapis.com

gcloud services enable aiplatform.googleapis.com

sleep 15

echo "${CYAN_TEXT}${BOLD_TEXT}Creating Notebook instance...${RESET_FORMAT}"
echo

export NOTEBOOK_NAME="lab-workbench"
export MACHINE_TYPE="e2-standard-2"

gcloud notebooks instances create $NOTEBOOK_NAME \
  --location=$ZONE \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu


echo "${GREEN_TEXT}${BOLD_TEXT}-> Notebook instance created successfully!${RESET_FORMAT}"

PROJECT_ID=$(gcloud config get-value project)
echo "${YELLOW_TEXT}${BOLD_TEXT}>> NOW FOLLOW VIDEO'S INSTRUCTIONS ....${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}Click the following URL and follow video's instructions:${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}https://console.cloud.google.com/vertex-ai/workbench/user-managed?project=$DEVSHELL_PROJECT_ID ${RESET_FORMAT}"

echo -e "${RED_TEXT}${BOLD_TEXT}Congratulations for completing the Lab !!${RESET_FORMAT}
