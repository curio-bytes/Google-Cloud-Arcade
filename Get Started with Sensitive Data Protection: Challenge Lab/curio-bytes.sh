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

echo -n "${GREEN_TEXT}${BOLD_TEXT}>> Enter bucket_name : ${RESET_FORMAT}"
read bucket_name


cat > redact-request.json <<EOF
{
  "item": {
    "value": "Please update my records with the following information:\n Email address: foo@example.com,\nNational Provider Identifier: 1245319599"
  },
  "deidentifyConfig": {
    "infoTypeTransformations": {
      "transformations": [{
        "primitiveTransformation": {
          "replaceWithInfoTypeConfig": {}
        }
      }]
    }
  },
  "inspectConfig": {
    "infoTypes": [{
        "name": "EMAIL_ADDRESS"
      },
      {
        "name": "US_HEALTHCARE_NPI"
      }
    ]
  }
}
EOF


curl -s \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  https://dlp.googleapis.com/v2/projects/$DEVSHELL_PROJECT_ID/content:deidentify \
  -d @redact-request.json -o redact-response.txt

echo
echo "${BLUE_TEXT}${BOLD_TEXT} Uploading the de-identified output to your Cloud Storage bucket...${RESET_FORMAT}"
gsutil cp redact-response.txt gs://$bucket_name

echo "${GREEN_TEXT}${BOLD_TEXT} Click here : ${BLUE_TEXT}https://console.cloud.google.com/security/sensitive-data-protection/landing/configuration/templates/deidentify?project=${DEVSHELL_PROJECT_ID}${RESET_FORMAT}"

echo "${CYAN_TEXT}${BOLD_TEXT} <<< Now Follow Video's Instructions >>>     ${RESET_FORMAT}"
