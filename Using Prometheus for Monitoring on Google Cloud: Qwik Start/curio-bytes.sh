#!/bin/bash
clear

# Define text and background colors
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

TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

echo
echo "${CYAN}${BOLD}===================================${RESET}"
echo "${CYAN}${BOLD}    Solution from Curio Bytes      ${RESET}"
echo "${CYAN}${BOLD}===================================${RESET}"
echo

# Step 1: Set Compute Zone & Region
echo "${BOLD}${BLUE}-> 1. Setting Compute Zone & Region${RESET}"
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Create Docker Artifact Registry
echo "${BOLD}${GREEN}-> 2. Creating Docker Artifact Registry${RESET}"
gcloud artifacts repositories create docker-repo --repository-format=docker \
  --location="$REGION" --description="Docker repository" \
  --project="$DEVSHELL_PROJECT_ID" || echo "Repository may already exist, continuing..."

# Step 3: Download Flask Telemetry App
echo "${BOLD}${CYAN}-> 3. Downloading Flask Telemetry App${RESET}"
wget -q https://storage.googleapis.com/spls/gsp1024/flask_telemetry.zip
unzip -o flask_telemetry.zip || { echo "Failed to unzip flask_telemetry.zip"; exit 1; }

# Step 4: Load Docker Image
echo "${BOLD}${YELLOW}-> 4. Loading Docker Image${RESET}"
docker load -i flask_telemetry.tar || { echo "Docker load failed"; exit 1; }

# Step 5: Tag Docker Image
echo "${BOLD}${MAGENTA}-> 5. Tagging Docker Image${RESET}"
docker tag gcr.io/ops-demo-330920/flask_telemetry:61a2a7aabc7077ef474eb24f4b69faeab47deed9 \
  "$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1"

# Step 6: Push Docker Image to Artifact Registry
echo "${BOLD}${RED}-> 6. Pushing Docker Image to Artifact Registry${RESET}"
docker push "$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1"

# Step 7: Create GKE Cluster with Prometheus Monitoring
echo "${BOLD}${GREEN}-> 7. Creating GKE Cluster with Prometheus Monitoring${RESET}"
gcloud beta container clusters create gmp-cluster --num-nodes=1 --zone "$ZONE" --enable-managed-prometheus

# Step 8: Get GKE Credentials
echo "${BOLD}${CYAN}-> 8. Getting GKE Credentials${RESET}"
gcloud container clusters get-credentials gmp-cluster --zone "$ZONE"

# Step 9: Create Namespace
echo "${BOLD}${YELLOW}-> 9. Creating Kubernetes Namespace${RESET}"
kubectl create ns gmp-test

# Step 10: Download Prometheus Setup Files
echo "${BOLD}${MAGENTA}-> 10. Downloading Prometheus Setup Files${RESET}"
wget -q https://storage.googleapis.com/spls/gsp1024/gmp_prom_setup.zip
unzip -o gmp_prom_setup.zip || { echo "Failed to unzip gmp_prom_setup.zip"; exit 1; }
cd gmp_prom_setup || { echo "Failed to enter gmp_prom_setup directory"; exit 1; }

# Step 11: Replace Placeholder in Deployment YAML
echo "${BOLD}${BLUE}-> 11. Replacing Placeholder in Deployment YAML${RESET}"
sed -i "s|<ARTIFACT REGISTRY IMAGE NAME>|$REGION-docker.pkg.dev/$DEVSHELL_PROJECT_ID/docker-repo/flask-telemetry:v1|g" flask_deployment.yaml

# Step 12: Apply Flask Deployment
echo "${BOLD}${GREEN}-> 12. Applying Flask Deployment${RESET}"
kubectl -n gmp-test apply -f flask_deployment.yaml

# Step 13: Apply Flask Service
echo "${BOLD}${CYAN}-> 13. Applying Flask Service${RESET}"
kubectl -n gmp-test apply -f flask_service.yaml

# Step 14: Retrieve LoadBalancer IP
echo "${BOLD}${YELLOW}-> 14. Retrieving LoadBalancer IP${RESET}"
url=$(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}')
echo "App URL: http://$url"

# Step 15: Curl Metrics Endpoint
echo "${BOLD}${MAGENTA}-> 15. Curling /metrics Endpoint${RESET}"
curl "$url/metrics"

# Step 16: Deploy Prometheus Configuration
echo "${BOLD}${RED}-> 16. Deploying Prometheus Configuration${RESET}"
kubectl -n gmp-test apply -f prom_deploy.yaml

# Step 17: Generate Random Traffic for 2 Minutes
echo "${BOLD}${BLUE}-> 17. Generating Random Traffic for 2 Minutes${RESET}"
timeout 120 bash -c "while true; do curl \$(kubectl get services -n gmp-test -o jsonpath='{.items[*].status.loadBalancer.ingress[0].ip}'); sleep \$((RANDOM % 4)); done"

# Step 18: Create Monitoring Dashboard
echo "${BOLD}${GREEN}-> 18. Creating Monitoring Dashboard${RESET}"
gcloud monitoring dashboards create --config='''{
  "category": "CUSTOM",
  "displayName": "Prometheus Dashboard Example",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "height": 4,
        "widget": {
          "title": "prometheus/flask_http_request_total/counter [MEAN]",
          "xyChart": {
            "chartOptions": {
              "mode": "COLOR"
            },
            "dataSets": [
              {
                "minAlignmentPeriod": "60s",
                "plotType": "LINE",
                "targetAxis": "Y1",
                "timeSeriesQuery": {
                  "apiSource": "DEFAULT_CLOUD",
                  "timeSeriesFilter": {
                    "aggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_NONE",
                      "perSeriesAligner": "ALIGN_RATE"
                    },
                    "filter": "metric.type=\"prometheus.googleapis.com/flask_http_request_total/counter\" resource.type=\"prometheus_target\"",
                    "secondaryAggregation": {
                      "alignmentPeriod": "60s",
                      "crossSeriesReducer": "REDUCE_MEAN",
                      "groupByFields": ["metric.label.\"status\""],
                      "perSeriesAligner": "ALIGN_MEAN"
                    }
                  }
                }
              }
            ],
            "thresholds": [],
            "timeshiftDuration": "0s",
            "yAxis": {
              "label": "y1Axis",
              "scale": "LINEAR"
            }
          }
        },
        "width": 6,
        "xPos": 0,
        "yPos": 0
      }
    ]
  }
}'''

echo -e "\nReturning to home directory..."
cd || exit 1

# Clean up temporary files
remove_files() {
  for file in *; do
    if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
      if [[ -f "$file" ]]; then
        rm "$file"
        echo "Removed file: $file"
      fi
    fi
  done
}

remove_files

echo
echo "${MAGENTA}${BOLD}---- Congratulations for Completing the Lab !${RESET}"
