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
echo "${YELLOW_COLOR}${BOLD}==============================================${RESET}"
echo "${YELLOW_COLOR}${BOLD}            Solution From Curio Bytes         ${RESET}"
echo "${YELLOW_COLOR}${BOLD}==============================================${RESET}"
echo

# Display initiation message
echo "${GREEN_TEXT}${BOLD_TEXT}... Initiating Execution ...${RESET_FORMAT}"

echo

echo -e "${YELLOW_COLOR}${BOLD_TEXT}-> Enter ZONE:${RESET_FORMAT} \c"
read ZONE
echo -e "${YELLOW_COLOR}${BOLD_TEXT}-> Enter the Static IP:${RESET_FORMAT} \c"
read STATIC_IP

# Export and configure values
export ZONE
export STATIC_IP
export REGION="${ZONE%-*}"

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# Display configuration
echo -e "\n${YELLOW_COLOR}${BOLD_TEXT}Configuration set to :${RESET_FORMAT}"
echo "ZONE: $ZONE"
echo "REGION: $REGION"
echo "STATIC_IP: $STATIC_IP"

sudo apt-get install -y virtualenv

python3 -m venv venv

source venv/bin/activate

echo 'sudo chmod -R 777 /usr/local/sbin/
sudo cat << EOF > /usr/local/sbin/serveprimes.py
import http.server
def is_prime(a): return a!=1 and all(a % i for i in range(2,int(a**0.5)+1))
class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/plain")
    s.end_headers()
    s.wfile.write(bytes(str(is_prime(int(s.path[1:]))).encode("utf-8")))
http.server.HTTPServer(("",80),myHandler).serve_forever()
EOF
nohup python3 /usr/local/sbin/serveprimes.py >/dev/null 2>&1 &' > backend.sh

gcloud compute instance-templates create primecalc \
--metadata-from-file startup-script=backend.sh \
--no-address --tags backend --machine-type=e2-medium

gcloud compute firewall-rules create http --network default --allow=tcp:80 \
--source-ranges 10.142.0.0/20 --target-tags backend

gcloud compute instance-groups managed create backend \
--size 3 \
--template primecalc \
--zone $ZONE

gcloud compute instance-groups managed set-autoscaling backend \
--target-cpu-utilization 0.8 --min-num-replicas 3 \
--max-num-replicas 10 --zone $ZONE

gcloud compute health-checks create http ilb-health --request-path /2

gcloud compute backend-services create prime-service \
--load-balancing-scheme internal --region=$REGION \
--protocol tcp --health-checks ilb-health

gcloud compute backend-services add-backend prime-service \
--instance-group backend --instance-group-zone=$ZONE \
--region=$REGION

gcloud compute forwarding-rules create prime-lb \
--load-balancing-scheme internal \
--ports 80 --network default \
--region=$REGION --address $STATIC_IP \
--backend-service prime-service

echo 'sudo chmod -R 777 /usr/local/sbin/
sudo cat << EOF > /usr/local/sbin/getprimes.py
import urllib.request
from multiprocessing.dummy import Pool as ThreadPool
import http.server
PREFIX="http://10.128.10.10/" #HTTP Load Balancer
def get_url(number):
    return urllib.request.urlopen(PREFIX+str(number)).read()
class myHandler(http.server.BaseHTTPRequestHandler):
  def do_GET(s):
    s.send_response(200)
    s.send_header("Content-type", "text/html")
    s.end_headers()
    i = int(s.path[1:]) if (len(s.path)>1) else 1
    s.wfile.write("<html><body><table>".encode('utf-8'))
    pool = ThreadPool(10)
    results = pool.map(get_url,range(i,i+100))
    for x in range(0,100):
      if not (x % 10): s.wfile.write("<tr>".encode('utf-8'))
      if results[x]=="True":
        s.wfile.write("<td bgcolor='#00ff00'>".encode('utf-8'))
      else:
        s.wfile.write("<td bgcolor='#ff0000'>".encode('utf-8'))
      s.wfile.write(str(x+i).encode('utf-8')+"</td> ".encode('utf-8'))
      if not ((x+1) % 10): s.wfile.write("</tr>".encode('utf-8'))
    s.wfile.write("</table></body></html>".encode('utf-8'))
http.server.HTTPServer(("",80),myHandler).serve_forever()
EOF
nohup python3 /usr/local/sbin/getprimes.py >/dev/null 2>&1 &' > frontend.sh

gcloud compute instances create frontend --zone=$ZONE \
--metadata-from-file startup-script=frontend.sh \
--tags frontend --machine-type=e2-standard-2

gcloud compute firewall-rules create http2 --network default --allow=tcp:80 \
--source-ranges 0.0.0.0/0 --target-tags frontend

echo
rm -- "$0"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}------- Congratulations for Completing the lab !! ---------${RESET_FORMAT}"
