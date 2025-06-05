gcloud auth list

export PROJECT_ID=$(gcloud config get-value project)

gcloud services enable texttospeech.googleapis.com

sudo apt-get install -y virtualenv

python3 -m venv venv

source venv/bin/activate

gcloud iam service-accounts create tts-qwiklab

gcloud iam service-accounts keys create tts-qwiklab.json --iam-account tts-qwiklab@$PROJECT_ID.iam.gserviceaccount.com

export GOOGLE_APPLICATION_CREDENTIALS=tts-qwiklab.json

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}LIKE AND SUBSCRIBE MY YOUTUBE CHANNEL${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}-> https://youtube.com/@curio_bytes_15${RESET_FORMAT}"
echo
