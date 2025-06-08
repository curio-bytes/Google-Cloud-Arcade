#!/bin/bash

# Terminal Colors
BLACK=$(tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
WHITE=$(tput setaf 7)

BG_BLACK=$(tput setab 0)
BG_RED=$(tput setab 1)
BG_GREEN=$(tput setab 2)
BG_YELLOW=$(tput setab 3)
BG_BLUE=$(tput setab 4)
BG_MAGENTA=$(tput setab 5)
BG_CYAN=$(tput setab 6)
BG_WHITE=$(tput setab 7)

BOLD=$(tput bold)
RESET=$(tput sgr0)

echo
echo "${CYAN}${BOLD}==============================================${RESET}"
echo "${CYAN}${BOLD}            Solution From Curio Bytes         ${RESET}"
echo "${CYAN}${BOLD}==============================================${RESET}"
echo

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

# Automatically retrieve project ID and region
PROJECT_ID=$(gcloud config get-value project)
REGION=$(gcloud config get-value compute/region)

if [[ -z "$PROJECT_ID" || -z "$REGION" ]]; then
  echo "${RED}ERROR: Project ID or Region not set in gcloud config.${RESET}"
  exit 1
fi

echo "${GREEN}Using project: ${PROJECT_ID}, region: ${REGION}${RESET}"

# Clone module
git clone https://github.com/terraform-google-modules/terraform-google-network
cd terraform-google-network || exit
git checkout tags/v6.0.1 -b v6.0.1

cd examples/simple_project || exit

# Setup variables.tf
cat > variables.tf <<EOF
variable "project_id" {
  description = "The project ID to host the network in"
  default     = "$PROJECT_ID"
}
variable "network_name" {
  description = "The name of the VPC network being created"
  default     = "example-vpc"
}
EOF

# Setup main.tf
cat > main.tf <<EOF
module "test-vpc-module" {
  source       = "terraform-google-modules/network/google"
  version      = "~> 6.0"
  project_id   = var.project_id
  network_name = var.network_name
  mtu          = 1460

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = "$REGION"
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = "$REGION"
      subnet_private_access = true
      subnet_flow_logs      = true
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = "$REGION"
      subnet_flow_logs          = true
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]
}
EOF

cat > outputs.tf <<EOF
output "network_name" {
  description = "The name of the VPC"
  value       = module.test-vpc-module.network_name
}
EOF

terraform init
terraform apply --auto-approve
terraform destroy --auto-approve

cd ~
rm -rf terraform-google-network

mkdir -p modules/gcs-static-website-bucket
cd modules/gcs-static-website-bucket

# website.tf
cat > website.tf <<EOF
resource "google_storage_bucket" "bucket" {
  name                        = var.name
  project                     = var.project_id
  location                    = var.location
  storage_class               = var.storage_class
  labels                      = var.labels
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "error.html"
  }

  versioning {
    enabled = var.versioning
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy == null ? [] : [var.retention_policy]
    content {
      is_locked        = retention_policy.value.is_locked
      retention_period = retention_policy.value.retention_period
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      default_kms_key_name = encryption.value.default_kms_key_name
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lookup(lifecycle_rule.value.action, "storage_class", null)
      }
      condition {
        age                   = lookup(lifecycle_rule.value.condition, "age", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
      }
    }
  }
}
EOF

# variables.tf
cat > variables.tf <<EOF
variable "name" {
  description = "The name of the bucket."
  type        = string
}
variable "project_id" {
  description = "The ID of the project."
  type        = string
}
variable "location" {
  description = "The location for the bucket."
  type        = string
}
variable "storage_class" {
  type    = string
  default = "STANDARD"
}
variable "labels" {
  type    = map(string)
  default = {}
}
variable "force_destroy" {
  type    = bool
  default = true
}
variable "versioning" {
  type    = bool
  default = true
}
variable "retention_policy" {
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}
variable "encryption" {
  type = object({
    default_kms_key_name = string
  })
  default = null
}
variable "lifecycle_rules" {
  type = list(object({
    action    = any
    condition = any
  }))
  default = []
}
EOF

# outputs.tf
cat > outputs.tf <<EOF
output "bucket" {
  description = "The created bucket resource"
  value       = google_storage_bucket.bucket
}
EOF

cd ~

# Root main.tf
cat > main.tf <<EOF
module "gcs-static-website-bucket" {
  source      = "./modules/gcs-static-website-bucket"
  name        = "$PROJECT_ID"
  project_id  = "$PROJECT_ID"
  location    = "$REGION"
  lifecycle_rules = [{
    action = {
      type = "Delete"
    }
    condition = {
      age        = 365
      with_state = "ANY"
    }
  }]
}
EOF

cat > variables.tf <<EOF
variable "project_id" {
  type    = string
  default = "$PROJECT_ID"
}
variable "name" {
  type    = string
  default = "$PROJECT_ID"
}
EOF

cat > outputs.tf <<EOF
output "bucket_name" {
  description = "Static website bucket"
  value       = module.gcs-static-website-bucket.bucket.name
}
EOF

terraform init
terraform apply --auto-approve

# HTML content
cat > index.html <<EOF
<!DOCTYPE html>
<html lang="en" dir="ltr">
  <head>
    <meta charset="utf-8">
    <title>Static Website</title>
  </head>
  <body>
    <p>Nothing to see here.</p>
  </body>
</html>
EOF

cat > error.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>404: Not Found</title>
  </head>
  <body>
    <h1>404: Not Found</h1>
    <p>The page you're looking for doesn't exist.</p>
  </body>
</html>
EOF

gsutil cp index.html error.html gs://$PROJECT_ID

echo "${BG_GREEN}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
