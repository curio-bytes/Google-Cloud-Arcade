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
echo "${YELLOW_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}     Solution from Curio Bytes      ${RESET_FORMAT}"
echo "${YELLOW_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

read -e -p "${GREEN_TEXT}${BOLD_TEXT}-. Enter the second zone (ZONE_2): ${RESET_FORMAT}" ZONE_2
export ZONE_2="$ZONE_2"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Detecting your default compute zone (ZONE_1)...${RESET_FORMAT}"
echo

export ZONE_1=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION_1=$(echo "$ZONE_1" | cut -d '-' -f 1-2)
export REGION_2=$(echo "$ZONE_2" | cut -d '-' -f 1-2)

echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Creating VM instances in the selected zones...${RESET_FORMAT}"
echo "${DIM_TEXT}This may take a few moments. Please wait...${RESET_FORMAT}"
echo

gcloud compute instances create www-1 \
  --image-family debian-11 \
  --image-project debian-cloud \
  --zone $ZONE_1 \
  --tags http-tag \
  --metadata startup-script="#! /bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    Code
    EOF"

gcloud compute instances create www-2 \
  --image-family debian-11 \
  --image-project debian-cloud \
  --zone $ZONE_1 \
  --tags http-tag \
  --metadata startup-script="#! /bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    Code
    EOF"

gcloud compute instances create www-3 \
  --image-family debian-11 \
  --image-project debian-cloud \
  --zone $ZONE_2 \
  --tags http-tag \
  --metadata startup-script="#! /bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    Code
    EOF"

gcloud compute instances create www-4 \
  --image-family debian-11 \
  --image-project debian-cloud \
  --zone $ZONE_2 \
  --tags http-tag \
  --metadata startup-script="#! /bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    Code
    EOF"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Setting up firewall rules to allow HTTP traffic...${RESET_FORMAT}"
echo

gcloud compute firewall-rules create www-firewall \
  --target-tags http-tag --allow tcp:80

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Listing all VM instances...${RESET_FORMAT}"
echo

gcloud compute instances list

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}-> Reserving a global static IP address for the load balancer...${RESET_FORMAT}"
echo

gcloud compute addresses create lb-ip-cr \
  --ip-version=IPV4 \
  --global

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Creating unmanaged instance groups in both regions...${RESET_FORMAT}"
echo

gcloud compute instance-groups unmanaged create $REGION_1-resources-w --zone $ZONE_1

gcloud compute instance-groups unmanaged create $REGION_2-resources-w --zone $ZONE_2

echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Adding VM instances to their respective instance groups...${RESET_FORMAT}"
echo

gcloud compute instance-groups unmanaged add-instances $REGION_1-resources-w \
  --instances www-1,www-2 \
  --zone $ZONE_1

gcloud compute instance-groups unmanaged add-instances $REGION_2-resources-w \
  --instances www-3,www-4 \
  --zone $ZONE_2

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Creating a health check for backend instances...${RESET_FORMAT}"
echo

gcloud compute health-checks create http http-basic-check

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Assigning named ports to instance groups...${RESET_FORMAT}"
echo

gcloud compute instance-groups unmanaged set-named-ports $REGION_1-resources-w \
  --named-ports http:80 \
  --zone $ZONE_1

gcloud compute instance-groups unmanaged set-named-ports $REGION_2-resources-w \
  --named-ports http:80 \
  --zone $ZONE_2

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}-> Creating backend service and adding instance groups...${RESET_FORMAT}"
echo

gcloud compute backend-services create web-map-backend-service \
  --protocol HTTP \
  --health-checks http-basic-check \
  --global

gcloud compute backend-services add-backend web-map-backend-service \
  --balancing-mode UTILIZATION \
  --max-utilization 0.8 \
  --capacity-scaler 1 \
  --instance-group $REGION_1-resources-w \
  --instance-group-zone $ZONE_1 \
  --global

gcloud compute backend-services add-backend web-map-backend-service \
  --balancing-mode UTILIZATION \
  --max-utilization 0.8 \
  --capacity-scaler 1 \
  --instance-group $REGION_2-resources-w \
  --instance-group-zone $ZONE_2 \
  --global

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Creating URL map and HTTP proxy for the load balancer...${RESET_FORMAT}"
echo

gcloud compute url-maps create web-map \
  --default-service web-map-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
  --url-map web-map

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Fetching the reserved IP address for the forwarding rule...${RESET_FORMAT}"
echo

LB_IP_ADDRESS=$(gcloud compute addresses list --format="get(ADDRESS)")

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Creating the global forwarding rule for HTTP traffic...${RESET_FORMAT}"
echo

  gcloud compute forwarding-rules create http-cr-rule \
  --address $LB_IP_ADDRESS \
  --global \
  --target-http-proxy http-lb-proxy \
  --ports 80

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}---------- Congratulations for Completing the lab !! -------------${RESET_FORMAT}"
echo
