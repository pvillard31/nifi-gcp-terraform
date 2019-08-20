variable "project" {
    default = "nifi-dev-project"
}

variable "region" {
    default = "europe-west1"
}

variable "zone" {
    default = "europe-west1-d"
}

variable network_name {
  default = "nifi-network"
}

variable nifi_version {
  default = "1.9.2"
}

variable nifi-ca-hostname {
  default = "nifi-ca"
}

variable nifi-hostname {
  default = "nifi"
}

variable nifi-admin {
  default = "admin@pierrevillard.com"
}

variable san {
  default = "nifi.pierrevillard.com"
}

variable proxyhost {
  default = "nifi.pierrevillard.com:8443"
}


// ---------------------------------
// Should be managed with Google KMS // TODO

variable ca_token {
  default = "ThisIsAVeryBadToken"
}

variable oauth_clientid {
  default = "578021925232-jp57srf2jr3nchc4mpa3e985ot5if5eq.apps.googleusercontent.com"
}

variable oauth_secret {
  default = "-gUemdA2NpaJ8I9CwjYkB1Rn"
}