 # Terraform on GCP - secured NiFi cluster with external ZooKeeper and secured NiFi Registry

Step-by-step guide to start a secured NiFi cluster configured with OpenID Connect using Terraform on the Google Cloud Platform. Please refer to the [Medium post](https://medium.com/@pierre.villard/secured-nifi-cluster-with-terraform-on-the-google-cloud-platform-58c0ca6624d7) to get more details.

It will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy an external ZooKeeper instance to manage cluster coordination and state across the nodes
  * deploy one secured instance of the NiFi Registry configured with OIDC
  * deploy X secured NiFi instances clustered together
  * configure NiFi to use OpenID connect for authentication
  * configure an HTTPS load balancer with Client IP affinity in front of the NiFi cluster

````
git clone https://github.com/pvillard31/nifi-gcp-terraform.git
cd nifi-gcp-terraform/gcp-cluster-secured-nifi-oidc/
/bin/sh deploy.sh <projectID> <bucket>
````

Requirements:
  * you need to have a file ``~/account.json`` with the key of the service account that will be used to perform the deployment
  * you need to have nifi-1.15.0-bin.zip, nifi-registry-1.15.0-bin.zip, nifi-toolkit-1.15.0-bin.zip and apache-zookeeper-3.6.3-bin.tar.gz in the configured GCS bucket

Variables to update in ``variables.tf`` **before**:

* **project** // GCP Project ID
* **nifi-admin** // Google mail address for the user that will be the initial admin in NiFi
* **san** // FQDN of the DNS mapping for that will be used to access NiFi. Example: nifi.example.com
* **san-registry** // FQDN of the DNS mapping that will be used to access NiFi Registry. Example: nifiregistry.example.com
* **proxyhost** // FQDN:port that will be used to access NiFi. Example: nifi.example.com:8443
* **ca_token** // The token to use to prevent MITM between the NiFi CA client and the NiFi CA server (must be at least 16 bytes long) (ex: ThisIsAVeryBadPass3word)
* **oauth_clientid** // OAuth Client ID
* **oauth_secret** // OAuth Client secret
* **instance_count** // Number of NiFi instances to create
* **nifi_bucket** // GCS path to the bucket containing the binaries (ex: gs://nifi_bin)
* **sensitivepropskey** // Key that will be used for encrypting the sensitive properties in the flow definition (ex: ThisIsAVeryBadPass3word)

Once you are done, you can execute:

````
terraform destroy
````
