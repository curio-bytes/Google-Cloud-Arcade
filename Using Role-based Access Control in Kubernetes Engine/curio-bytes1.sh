#!/bin/bash

set -e

# ----------------------------
# 🔍 PREREQUISITE CHECKS
# ----------------------------

echo "🔍 Checking environment..."

# Ensure running in Google Cloud Shell
if [[ -z "$CLOUD_SHELL" ]]; then
  echo "❌ This script must be run inside Google Cloud Shell."
  exit 1
fi

# Check for gcloud
if ! command -v gcloud &>/dev/null; then
  echo "❌ 'gcloud' is not installed. Cloud Shell should include this. Exiting."
  exit 1
fi

# Check for kubectl
if ! command -v kubectl &>/dev/null; then
  echo "❌ 'kubectl' not found. Installing..."
  sudo apt-get update && sudo apt-get install -y kubectl
fi

# Check for make, install if missing
if ! command -v make &>/dev/null; then
  echo "⚠️ 'make' not found. Installing 'make'..."
  sudo apt-get update && sudo apt-get install -y make
fi

# ----------------------------
# 📍 REGION & ZONE SETUP
# ----------------------------
read -p "📍 Enter the region (e.g. us-east4): " REGION
read -p "📍 Enter the zone (e.g. us-east4-b): " ZONE

echo "✅ Setting region and zone..."
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# ----------------------------
# 📦 Task 1: Clone Demo and Setup Cluster
# ----------------------------

echo "📦 Downloading and extracting demo files..."
gsutil cp gs://spls/gsp493/gke-rbac-demo.tar .
tar -xvf gke-rbac-demo.tar
cd gke-rbac-demo

echo "🔧 Creating GKE cluster with Terraform..."
make create

echo "⏳ Waiting for cluster to be in RUNNING state..."
while [[ -z $(gcloud container clusters list --filter="name=rbac-demo-cluster AND status=RUNNING" --format="value(name)") ]]; do
  echo "⏱️  Cluster is still provisioning..."
  sleep 30
done

# ----------------------------
# 👥 Task 2: RBAC Scenario 1
# ----------------------------

echo "🔎 Listing service accounts and instances..."
gcloud iam service-accounts list
gcloud compute instances list

# Step 3: Admin RBAC setup
echo "🔑 SSH into 'admin' instance to apply RBAC config..."
gcloud compute ssh gke-tutorial-admin --command "
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
  echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
  source ~/.bashrc
  gcloud container clusters get-credentials rbac-demo-cluster --zone=$ZONE
  kubectl apply -f ./manifests/rbac.yaml
"

# Step 5-6: Owner deploys servers
echo "🛠️  SSH into 'owner' instance to deploy workloads..."
gcloud compute ssh gke-tutorial-owner --command "
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
  echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
  source ~/.bashrc
  gcloud container clusters get-credentials rbac-demo-cluster --zone=$ZONE
  kubectl create -n dev -f ./manifests/hello-server.yaml
  kubectl create -n prod -f ./manifests/hello-server.yaml
  kubectl create -n test -f ./manifests/hello-server.yaml
  kubectl get pods -l app=hello-server --all-namespaces
"

# Step 7-9: Auditor access verification
echo "🔍 SSH into 'auditor' instance to verify access restrictions..."
gcloud compute ssh gke-tutorial-auditor --command "
  sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
  echo 'export USE_GKE_GCLOUD_AUTH_PLUGIN=True' >> ~/.bashrc
  source ~/.bashrc
  gcloud container clusters get-credentials rbac-demo-cluster --zone=$ZONE

  kubectl get pods -l app=hello-server --all-namespaces || echo 'Expected: Forbidden'
  kubectl get pods -l app=hello-server -n dev
  kubectl get pods -l app=hello-server -n test || echo 'Expected: Forbidden'
  kubectl get pods -l app=hello-server -n prod || echo 'Expected: Forbidden'
  kubectl create -n dev -f manifests/hello-server.yaml || echo 'Expected: Forbidden'
  kubectl delete deployment -n dev -l app=hello-server || echo 'Expected: Forbidden'
"

# ----------------------------
# 🤖 Task 3: API Role Permissions
# ----------------------------

# Step 1: Deploy app
echo "🚀 Deploying pod-labeler app..."
kubectl apply -f manifests/pod-labeler.yaml
sleep 10

# Step 2: Diagnose failures
echo "📋 Checking pod-labeler pod status..."
kubectl get pods -l app=pod-labeler
kubectl describe pod -l app=pod-labeler | tail -n 20
kubectl logs -l app=pod-labeler

# Step 3: Fix serviceAccount
echo "🔧 Fixing serviceAccount in pod-labeler-fix-1.yaml..."
cat <<EOF > manifests/pod-labeler-fix-1.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pod-labeler
spec:
  selector:
    matchLabels:
      app: pod-labeler
  template:
    metadata:
      labels:
        app: pod-labeler
    spec:
      serviceAccountName: pod-labeler
      containers:
      - name: pod-labeler
        image: us-docker.pkg.dev/google-samples/containers/pod-labeler:v0.1.0
EOF

kubectl apply -f manifests/pod-labeler-fix-1.yaml
kubectl get deployment pod-labeler -oyaml
sleep 5
kubectl logs -l app=pod-labeler

# Step 4: Fix Role permissions
echo "🔒 Updating RBAC Role to include 'patch'..."
cat <<EOF > manifests/pod-labeler-fix-2.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-labeler
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["list", "patch"]
EOF

kubectl apply -f manifests/pod-labeler-fix-2.yaml

echo "✅ Script completed! All steps executed. You can now click 'Check my progress' in the lab interface."
