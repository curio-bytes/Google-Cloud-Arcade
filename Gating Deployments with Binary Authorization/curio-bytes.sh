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
echo "${MAGENTA_TEXT}${BOLD_TEXT}===========================================${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}          Solution from Curio Bytes        ${RESET_FORMAT}"
echo "${MAGENTA_TEXT}${BOLD_TEXT}===========================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}... Starting Execution ...${RESET_FORMAT}"
echo

export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(echo "$ZONE" | cut -d '-' -f 1-2)

# Confirm values
echo "Using ZONE: $ZONE"
echo "Derived REGION: $REGION"

# ENVIRONMENT SETUP
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
echo "Using PROJECT_ID: $PROJECT_ID"
echo "Using PROJECT_NUMBER: $PROJECT_NUMBER"

# ENABLE SERVICES
gcloud services enable \
  cloudkms.googleapis.com \
  cloudbuild.googleapis.com \
  container.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  containerscanning.googleapis.com \
  ondemandscanning.googleapis.com \
  binaryauthorization.googleapis.com

# TASK 1: CREATE ARTIFACT REPO
gcloud artifacts repositories create artifact-scanning-repo \
  --repository-format=docker \
  --location="$REGION" \
  --description="Docker repository"

sleep 2

gcloud auth configure-docker "$REGION-docker.pkg.dev"

mkdir vuln-scan && cd vuln-scan

# CREATE DOCKERFILE
cat > Dockerfile << EOF
FROM python:3.8-alpine  
WORKDIR /app
COPY . ./
RUN pip3 install Flask==2.1.0 gunicorn==20.1.0 Werkzeug==2.2.2
CMD exec gunicorn --bind :\$PORT --workers 1 --threads 8 main:app
EOF

# CREATE APP
cat > main.py << EOF
import os
from flask import Flask
app = Flask(__name__)
@app.route("/")
def hello_world():
    name = os.environ.get("NAME", "Worlds")
    return "Hello {}!".format(name)
if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
EOF

# BUILD & PUSH IMAGE
gcloud builds submit . -t "$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image"

sleep 3

# TASK 2: IMAGE SIGNING - CREATE NOTE
NOTE_ID=vulnz_note
cat > vulnz_note.json << EOF
{
  "attestation": {
    "hint": {
      "human_readable_name": "Container Vulnerabilities attestation authority"
    }
  }
}
EOF

curl -s -X POST \
    -H "Content-Type: application/json"  \
    -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
    --data-binary @vulnz_note.json  \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# CREATE ATTESTOR
ATTESTOR_ID=vulnz-attestor
gcloud container binauthz attestors create $ATTESTOR_ID \
    --attestation-authority-note=$NOTE_ID \
    --attestation-authority-note-project=${PROJECT_ID}

# BIND NOTE VIEWER TO BINAUTHZ SA
BINAUTHZ_SA_EMAIL="service-${PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
cat > iam_request.json << EOF
{
  "policy": {
    "bindings": [
      {
        "role": "roles/containeranalysis.notes.occurrences.viewer",
        "members": [
          "serviceAccount:${BINAUTHZ_SA_EMAIL}"
        ]
      }
    ]
  }
}
EOF

curl -s -X POST \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" \
    -H "Content-Type: application/json" \
    --data-binary @iam_request.json \
    "https://containeranalysis.googleapis.com/v1/projects/${PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

sleep 4
# TASK 3: KMS KEY CREATION
KEY_LOCATION=global
KEYRING=binauthz-keys
KEY_NAME=codelab-key
KEY_VERSION=1

gcloud kms keyrings create "$KEYRING" --location="$KEY_LOCATION"
gcloud kms keys create "$KEY_NAME" \
  --location="$KEY_LOCATION" --keyring="$KEYRING" \
  --purpose=asymmetric-signing \
  --default-algorithm=ec-sign-p256-sha256

sleep 2
# ADD KMS KEY TO ATTESTOR
gcloud beta container binauthz attestors public-keys add \
  --attestor="${ATTESTOR_ID}" \
  --keyversion-project="${PROJECT_ID}" \
  --keyversion-location="${KEY_LOCATION}" \
  --keyversion-keyring="${KEYRING}" \
  --keyversion-key="${KEY_NAME}" \
  --keyversion="${KEY_VERSION}"

sleep 3
# TASK 4: SIGN IMAGE
CONTAINER_PATH="$REGION-docker.pkg.dev/${PROJECT_ID}/artifact-scanning-repo/sample-image"
DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:latest --format='get(image_summary.digest)')

gcloud beta container binauthz attestations sign-and-create \
  --artifact-url="${CONTAINER_PATH}@${DIGEST}" \
  --attestor="${ATTESTOR_ID}" \
  --attestor-project="${PROJECT_ID}" \
  --keyversion-project="${PROJECT_ID}" \
  --keyversion-location="${KEY_LOCATION}" \
  --keyversion-keyring="${KEYRING}" \
  --keyversion-key="${KEY_NAME}" \
  --keyversion="${KEY_VERSION}"

sleep 2
# TASK 5: GKE CLUSTER & POLICY
gcloud beta container clusters create binauthz \
  --zone "$ZONE" \
  --binauthz-evaluation-mode=PROJECT_SINGLETON_POLICY_ENFORCE

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/container.developer"

# TASK 6: AUTO SIGN VIA CLOUD BUILD
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/binaryauthorization.attestorsViewer"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/cloudkms.signerVerifier"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
  --role="roles/cloudkms.signerVerifier"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/containeranalysis.notes.attacher"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/ondemandscanning.admin"

sleep 3

git clone https://github.com/GoogleCloudPlatform/cloud-builders-community.git
cd cloud-builders-community/binauthz-attestation
sleep 2

gcloud builds submit . --config cloudbuild.yaml

sleep 2

cd ../..
rm -rf cloud-builders-community

# CREATE cloudbuild.yaml
cat > cloudbuild.yaml << EOF
steps:
- id: "build"
  name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '$CONTAINER_PATH', '.']

- id: "retag"
  name: 'gcr.io/cloud-builders/docker'
  args: ['tag', '$CONTAINER_PATH', '${CONTAINER_PATH}:good']

- id: "push"
  name: 'gcr.io/cloud-builders/docker'
  args: ['push', '${CONTAINER_PATH}:good']

- id: "create-attestation"
  name: "gcr.io/${PROJECT_ID}/binauthz-attestation:latest"
  args:
    - "--artifact-url"
    - "${CONTAINER_PATH}:good"
    - "--attestor"
    - "projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}"
    - "--keyversion"
    - "projects/${PROJECT_ID}/locations/${KEY_LOCATION}/keyRings/${KEYRING}/cryptoKeys/${KEY_NAME}/cryptoKeyVersions/${KEY_VERSION}"

images:
- "${CONTAINER_PATH}:good"
EOF

gcloud builds submit .

# TASK 7: AUTHORIZE ONLY SIGNED IMAGES
cat > binauth_policy.yaml << EOF
defaultAdmissionRule:
  evaluationMode: REQUIRE_ATTESTATION
  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
  requireAttestationsBy:
  - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}
globalPolicyEvaluationMode: ENABLE
clusterAdmissionRules:
  ${ZONE}.binauthz:
    evaluationMode: REQUIRE_ATTESTATION
    enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG
    requireAttestationsBy:
    - projects/${PROJECT_ID}/attestors/${ATTESTOR_ID}
EOF

gcloud beta container binauthz policy import binauth_policy.yaml

# DEPLOY SIGNED IMAGE
GOOD_DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:good --format='get(image_summary.digest)')
cat > deploy.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: deb-httpd
spec:
  selector:
    app: deb-httpd
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deb-httpd
spec:
  replicas: 1
  selector:
    matchLabels:
      app: deb-httpd
  template:
    metadata:
      labels:
        app: deb-httpd
    spec:
      containers:
      - name: deb-httpd
        image: ${CONTAINER_PATH}@${GOOD_DIGEST}
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
EOF

sleep 3

kubectl apply -f deploy.yaml

# TASK 8: DEPLOY BLOCKED IMAGE
docker build -t "${CONTAINER_PATH}:bad" .
docker push "${CONTAINER_PATH}:bad"
BAD_DIGEST=$(gcloud container images describe ${CONTAINER_PATH}:bad --format='get(image_summary.digest)')

sed -i "s|${GOOD_DIGEST}|${BAD_DIGEST}|" deploy.yaml
kubectl apply -f deploy.yaml || echo "As expected: Unsigned image deployment was blocked."


echo
echo "${CYAN_TEXT}${BOLD_TEXT}--------------- Congratulations for completing the lab !! ---------------${RESET_FORMAT}"
echo
