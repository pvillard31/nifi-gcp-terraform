# Terraform / NiFi on Google Cloud

This repository is used to deploy NiFi instances using Terraform on the Google Cloud Platform.

* [gcp-single-secured-nifi-oidc](./gcp-single-secured-nifi-oidc) - Will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy a single secured NiFi instance mapped to a domain
  * configure NiFi to use OpenID connect for authentication
