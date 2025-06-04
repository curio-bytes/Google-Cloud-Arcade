gcloud auth list

export ZONE=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe --format="value(commonInstanceMetadata.items[google-compute-default-region])")

gcloud config set compute/zone "$ZONE"

gcloud config set compute/region "$REGION"

gcloud config set project "$DEVSHELL_PROJECT_ID"

gcloud services enable sqladmin.googleapis.com

gcloud sql instances create my-instance --project=$DEVSHELL_PROJECT_ID --region=$REGION --database-version=MYSQL_5_7 --tier=db-n1-standard-1

gcloud sql databases create mysql-db --instance=my-instance --project=$DEVSHELL_PROJECT_ID

bq mk --dataset $DEVSHELL_PROJECT_ID:mysql_db


bq query --use_legacy_sql=false \
"CREATE TABLE \`${DEVSHELL_PROJECT_ID}.mysql_db.info\` (
  name STRING,
  age INT64,
  occupation STRING
);"


cat > employee_info.csv <<EOF_CP
"Sean", 23, "Content Creator"
"Emily", 34, "Cloud Engineer"
"Rocky", 40, "Event coordinator"
"Kate", 28, "Data Analyst"
"Juan", 51, "Program Manager"
"Jennifer", 32, "Web Developer"
EOF_CP


gsutil mb gs://$DEVSHELL_PROJECT_ID

gsutil cp employee_info.csv gs://$DEVSHELL_PROJECT_ID/

SERVICE_EMAIL=$(gcloud sql instances describe my-instance --format="value(serviceAccountEmailAddress)")

gsutil iam ch serviceAccount:$SERVICE_EMAIL:roles/storage.admin gs://$DEVSHELL_PROJECT_ID/

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}Congratulations for completing the lab !${RESET_FORMAT}"
echo
