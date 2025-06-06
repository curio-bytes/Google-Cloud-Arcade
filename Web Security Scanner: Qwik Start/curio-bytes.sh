#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

echo
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}            Solution From Curio Bytes         ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

echo -n "${YELLOW_TEXT}${BOLD_TEXT}-> Enter the region: ${RESET_FORMAT}"
read REGION
export REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Copying files from the Cloud Storage bucket...${RESET_FORMAT}"
gsutil -m cp -r gs://spls/gsp067/python-docs-samples .

cd python-docs-samples/appengine/standard_python3/hello_world

echo 
echo "${MAGENTA_TEXT}${BOLD_TEXT}Updating app.yaml ...${RESET_FORMAT}"
sed -i "s/python37/python39/g" app.yaml

echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Creating a new App Engine application in the specified region...${RESET_FORMAT}"
gcloud app create --region=$REGION

echo "${MAGENTA_TEXT}${BOLD_TEXT}Deploying the application to App Engine...${RESET_FORMAT}"
yes | gcloud app deploy

echo
echo "${RED_TEXT}${BOLD_TEXT}Congratulations for Completing the LAb !!${RESET_FORMAT} ${BLUE_TEXT}${BOLD_TEXT}"
