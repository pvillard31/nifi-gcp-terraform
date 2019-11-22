 # Terraform on GCP - secured NiFi cluster with external ZooKeeper

Step-by-step guide to start a secured NiFi cluster configured with OpenID Connect using Terraform on the Google Cloud Platform. Please refer to the [Medium post](https://medium.com/@pierre.villard/secured-nifi-cluster-with-terraform-on-the-google-cloud-platform-58c0ca6624d7) to get more details.

It will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy an external ZooKeeper instance to manage cluster coordination and state across the nodes
  * deploy X secured NiFi instances clustered together
  * configure NiFi to use OpenID connect for authentication
  * configure an HTTPS load balancer with Client IP affinity in front of the NiFi cluster

````
git clone https://github.com/pvillard31/nifi-gcp-terraform.git
cd nifi-gcp-terraform/gcp-cluster-secured-nifi-oidc/
/bin/sh deploy.sh <projectID> <bucket>
````

Variables to update in ``variables.tf`` **before**:

* **project** // GCP Project ID
* **nifi-admin** // Google mail address for the user that will be the initial admin in NiFi
* **san** // FQDN of the DNS mapping for that will be used to access NiFi. Example: nifi.example.com
* **proxyhost** // FQDN:port that will be used to access NiFi. Example: nifi.example.com:8443
* **ca_token** // The token to use to prevent MITM between the NiFi CA client and the NiFi CA server (must be at least 16 bytes long)
* **oauth_clientid** // OAuth Client ID
* **oauth_secret** // OAuth Client secret
* **instance_count** // Number of NiFi instances to create
* **nifi_bucket** // GCS path to the bucket containing the binaries (ex: gs://nifi_bin)
