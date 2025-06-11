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
echo -e "${YELLOW}==============================================${RESET_FORMAT}"
echo

echo "${GREEN}${BOLD}..... Starting Execution ......${RESET}"

gcloud services enable appengine.googleapis.com

sleep 10

gcloud config set compute/region $REGION

echo
echo ">> Cloning Gihub repository ... "
echo

git clone https://github.com/GoogleCloudPlatform/golang-samples.git

echo

cd golang-samples/appengine/go11x/helloworld

echo
echo ">> Installing Google Cloud App Engine ..."
echo

sudo apt-get install google-cloud-sdk-app-engine-go

echo
echo ">> Deploying the App ..."
gcloud app deploy

echo
echo "${RED}${BOLD}Congratulations${RESET}" "${WHITE}${BOLD}for${RESET}" "${GREEN}${BOLD}Completing the Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#
