#!/bin/bash

# Exit on error
set -e

# 1. Get the current GCP Project ID
PROJECT_ID=$(gcloud config list --format 'value(core.project)')

# 2. Create required directories and files
mkdir -p terraform/state
touch main.tf

# 3. Write the provider and bucket resource block to main.tf
cat <<EOF > main.tf
provider "google" {
  project = "$PROJECT_ID"
  region  = "$REGION"
}

resource "google_storage_bucket" "test-bucket-for-state" {
  name                        = "${PROJECT_ID}-tfstate-bucket"
  location                    = "US"
  uniform_bucket_level_access = true
}

terraform {
  backend "local" {
    path = "terraform/state/terraform.tfstate"
  }
}
EOF

# 4. Initialize Terraform (Local backend)
echo "Initializing Terraform with local backend..."
terraform init

# 5. Apply configuration (create bucket)
echo "Applying configuration to create GCS bucket..."
terraform apply -auto-approve

# 6. Replace backend with GCS in main.tf
cat <<EOF > backend_override.tf
terraform {
  backend "gcs" {
    bucket = "${PROJECT_ID}-tfstate-bucket"
    prefix = "terraform/state"
  }
}
EOF

# 7. Migrate state to GCS
echo "Migrating state to GCS backend..."
terraform init -migrate-state

# 8. Simulate manual change via GCP Console (adding label)
echo "Adding label manually to bucket for refresh test..."
gcloud storage buckets update "${PROJECT_ID}-tfstate-bucket" --update-labels=key=value

# 9. Refresh state
echo "Refreshing state to detect drift..."
terraform refresh

# 10. Show final state
echo "Final Terraform state:"
terraform show
