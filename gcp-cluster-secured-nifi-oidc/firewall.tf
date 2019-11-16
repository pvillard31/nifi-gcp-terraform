resource "google_compute_firewall" "allow-ssh" {
    
    name    = "allow-ssh"
    network = "${google_compute_subnetwork.default.name}"

    allow {
        protocol = "tcp"
        ports    = ["22"]
    }

}

resource "google_compute_firewall" "allow-internal" {
    
    name    = "allow-internal"
    network = "${google_compute_subnetwork.default.name}"

    allow {
        protocol = "icmp"
    }

    allow {
        protocol = "tcp"
        ports    = ["0-65535"]
    }

    allow {
        protocol = "udp"
        ports    = ["0-65535"]
    }

    source_ranges = [
        "${google_compute_subnetwork.default.ip_cidr_range}"
    ]

}

resource "google_compute_firewall" "allow-https" {
    
    name    = "allow-https"
    network = "${google_compute_subnetwork.default.name}"

    allow {
        protocol = "tcp"
        ports    = ["8443"]
    }

    target_tags  = ["nifi"]

}
