BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo
echo -e "${GREEN}==============================================${RESET_FORMAT}"
echo -e "${GREEN}          Solution From Curio Bytes         ${RESET_FORMAT}"
echo -e "${GREEN}==============================================${RESET_FORMAT}"
echo

echo "${BG_BLUE}${BOLD}..... Starting Execution ......${RESET}"

gcloud services enable automl.googleapis.com

gsutil mb -p $DEVSHELL_PROJECT_ID \
    -c standard    \
    -l us \
    gs://$DEVSHELL_PROJECT_ID-vcm/

export BUCKET=$DEVSHELL_PROJECT_ID-vcm

gsutil -m cp -r gs://spls/gsp223/images/* gs://${BUCKET}

gsutil cp gs://spls/gsp223/data.csv .

sed -i -e "s/placeholder/${BUCKET}/g" ./data.csv

gsutil cp ./data.csv gs://${BUCKET}


echo
echo "${YELLOW}${BOLD}Now click here: "${RESET}""${BLUE}${BOLD}""https://console.cloud.google.com/vertex-ai/datasets/create?project=$DEVSHELL_PROJECT_ID"""${RESET}"
echo
echo "${CYAN}${BOLD}  <<< Now follow video's instruction >>>${RESET}"
