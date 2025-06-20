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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}     Solution from Curio Bytes     ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}... Starting Execution ...${RESET_FORMAT}"
echo


gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

export BUCKET_NAME=$DEVSHELL_PROJECT_ID-bucket
export PROJECT_ID=$DEVSHELL_PROJECT_ID

git clone https://github.com/googleapis/synthtool

gcloud config set project $DEVSHELL_PROJECT_ID

cd synthtool/tests/fixtures/nodejs-dlp/samples/ && npm install

gcloud services enable dlp.googleapis.com cloudkms.googleapis.com --project=$DEVSHELL_PROJECT_ID

node inspectString.js $PROJECT_ID "My email address is jenny@somedomain.com and you can call me at 555-867-5309" > inspected-string.txt

node inspectFile.js $PROJECT_ID resources/accounts.txt > inspected-file.txt

gsutil cp inspected-string.txt gs://$BUCKET_NAME
gsutil cp inspected-file.txt gs://$BUCKET_NAME

node deidentifyWithMask.js $PROJECT_ID "My order number is F12312399. Email me at anthony@somedomain.com" > de-identify-output.txt

gsutil cp de-identify-output.txt gs://$BUCKET_NAME

node redactText.js $PROJECT_ID  "Please refund the purchase to my credit card 4012888888881881" CREDIT_CARD_NUMBER > redacted-string.txt

node redactImage.js $PROJECT_ID resources/test.png "" PHONE_NUMBER ./redacted-phone.png

node redactImage.js $PROJECT_ID resources/test.png "" EMAIL_ADDRESS ./redacted-email.png

gsutil cp redacted-string.txt gs://$BUCKET_NAME
gsutil cp redacted-phone.png gs://$BUCKET_NAME
gsutil cp redacted-email.png gs://$BUCKET_NAME


echo
echo "${CYAN_TEXT}${BOLD_TEXT}... Congratulations for completing the lab !! ...${RESET_FORMAT}"
echo
