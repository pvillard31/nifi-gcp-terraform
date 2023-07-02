#!/bin/sh

PROJECT=$1
BUCKET=$2

# set project
gcloud config set project $PROJECT

# init terraform
terraform init

touch key.pem
touch certs.pem

# start NiFi CA to generate certificates that will be used for the load balancer
terraform apply -auto-approve -target=google_compute_instance.nifi-ca

# wait until certificates are generated and pushed into GCS
until gsutil ls gs://$BUCKET/certs.pem; do
    echo "Waiting until NiFi CA is started and has generated certs... (sleep 10)"
    sleep 10
done

# copy private key and public certificates locally to configure load balancer
gsutil cp gs://$BUCKET/key.pem .
gsutil cp gs://$BUCKET/certs.pem .

terraform apply -auto-approve

# download keystore, truststore and config for admin identity
gsutil cp gs://$BUCKET/keystore.jks .
gsutil cp gs://$BUCKET/truststore.jks .
gsutil cp gs://$BUCKET/config.json .
gsutil cp gs://pvi-nifi/nifi-toolkit-1.22.0-bin.zip .
unzip nifi-toolkit-1.22.0-bin.zip
rm nifi-toolkit-1.22.0-bin.zip

echo "baseUrl=https://nifi.example.com/" > nifi-cli.properties
echo "keystore=./keystore.jks" >> nifi-cli.properties
echo "keystoreType=JKS" >> nifi-cli.properties
echo "keystorePasswd="$(jq -r '.keyStorePassword' ./config.json) >> nifi-cli.properties
echo "keyPasswd="$(jq -r '.keyPassword' ./config.json) >> nifi-cli.properties
echo "truststore=./truststore.jks" >> nifi-cli.properties
echo "truststoreType=JKS" >> nifi-cli.properties
echo "truststorePasswd="$(jq -r '.trustStorePassword' ./config.json) >> nifi-cli.properties

# delete/clean certs/key
gsutil rm gs://$BUCKET/key.pem
gsutil rm gs://$BUCKET/certs.pem
rm certs.pem key.pem config.json

# to allow terraform destroy
touch certs.pem
touch key.pem