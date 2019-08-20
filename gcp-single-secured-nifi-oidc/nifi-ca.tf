resource "google_compute_instance" "nifi-ca" {
    name         = "${var.nifi-ca-hostname}"
    machine_type = "f1-micro"

    tags = ["nifi-ca"]
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network            = "${google_compute_subnetwork.default.name}"
        subnetwork         = "${google_compute_subnetwork.default.name}"
        // access_config { } // uncomment to generate ephemeral external IP
    }

    metadata_startup_script =   <<EOF
        apt-get install openjdk-8-jdk -y && \
        wget https://www-eu.apache.org/dist/nifi/${var.nifi_version}/nifi-toolkit-${var.nifi_version}-bin.tar.gz && \
        tar -xvzf nifi-toolkit-${var.nifi_version}-bin.tar.gz && \
        /nifi-toolkit-${var.nifi_version}/bin/tls-toolkit.sh server -c ${var.nifi-ca-hostname} -t ${var.ca_token} &
    EOF

}