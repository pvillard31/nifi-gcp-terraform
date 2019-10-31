 # Terraform on GCP - NiFi CA + NiFi with OIDC

Step-by-step guide to start a secured NiFi instance configured with OpenID Connect using Terraform on the Google Cloud Platform. Please refer to the [Medium post](https://medium.com/@pierre.villard/nifi-with-oidc-using-terraform-on-the-google-cloud-platform-8686ac247ee9) to get more details.

It will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy a single secured NiFi instance mapped to a domain
  * configure NiFi to use OpenID connect for authentication

````
git clone https://github.com/pvillard31/nifi-gcp-terraform.git
cd nifi-gcp-terraform/gcp-single-secured-nifi-oidc/
terraform init
terraform apply
````

Variables to provide:

* **project** // GCP Project ID
* **nifi-admin** // Google mail address for the user that will be the initial admin in NiFi
* **san** // FQDN of the DNS mapping for that will be used to access NiFi. Example: nifi.example.com
* **proxyhost** // FQDN:port that will be used to access NiFi. Example: nifi.example.com:8443
* **ca_token** // The token to use to prevent MITM between the NiFi CA client and the NiFi CA server (must be at least 16 bytes long)
* **oauth_clientid** // OAuth Client ID
* **oauth_secret** // OAuth Client secret
