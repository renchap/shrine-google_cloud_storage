#!/usr/bin/env sh
set -e

### This script will create a service account for GCS used for testing and will
### add to ../.env the necessary env variables.
### The script below assumes you have run `gcloud auth login`


# Set the project root, in a POSIX way
# Source: https://www.jasan.tk/posix/2017/05/11/posix_shell_dirname_replacement
a="/$0"; a=${a%/*}; a=${a:-.}; a=${a#/}/;
PROJECT_ROOT=$(cd $a/..; pwd)

ENV_FILE=$PROJECT_ROOT/.env

# Load the .env file variables
if [ -f $ENV_FILE ]; then . $ENV_FILE; fi

if [ -z "$GOOGLE_CLOUD_PROJECT" ] || [ -z "$GOOGLE_BILLING_ACCOUNT" ]
then
  echo "You need to create a file named \".env\" in your project directory"
  echo "and define the GOOGLE_CLOUD_PROJECT and GOOGLE_BILLING_ACCOUNT variables in it."
  echo "Please refer to \".env.sample\" for an example."

  exit 1
fi

GCS_SA=shrine-gcs-test
GCS_BUCKET=${GCS_SA}-${GOOGLE_CLOUD_PROJECT}
GOOGLE_CLOUD_KEYFILE="$PROJECT_ROOT/keyfile_$GCS_SA.json"

if [ -f $GOOGLE_CLOUD_KEYFILE ]
then
  echo "The file '$GOOGLE_CLOUD_KEYFILE' already exists. Please delete or move it before running this script."
  echo "WARNING: please review the content of this file before deleting it, it might contain"
  echo "         a private key for a Google Cloud Service Account you are using!"
  exit 4
fi

echo "This script will bootstrap a Google Cloud Project to run the shrine-google_cloud_storage test suite."
echo "It will create a Google Cloud Project named '$GOOGLE_CLOUD_PROJECT' linked to your $GOOGLE_BILLING_ACCOUNT Billing Account."
echo ""
echo "In this project, it will create the following resources:"
echo "- A Service Account named '$GCS_SA' with storage.admin permissions"
echo "- A Google Cloud Storage bucket named '$GCS_BUCKET'"
echo "The '$GCS_SA' Service Account credentials will be written to $GOOGLE_CLOUD_KEYFILE"
echo "Finally, the GCS_BUCKET and GOOGLE_CLOUD_KEYFILE variables will be added to your .env file"
echo ""

read -p "Continue (y/n)? " CONT

if [ "$CONT" != "y" ]
then
  echo "Aborting!"
  exit 3
fi

# Display every command executed from now
set -x

gcloud projects create $GOOGLE_CLOUD_PROJECT || read -p "Looks like this service accounts exists. If so, continue? (y/n)? " CONT

if [ "$CONT" == "n" ]
then
  echo "Aborting!"
  exit 3
fi

if [ $? -eq 1 ]
then
  set +x # Do not display those commands
  echo "The $GOOGLE_CLOUD_PROJECT project defined in your .env file already exists."
  echo "If you want to bootstrap a test project again, please delete it first in the Google Cloud console."
  echo "Otherwise, please use another project name."
  exit 2
fi

gcloud beta billing projects link $GOOGLE_CLOUD_PROJECT --billing-account=$GOOGLE_BILLING_ACCOUNT

gcloud iam service-accounts create $GCS_SA \
    --project=$GOOGLE_CLOUD_PROJECT \
    --display-name $GCS_SA || true

GCS_SA_EMAIL=$(gcloud iam service-accounts list \
    --project=$GOOGLE_CLOUD_PROJECT \
    --filter="displayName:$GCS_SA" \
    --format='value(email)')

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --role roles/storage.admin \
    --member serviceAccount:$GCS_SA_EMAIL

gcloud iam service-accounts keys create $GOOGLE_CLOUD_KEYFILE \
    --iam-account $GCS_SA_EMAIL

gsutil mb -p $GOOGLE_CLOUD_PROJECT gs://$GCS_BUCKET/

set +x # We dont need to display the last commands

cat >>$ENV_FILE <<EOL
GCS_BUCKET=${GCS_BUCKET}
GOOGLE_CLOUD_KEYFILE=${GOOGLE_CLOUD_KEYFILE}
EOL

echo "Success! The environment variables required to run the test suite"
echo "have been added to $ENV_FILE"
