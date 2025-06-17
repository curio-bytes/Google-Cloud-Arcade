
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'
clear

echo
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}         Solution from Curio Bytes     ${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}=======================================${RESET_FORMAT}"
echo

echo "${CYAN_TEXT}${BOLD_TEXT}... Starting Execution ... ${RESET_FORMAT}"

echo
echo "${RED_TEXT}${BOLD_TEXT} Task 1 : Set Project and Zone ${RESET_FORMAT}"
echo

gcloud auth list
  
export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

PROJECT=$(gcloud config get-value project)

REGION="${ZONE%-*}"

CLUSTER=gke-load-test
TARGET=${PROJECT}.appspot.com

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Task 2 : Get the sample code and build a Docker image for the application ${RESET_FORMAT}"
echo

gsutil -m cp -r gs://spls/gsp182/distributed-load-testing-using-kubernetes .

cd distributed-load-testing-using-kubernetes/sample-webapp/

sed -i "s/python37/python39/g" app.yaml

cd ..

gcloud builds submit --tag gcr.io/$PROJECT/locust-tasks:latest docker-image/.

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT} Task 3 : Deploy web application ${RESET_FORMAT}"
echo

gcloud app deploy sample-webapp/app.yaml

echo
echo "${CYAN_TEXT}${BOLD_TEXT} Task 4. Deploy Kubernetes cluster ${RESET_FORMAT}"
echo

gcloud container clusters create $CLUSTER \
  --zone $ZONE \
  --num-nodes=5

echo
echo "${YELLOW_TEXT}${BOLD_TEXT} Task 5. Load testing master ${RESET_FORMAT}"
echo

echo
echo "${RED_TEXT}${BOLD_TEXT} Task 6. Deploy locust-master ${RESET_FORMAT}"
echo

sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[TARGET_HOST\]/$TARGET/g" kubernetes-config/locust-worker-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-master-controller.yaml
sed -i -e "s/\[PROJECT_ID\]/$PROJECT/g" kubernetes-config/locust-worker-controller.yaml

kubectl apply -f kubernetes-config/locust-master-controller.yaml

kubectl get pods -l app=locust-master

kubectl apply -f kubernetes-config/locust-master-service.yaml

kubectl get svc locust-master

echo
echo "${WHITE_TEXT}${BOLD_TEXT} Task 7. Load testing workers ${RESET_FORMAT}"
echo

kubectl apply -f kubernetes-config/locust-worker-controller.yaml

kubectl get pods -l app=locust-worker

kubectl scale deployment/locust-worker --replicas=20

kubectl get pods -l app=locust-worker

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT} Task 8. Execute tests ${RESET_FORMAT}"
echo


echo
echo "${GREEN_TEXT}${BOLD_TEXT}--------- Congratulations for Completing the lab !! ---------${RESET_FORMAT}"
echo
