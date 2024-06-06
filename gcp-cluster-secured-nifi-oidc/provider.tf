provider "google" {
  credentials = "${file("~/account.json")}"
  project     = var.project
  region      = var.region
  zone        = var.zone
}

terraform {
  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.0"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

provider "acme" {
  #server_url = "https://acme-v02.api.letsencrypt.org/directory" # THIS IS FOR PRODUCTION
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory" # THIS IS FOR TESTING
}

provider "cloudflare" {
  email     = "${var.nifi-admin}"
  api_key   = var.cloudflare_api_key
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "${var.nifi-admin}"
}

resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "${var.san}"
  subject_alternative_names = ["${var.san}"]

  dns_challenge {
    provider = "cloudflare"

    config = {
      CF_DNS_API_TOKEN     = var.cloudflare_dns_api_token
    }
  }
}