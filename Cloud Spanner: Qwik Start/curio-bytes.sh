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

gcloud auth list

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export PROJECT_ID=$(gcloud config get-value project)
gcloud config set project $DEVSHELL_PROJECT_ID

gcloud config set compute/region "$REGION"


gcloud spanner instances create test-instance --project=$DEVSHELL_PROJECT_ID --config=regional-$REGION --description="subscribe to techcps" --nodes=1


gcloud spanner databases create example-db --instance=test-instance

gcloud spanner databases ddl update example-db --instance=test-instance \
  --ddl="CREATE TABLE Singers (
    SingerId INT64 NOT NULL,
    FirstName STRING(1024),
    LastName STRING(1024),
    SingerInfo BYTES(MAX),
    BirthDate DATE,
    ) PRIMARY KEY(SingerId);"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}--------- Congratulations for Completing the lab !! ---------${RESET_FORMAT}"
echo
