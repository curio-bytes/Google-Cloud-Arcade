#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo
echo "${YELLOW}${BOLD}===================================${RESET_FORMAT}"
echo "${YELLOW}${BOLD}     Solution from Curio Bytes     ${RESET_FORMAT}"
echo "${YELLOW}${BOLD}===================================${RESET_FORMAT}"
echo

echo "${BG_MAGENTA}${BOLD}... Starting Execution ...${RESET}"
echo

gcloud config set compute/region $REGION

echo

gcloud services enable appengine.googleapis.com

echo

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

echo

cd python-docs-samples/appengine/standard_python3/hello_world

echo

sed -i 's/Hello World!/Hello, Cruel World!/g' main.py

echo

gcloud app create --region=$REGION

echo

yes | gcloud app deploy

echo
echo "${CYAN}${BOLD}---------- Congratulations For Completing The Lab !!! ------------${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
