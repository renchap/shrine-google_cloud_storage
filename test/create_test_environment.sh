#!/usr/bin/env sh
set -ex

# This script will create a service account for GCS used for testing and will add to ../.env the necessary env variables.
# The script below assumes you have run `gcloud auth login`
#
# Set the following before running the script:
#   GOOGLE_CLOUD_PROJECT=[SET YOUR PROJECT ID]
#
GCS_SA=shrine-gcs-test
GOOGLE_CLOUD_KEYFILE=${HOME}/.gcp/$GOOGLE_CLOUD_PROJECT/$GCS_SA.json

gcloud iam service-accounts create $GCS_SA \
    --project=$GOOGLE_CLOUD_PROJECT \
    --display-name $GCS_SA

GCS_SA_EMAIL=$(gcloud iam service-accounts list \
    --project=$GOOGLE_CLOUD_PROJECT \
    --filter="displayName:$GCS_SA" \
    --format='value(email)')

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --role roles/storage.admin \
    --member serviceAccount:$GCS_SA_EMAIL

# Download the service account json
mkdir -p $(dirname $GOOGLE_CLOUD_KEYFILE)
rm -f $GOOGLE_CLOUD_KEYFILE
gcloud iam service-accounts keys create $GOOGLE_CLOUD_KEYFILE \
    --iam-account $GCS_SA_EMAIL

GCS_BUCKET=${GCS_SA}-${GOOGLE_CLOUD_PROJECT}
gsutil mb -p $GOOGLE_CLOUD_PROJECT gs://$GCS_BUCKET/

cat >../.env <<EOL
GCS_BUCKET=${GCS_BUCKET}
GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}
GOOGLE_CLOUD_KEYFILE=${GOOGLE_CLOUD_KEYFILE}
EOL
