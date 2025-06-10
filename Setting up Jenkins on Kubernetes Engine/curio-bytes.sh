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

echo "${BG_RED}${BOLD}==========================================${RESET}"
echo "${BG_RED}${BOLD}         Solution from Curio Bytes        ${RESET}"
echo "${BG_RED}${BOLD}==========================================${RESET}"

echo
echo "${BG_MAGENTA}${BOLD}... Starting Execution ...${RESET}"

gcloud config set compute/zone $ZONE

git clone https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes.git

cd continuous-deployment-on-kubernetes

gcloud container clusters create jenkins-cd \
--num-nodes 2 \
--scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform"

gcloud container clusters get-credentials jenkins-cd

helm repo add jenkins https://charts.jenkins.io

helm repo update

helm upgrade --install -f jenkins/values.yaml myjenkins jenkins/jenkins

echo "${BG_RED}${BOLD}----------- Congratulations For Completing The Lab !!! --------------${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
