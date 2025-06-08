#!/bin/bash

# Set colors
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

#----------------------------------------------------start--------------------------------------------------#

echo
echo "${CYAN}${BOLD}==============================================${RESET}"
echo "${CYAN}${BOLD}            Solution From Curio Bytes         ${RESET}"
echo "${CYAN}${BOLD}==============================================${RESET}"
echo

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

# Clone repo
git clone https://github.com/terraform-google-modules/terraform-google-network
cd terraform-google-network
git checkout tags/v6.0.1 -b v6.0.1

cd ~/terraform-google-network/examples/simple_project

# Define variables.tf
cat > variables.tf <<EOF_END
variable "project_id" {
  description = "The project ID to host the network in"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network being created"
  type        = string
  default     = "example-vpc"
}

variable "region" {
  description = "Region for the subnets"
  type        = string
  default     = "us-central1"
}
EOF_END

# Define main.tf
cat > main.tf <<EOF_END
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
      subnet_region = var.region
    },
    {
      subnet_name           = "subnet-02"
      subnet_ip             = "10.10.20.0/24"
      subnet_region         = var.region
      subnet_private_access = true
      subnet_flow_logs      = true
    },
    {
      subnet_name               = "subnet-03"
      subnet_ip                 = "10.10.30.0/24"
      subnet_region             = var.region
      subnet_flow_logs          = true
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.7
      subnet_flow_logs_metadata = "INCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]
}
EOF_END

# Define outputs.tf
cat > outputs.tf <<EOF_END
output "network_name" {
  description = "The name of the VPC network"
  value       = var.network_name
}
EOF_END

terraform init
terraform apply --auto-approve
terraform destroy --auto-approve

cd ~
rm -rf terraform-google-network

# Set up GCS website module
mkdir -p modules/gcs-static-website-bucket
cd modules/gcs-static-website-bucket

touch website.tf variables.tf outputs.tf

# README
cat > README.md <<EOF
# GCS static website bucket
This module provisions Cloud Storage buckets configured for static website hosting.
EOF

# LICENSE
cat > LICENSE <<EOF
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF

# website.tf
cat > website.tf <<EOF_END
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
      is_locked        = var.retention_policy.is_locked
      retention_period = var.retention_policy.retention_period
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      default_kms_key_name = var.encryption.default_kms_key_name
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
        created_before        = lookup(lifecycle_rule.value.condition, "created_before", null)
        with_state            = lookup(lifecycle_rule.value.condition, "with_state", null)
        matches_storage_class = lookup(lifecycle_rule.value.condition, "matches_storage_class", null)
        num_newer_versions    = lookup(lifecycle_rule.value.condition, "num_newer_versions", null)
      }
    }
  }
}
EOF_END

# variables.tf
cat > variables.tf <<EOF_END
variable "name" {
  description = "The name of the bucket."
  type        = string
}
variable "project_id" {
  description = "The ID of the project to create the bucket in."
  type        = string
}
variable "location" {
  description = "The location of the bucket."
  type        = string
}
variable "storage_class" {
  description = "The Storage Class of the new bucket."
  type        = string
  default     = null
}
variable "labels" {
  description = "A set of key/value label pairs to assign to the bucket."
  type        = map(string)
  default     = null
}
variable "bucket_policy_only" {
  description = "Enables Bucket Policy Only access to a bucket."
  type        = bool
  default     = true
}
variable "versioning" {
  description = "While set to true, versioning is fully enabled for this bucket."
  type        = bool
  default     = true
}
variable "force_destroy" {
  description = "Delete bucket contents when deleting bucket."
  type        = bool
  default     = true
}
variable "iam_members" {
  description = "The list of IAM members to grant permissions on the bucket."
  type = list(object({
    role   = string
    member = string
  }))
  default = []
}
variable "retention_policy" {
  description = "Bucket's data retention policy."
  type = object({
    is_locked        = bool
    retention_period = number
  })
  default = null
}
variable "encryption" {
  description = "KMS key for object encryption."
  type = object({
    default_kms_key_name = string
  })
  default = null
}
variable "lifecycle_rules" {
  description = "Bucket Lifecycle Rules."
  type = list(object({
    action    = any
    condition = any
  }))
  default = []
}
EOF_END

# outputs.tf
cat > outputs.tf <<EOF_END
output "bucket" {
  description = "The created storage bucket"
  value       = google_storage_bucket.bucket
}
EOF_END

cd ~

# Top-level main.tf for using the module
cat > main.tf <<EOF_END
module "gcs-static-website-bucket" {
  source     = "./modules/gcs-static-website-bucket"
  name       = var.name
  project_id = var.project_id
  location   = var.region

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
EOF_END

# outputs.tf
cat > outputs.tf <<EOF_END
output "bucket" {
  description = "The created bucket resource"
  value       = module.gcs-static-website-bucket.bucket
}
EOF_END

# variables.tf
cat > variables.tf <<EOF_END
variable "project_id" {
  description = "The project to deploy resources in"
  type        = string
  default     = "$(gcloud config get-value project)"
}
variable "name" {
  description = "Name of the bucket"
  type        = string
  default     = "$(gcloud config get-value project)"
}
variable "region" {
  description = "Bucket region"
  type        = string
  default     = "us-central1"
}
EOF_END

terraform init
terraform apply --auto-approve

# Download HTML files and upload to bucket
curl -s https://raw.githubusercontent.com/curio-bytes/Google-Cloud-Arcade/main/Interact%20with%20Terraform%20Modules/index.html -o index.html
curl -s https://raw.githubusercontent.com/curio-bytes/Google-Cloud-Arcade/main/Interact%20with%20Terraform%20Modules/error.html -o error.html

gsutil cp *.html gs://$(gcloud config get-value project)

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"
