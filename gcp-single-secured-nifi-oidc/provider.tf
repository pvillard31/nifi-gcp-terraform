provider "google" {
  credentials = "${file("~/account.json")}"
  project     = var.project
  region      = var.region
  zone        = var.zone
}