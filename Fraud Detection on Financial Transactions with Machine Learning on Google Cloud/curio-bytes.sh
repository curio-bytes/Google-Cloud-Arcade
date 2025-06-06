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
echo "${CYAN_TEXT}${BOLD_TEXT}                   ===================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                       SOLUTION FROM CURIO BYTES      ${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}                   ===================================${RESET_FORMAT}"
echo

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Setting your Google Cloud Project ID...${RESET_FORMAT}"
export PROJECT_ID=$(gcloud config get-value project)

echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Copying the dataset from Cloud Storage...${RESET_FORMAT}"
gsutil cp gs://spls/gsp774/archive.zip .

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Unzipping the downloaded file...${RESET_FORMAT}"
unzip archive.zip

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Assigning data file variable...${RESET_FORMAT}"
export DATA_FILE=PS_20174392719_1491204439457_log.csv

echo
echo "${RED_TEXT}${BOLD_TEXT}-> Creating a new BigQuery dataset named 'finance'...${RESET_FORMAT}"
bq mk --dataset $PROJECT_ID:finance

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}-> Setting up a new Cloud Storage bucket...${RESET_FORMAT}"
gsutil mb gs://$PROJECT_ID

echo
echo "${GREEN_TEXT}${BOLD_TEXT}⬆-> Uploading the data file to the Cloud Storage bucket...${RESET_FORMAT}"
gsutil cp $DATA_FILE gs://$PROJECT_ID

echo
echo "${BLUE_TEXT}${BOLD_TEXT}-> Loading the data into BigQuery table 'finance.fraud_data'...${RESET_FORMAT}"
bq load --autodetect --source_format=CSV --max_bad_records=100000 finance.fraud_data gs://$PROJECT_ID/$DATA_FILE

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Summarizing transactions by type and fraud status...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"SELECT type, isFraud, count(*) as cnt
 FROM \`finance.fraud_data\`
 GROUP BY isFraud, type
 ORDER BY type"

echo
echo "${CYAN_TEXT}${BOLD_TEXT}-> Checking fraud counts for 'CASH_OUT' and 'TRANSFER' transactions...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'SELECT isFraud, count(*) as cnt
FROM `finance.fraud_data`
WHERE type in ("CASH_OUT", "TRANSFER")
GROUP BY isFraud'

echo
echo "${RED_TEXT}${BOLD_TEXT}-> Displaying the top 10 largest transactions...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"SELECT *
 FROM \`finance.fraud_data\`
 ORDER BY amount DESC
 LIMIT 10"

echo
echo "${YELLOW_TEXT}${BOLD_TEXT}-> Creating a sampled dataset with engineered features...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'CREATE OR REPLACE TABLE finance.fraud_data_sample AS
SELECT
  type,
  amount,
  nameOrig,
  nameDest,
  oldbalanceOrg as oldbalanceOrig,  #standardize the naming.
  newbalanceOrig,
  oldbalanceDest,
  newbalanceDest,
# add new features:
  if(oldbalanceOrg = 0.0, 1, 0) as origzeroFlag,
  if(newbalanceDest = 0.0, 1, 0) as destzeroFlag,
  round((newbalanceDest-oldbalanceDest-amount)) as amountError,
  generate_uuid() as id,        #create a unique id for each transaction.
  isFraud
FROM finance.fraud_data
WHERE
# filter unnecessary transaction types:
  type in("CASH_OUT","TRANSFER") AND
# undersample:
  (isFraud = 1 or (RAND()< 10/100))'  # select 10% of the non-fraud cases

echo
echo "${GREEN_TEXT}${BOLD_TEXT}<< NOW APPLYING MACHINE LEARNING ALGORITHM ON DATASETS >>${RESET_FORMAT}"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}-> Splitting the data into test and model datasets...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE finance.fraud_data_test AS
SELECT *
FROM finance.fraud_data_sample
where RAND() < 20/100"

bq query --use_legacy_sql=false \
"CREATE OR REPLACE TABLE finance.fraud_data_model AS
SELECT
*
FROM finance.fraud_data_sample  
EXCEPT distinct select * from finance.fraud_data_test"

echo "${BLUE_TEXT}${BOLD_TEXT}-> Training an unsupervised K-Means clustering model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL
  finance.model_unsupervised OPTIONS(model_type='kmeans', num_clusters=5) AS
SELECT
  amount, oldbalanceOrig, newbalanceOrig, oldbalanceDest, newbalanceDest, type, origzeroFlag, destzeroFlag, amountError
  FROM
  \`finance.fraud_data_model\`"

echo "${MAGENTA_TEXT}${BOLD_TEXT}-> Reviewing fraud distribution across clusters...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'SELECT
  centroid_id, sum(isfraud) as fraud_cnt,  count(*) total_cnt
FROM
  ML.PREDICT(MODEL `finance.model_unsupervised`,
    (
    SELECT *
    FROM  `finance.fraud_data_test`))
group by centroid_id
order by centroid_id'

echo "${GREEN_TEXT}${BOLD_TEXT}-. Training a supervised logistic regression model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
"CREATE OR REPLACE MODEL
  finance.model_supervised_initial
  OPTIONS(model_type='LOGISTIC_REG', INPUT_LABEL_COLS = ['isfraud']
  )
AS
SELECT
type, amount, oldbalanceOrig, newbalanceOrig, oldbalanceDest, newbalanceDest, isFraud
FROM finance.fraud_data_model"

echo "${CYAN_TEXT}${BOLD_TEXT}-> Retrieving weights from the logistic regression model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'SELECT
  *
FROM
  ML.WEIGHTS(MODEL `finance.model_supervised_initial`,
    STRUCT(true AS standardize))'

echo
echo "${RED_TEXT}${BOLD_TEXT}-> Predicting fraud cases using the trained model...${RESET_FORMAT}"
bq query --use_legacy_sql=false \
'SELECT id, label as predicted, isFraud as actual
FROM
  ML.PREDICT(MODEL `finance.model_supervised_initial`,
   (
    SELECT  *
    FROM  `finance.fraud_data_test`
   )
  ), unnest(predicted_isfraud_probs) as p
where p.label = 1 and p.prob > 0.5'

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}CONGRATULATIONS FOR COMPLETING THE LAB !${RESET_FORMAT}"
echo
