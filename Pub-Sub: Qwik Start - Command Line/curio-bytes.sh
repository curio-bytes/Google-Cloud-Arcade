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
echo "${MAGENTA}${BOLD}..... Creating Pub/Sub Topic 'myTopic' ......${RESET}"
gcloud pubsub topics create myTopic



echo
echo "${CYAN}${BOLD}..... Creating Pub/Sub Subscription .....${RESET}"
gcloud  pubsub subscriptions create --topic myTopic mySubscription

echo
echo "${BG_CYAN}------------- Congratulations for Completing the lab!! ----------------${RESET_FORMAT}"
echo
