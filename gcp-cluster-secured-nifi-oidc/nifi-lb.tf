resource "google_compute_instance_group" "nifi-ig" {
    name        = "nifi-ig"
    description = "Instance group for NiFi instances"
    network     = "${google_compute_network.default.self_link}"
    instances   = "${google_compute_instance.nifi.*.self_link}"
    
    named_port {
        name    = "https"
        port    = "8443"
    }

    zone        = "${var.zone}"
}

resource "google_compute_https_health_check" "nifi-healthcheck" {
    name            = "nifi-healthcheck"
    request_path    = "/"
    port            = "8443"
}

resource "google_compute_backend_service" "nifi-backend" {
    name                = "nifi-backend"
    protocol            = "HTTPS"
    port_name           = "https"
    session_affinity    = "CLIENT_IP"
    health_checks       = ["${google_compute_https_health_check.nifi-healthcheck.self_link}"]
    backend {
        group           = "${google_compute_instance_group.nifi-ig.self_link}"
    }
}

resource "google_compute_ssl_certificate" "nifi-lb-cert" {
  name          = "nifi-lb-cert"
  private_key   = "${file("key.pem")}"
  certificate   = "${file("certs.pem")}"
}

resource "google_compute_target_https_proxy" "nifi-target-proxy" {
  name             = "nifi-target-proxy"
  url_map          = "${google_compute_url_map.nifi-url-map.self_link}"
  ssl_certificates = ["${google_compute_ssl_certificate.nifi-lb-cert.self_link}"]
}

resource "google_compute_url_map" "nifi-url-map" {
  name              = "nifi-url-map"
  default_service   = "${google_compute_backend_service.nifi-backend.self_link}"
}

resource "google_compute_global_forwarding_rule" "nifi-lb" {
  name                  = "nifi-lb"
  target                = "${google_compute_target_https_proxy.nifi-target-proxy.self_link}"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
  port_range            = "443"
}
