#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
DIM_TEXT=$'\033[2m'
STRIKETHROUGH_TEXT=$'\033[9m'
BOLD_TEXT=$'\033[1m'
RESET_FORMAT=$'\033[0m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀     STARTING EXECUTION     🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 1: Zone Configuration Setup${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Fetching your default compute zone from project metadata...${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

if [ -z "$ZONE" ]; then
  echo "${YELLOW_TEXT}${BOLD_TEXT}⚠️  No default zone detected in your project configuration!${RESET_FORMAT}"
  echo "${CYAN_TEXT}${BOLD_TEXT}Please enter zone for your Dataproc cluster:${RESET_FORMAT}"
  read -p "${CYAN_TEXT}${BOLD_TEXT}Zone: ${RESET_FORMAT}" ZONE
  export ZONE
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Zone configured: ${ZONE}${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 2: Region Configuration Setup${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Determining your project's default region...${RESET_FORMAT}"
echo

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

if [ -z "$REGION" ]; then
  export REGION=$(echo $ZONE | sed 's/-[a-z]$//')
  echo "${GREEN_TEXT}${BOLD_TEXT}Region fetched from zone: $REGION${RESET_FORMAT}"
fi

echo "${GREEN_TEXT}${BOLD_TEXT}Region configured: ${REGION}${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 3: Enabling Dataproc API${RESET_FORMAT}"
echo "${WHITE_TEXT}${BOLD_TEXT}Activating Google Cloud Dataproc service for your project...${RESET_FORMAT}"
echo

gcloud services enable dataproc.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Dataproc API successfully enabled!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 4: Creating Dataproc Cluster${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}This process may take several minutes to complete... Please wait...${RESET_FORMAT}"
echo

gcloud dataproc clusters create my-cluster \
    --region=$REGION \
    --zone=$ZONE \
    --image-version=2.0-debian10 \
    --optional-components=JUPYTER \
    --project=$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Cluster 'my-cluster' created successfully!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 5: Submitting Spark Job${RESET_FORMAT}"
echo

gcloud dataproc jobs submit spark \
    --cluster=my-cluster \
    --region=$REGION \
    --jars=file:///usr/lib/spark/examples/jars/spark-examples.jar \
    --class=org.apache.spark.examples.SparkPi \
    --project=$DEVSHELL_PROJECT_ID \
    -- \
    1000

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Spark job completed successfully!${RESET_FORMAT}"
echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 6: Scaling Cluster Workers${RESET_FORMAT}"
echo

gcloud dataproc clusters update my-cluster \
    --region=$REGION \
    --num-workers=3 \
    --project=$DEVSHELL_PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Cluster successfully scaled to 3 workers!${RESET_FORMAT}"
echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}CONGRATULATIONS FOR COMPLETING THE LAB !${RESET_FORMAT}"
echo
