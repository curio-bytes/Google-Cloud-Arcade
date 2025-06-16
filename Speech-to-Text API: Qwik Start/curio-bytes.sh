#!/bin/bash

# Define color variables
YELLOW_COLOR=$'\033[0;33m'
NO_COLOR=$'\033[0m'
BACKGROUND_RED=`tput setab 1`
GREEN_TEXT=$'\033[0;32m'
RED_TEXT=`tput setaf 1`
BOLD_TEXT=`tput bold`
RESET_FORMAT=`tput sgr0`
BLUE_TEXT=`tput setaf 4`

echo
echo "${YELLOW_COLOR}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo "${YELLOW_COLOR}${BOLD_TEXT}            Solution From Curio Bytes         ${RESET_FORMAT}"
echo "${YELLOW_COLOR}${BOLD_TEXT}==============================================${RESET_FORMAT}"
echo

echo "${GREEN_TEXT}${BOLD_TEXT}... Initiating Speech-to-Text API Request ...${RESET_FORMAT}"
echo

# Prompt user for API key
echo -e "${YELLOW_COLOR}${BOLD_TEXT}-> Enter your API Key:${RESET_FORMAT} \c"
read API_KEY
export API_KEY

# Create request.json file
cat << EOF > request.json
{
  "config": {
      "encoding":"FLAC",
      "languageCode": "en-US"
  },
  "audio": {
      "uri":"gs://cloud-samples-tests/speech/brooklyn.flac"
  }
}
EOF

# Send API request and save response
curl -s -X POST -H "Content-Type: application/json" --data-binary @request.json \
"https://speech.googleapis.com/v1/speech:recognize?key=${API_KEY}" > result.json

echo
echo "${GREEN_TEXT}${BOLD_TEXT}Speech-to-Text API response saved in 'result.json'.${RESET_FORMAT}"
echo


rm curio-bytes.sh

echo
echo "${GREEN_TEXT}${BOLD_TEXT}------- Congratulations for Completing the lab !! ---------${RESET_FORMAT}"
