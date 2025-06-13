#!/bin/bash


echo "===================================================="
echo "           Solution from Curio Bytes                "
echo "===================================================="
echo

# Prompt user for region and zone
read -p ">> Enter the region (e.g. us-central1): " REGION
read -p ">> Enter the zone (e.g. us-central1-a): " ZONE

VM_NAME="my-vm-1"
REGION="europe-west1"
ZONE="europe-west1-b"
MACHINE_TYPE="e2-standard-2"
IMAGE_PROJECT="ubuntu-os-cloud"
IMAGE_NAME="ubuntu-2404-minimal-v20240606"  # As of June 2024; adjust if newer needed

# Optional: Set gcloud config defaults
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

# Create the VM instance with Ubuntu 24.04 LTS Minimal
gcloud compute instances create $VM_NAME \
  --zone=$ZONE \
  --machine-type=$MACHINE_TYPE \
  --image=$IMAGE_NAME \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-balanced \
  --boot-disk-device-name=$VM_NAME

echo "✅ VM $VM_NAME creation initiated in region $REGION, zone $ZONE using image $IMAGE_NAME."
