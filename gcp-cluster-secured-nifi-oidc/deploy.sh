#!/bin/sh

PROJECT=$1
BUCKET=$2

# set project
gcloud config set project $PROJECT

# init terraform
terraform init

# start NiFi CA to generate certificates that will be used for the load balancer
terraform apply -auto-approve -target=google_compute_instance.nifi-ca

# wait until certificates are generated and pushed into GCS
until gsutil ls gs://$BUCKET/key.pem; do
    sleep 1
done

# copy private key and public certificates locally to configure load balancer
gsutil cp gs://$BUCKET/key.pem .
gsutil cp gs://$BUCKET/certs.pem .

terraform apply -auto-approve

# delete/clean certs/key
gsutil rm gs://$BUCKET/key.pem
gsutil rm gs://$BUCKET/certs.pem
rm certs.pem key.pem

# to allow terraform destroy
touch certs.pem
touch key.pem