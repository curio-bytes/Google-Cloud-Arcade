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

echo
echo "${CYAN}${BOLD}..... Enable the Google App Engine Admin API .....${RESET}"
gcloud services enable appengine.googleapis.com

cat > prepare_disk.sh <<'EOF_END'

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world

EOF_END

export ZONE=$(gcloud compute instances list lab-setup --format 'csv[no-heading](zone)')

export REGION="${ZONE%-*}"

gcloud compute scp prepare_disk.sh lab-setup:/tmp --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet

gcloud compute ssh lab-setup --project=$DEVSHELL_PROJECT_ID --zone=$ZONE --quiet --command="bash /tmp/prepare_disk.sh"

echo
echo "${CYAN}${BOLD}..... Download the Hello World app .....${RESET}"

git clone https://github.com/GoogleCloudPlatform/python-docs-samples.git

cd python-docs-samples/appengine/standard_python3/hello_world


echo
echo "${CYAN}${BOLD}..... Deploy your application .....${RESET}"

gcloud app create --region=$REGION

yes | gcloud app deploy

echo
echo "${CYAN}${BOLD}..... Deploy updates to your application .....${RESET}"

sed -i 's/Hello World!/'"$MESSAGE"'/g' main.py

yes | gcloud app deploy

echo
echo "${RED}------------- Congratulations for Completing the lab!! ----------------${RESET_FORMAT}"
echo
