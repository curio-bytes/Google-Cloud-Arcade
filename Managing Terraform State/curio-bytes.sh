#!/bin/bash

# Exit on any error
set -e

# Step 1: Setup
PROJECT_ID=$(gcloud config list --format 'value(core.project)')
REGION="us-central1"  # Adjust as needed
BUCKET_NAME="${PROJECT_ID}-tf-state-bucket"
TF_DIR="terraform"
TF_STATE_PATH="$TF_DIR/state"

# Step 2: Create directories and main.tf
mkdir -p "$TF_STATE_PATH"
cd "$TF_DIR"

# Step 3: Write initial Terraform config with local backend
cat > main.tf <<EOF
provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
}

resource "google_storage_bucket" "test-bucket-for-state" {
  name                        = "${BUCKET_NAME}"
  location                    = "US"
  uniform_bucket_level_access = true
}

terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}
EOF

# Step 4: Initialize and apply with local backend
terraform init
terraform apply -auto-approve

# Step 5: Replace local backend with GCS backend
cat > backend.tf <<EOF
terraform {
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "terraform/state"
  }
}
EOF

# Step 6: Reinitialize with state migration
terraform init -migrate-state -reconfigure

# Step 7: Wait and notify to add label manually in GCP UI
echo "⏳ Please open the Cloud Console -> Storage -> Buckets -> ${BUCKET_NAME}"
echo "➕ Add label: key = key, value = value to the bucket."
read -p "⚠️ Press ENTER once the label is added to continue with refresh..."

# Step 8: Refresh state and show result
terraform refresh
terraform show
