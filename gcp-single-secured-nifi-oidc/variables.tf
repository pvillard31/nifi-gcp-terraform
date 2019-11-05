variable network_name {
    default = "nifi-network"
}

variable nifi-ca-hostname {
    default = "nifi-ca"
}

variable nifi-hostname {
    default = "nifi"
}

variable nifi-basedir {
    default = "/opt/nifi"
}

variable nifi-machine-type {
    default = "n1-highcpu-4"
}

variable nifi-ca-machine-type {
    default = "f1-micro"
}

variable nifi_version {
    default = "1.10.0"
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
    description = "FQDN of the DNS mapping for that will be used to access NiFi. Example: nifi.example.com"
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
