variable network_name {
    default = "nifi-network"
}

variable nifi-ca-hostname {
    default = "nifi-ca"
}

variable zookeeper-hostname {
    default = "zookeeper"
}

variable registry-hostname {
    default = "nifi-registry"
}

variable nifi-hostname {
    default = "nifi"
}

variable nifi-basedir {
    default = "/opt/nifi"
}

variable nifi-machine-type {
    default = "e2-highcpu-4"
}

variable nifi-ca-machine-type {
    default = "e2-micro"
}

variable zookeeper-machine-type {
    default = "e2-micro"
}

variable registry-machine-type {
    default = "e2-micro"
}

variable zookeeper_version {
    default = "3.9.3"
}

variable nifi_version {
    default = "2.0.0"
}

variable nifiregistry_version {
    default = "2.0.0"
}

variable nifi_toolkit_version {
    default = "1.28.0"
}

variable "region" {
    default = "europe-west1"
}

variable "zone" {
    default = "europe-west1-d"
}

// ---------------------------------

variable "project" {
    description = "GCP Project ID"
}

variable nifi-admin {
    description = "Google mail address for the user that will be the initial admin in NiFi"
}

variable san {
    description = "FQDN of the DNS mapping that will be used to access NiFi. Example: nifi.example.com"
}

variable san-registry {
    description = "FQDN of the DNS mapping that will be used to access NiFi Registry. Example: nifiregistry.example.com"
}

variable proxyhost {
    description = "FQDN:port that will be used to access NiFi. Example: nifi.example.com:8443"
}

variable ca_token {
    description = "The token to use to prevent MITM between the NiFi CA client and the NiFi CA server (must be at least 16 bytes long)"
}

variable oauth_clientid {
    description = "OAuth Client ID"
}

variable oauth_secret {
    description = "OAuth Client secret"
}

variable "instance_count" {
    description = "Number of NiFi instances"
}

variable nifi_bucket {
    description = "GCS path to the bucket containing the binaries (ex: gs://nifi_bin)"
}

variable sensitivepropskey {
    description = "Key that will be used for encrypting the sensitive properties in the flow definition (ex: ThisIsAVeryBadPass3word)"
}

variable cloudflare_dns_api_token {
	description = "Cloudflare DNS API Token for the Let's encrypt challenge when generating certificates"
}

variable cloudflare_api_key {
	description = "Cloudflare API Key to update the DNS records"
}

variable cloudflare_zone_id {
	description = "Cloudflare Zone ID for the DNS updates"
}

variable cloudflare_record_name {
	description = "Cloudflare record name for NiFi"
}