# Terraform / NiFi on Google Cloud

This repository is used to deploy NiFi instances using Terraform on the Google Cloud Platform.

* [gcp-single-secured-nifi-oidc](./gcp-single-secured-nifi-oidc) - Will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy a single secured NiFi instance mapped to a domain
  * configure NiFi to use OpenID connect for authentication
* [gcp-cluster-secured-nifi-oidc](./gcp-cluster-secured-nifi-oidc) - Will:
  * deploy a NiFi CA server as a convenient way to generate SSL certificates
  * deploy an external ZooKeeper instance to manage cluster coordination and state across the nodes
  * deploy X secured NiFi instances clustered together
  * configure NiFi to use OpenID connect for authentication
  * configure an HTTPS load balancer with Client IP affinity in front of the NiFi cluster

