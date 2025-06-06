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
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}    Solution from Curio Bytes      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}===================================${RESET_FORMAT}"
echo

echo "${RED_TEXT}${BOLD_TEXT}-> Step 1:${RESET_FORMAT} ${RED_TEXT}Enabling the Firestore API for your project.${RESET_FORMAT}"
gcloud services enable firestore.googleapis.com

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Step 2:${RESET_FORMAT} ${GREEN_TEXT}Creating Firestore Database in Datastore mode...${RESET_FORMAT}"
gcloud firestore databases create --location=nam5 --type=datastore-mode

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}-> Step 3:${RESET_FORMAT} ${YELLOW_TEXT}Creating Python script to insert task into Firestore...${RESET_FORMAT}"
cat << 'EOF' > insert_task.py
from google.cloud import datastore
from datetime import datetime

# Initialize client
client = datastore.Client()

# Define the kind and create a task entity
kind = "Task"
task_key = client.key(kind)

task = datastore.Entity(key=task_key)
task.update({
  "description": "Learn Google Cloud Datastore",
  "created": datetime.utcnow(),
  "done": False
})

client.put(task)
print("Task entity added successfully.")
EOF

echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Step 4:${RESET_FORMAT} ${BLUE_TEXT}Creating and activating Python virtual environment...${RESET_FORMAT}"
python3 -m venv env
source env/bin/activate

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Step 5:${RESET_FORMAT} ${MAGENTA_TEXT}Installing google-cloud-datastore package...${RESET_FORMAT}"
pip install google-cloud-datastore

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Step 6:${RESET_FORMAT} ${CYAN_TEXT}Running Python script to insert task...${RESET_FORMAT}"
python insert_task.py

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Congratulations for Completing the Lab !${RESET_FORMAT}"
echo
