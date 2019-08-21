resource "google_compute_instance" "nifi-ca" {
    name         = "${var.nifi-ca-hostname}"
    machine_type = "${var.nifi-ca-machine-type}"

    tags = ["nifi-ca"]
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network            = "${google_compute_subnetwork.default.name}"
        subnetwork         = "${google_compute_subnetwork.default.name}"
        access_config { } // uncomment to generate ephemeral external IP
    }

    metadata_startup_script =   <<EOF

        apt-get update && apt-get install openjdk-8-jdk unzip -y

        NIFI_UID=10000
        NIFI_GID=10000

        groupadd -g $${NIFI_GID} nifi || groupmod -n nifi `getent group $${NIFI_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${NIFI_UID} -g $${NIFI_GID} -m nifi \
            && mkdir -p ${var.nifi-basedir} \
            && chown -R nifi:nifi ${var.nifi-basedir}

        su nifi -c 'curl -fSL https://www-eu.apache.org/dist/nifi/${var.nifi_version}/nifi-toolkit-${var.nifi_version}-bin.zip -o ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip'
        su nifi -c 'unzip ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip -d ${var.nifi-basedir}'
        su nifi -c 'rm ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip'
        su nifi -c 'cd /home/nifi && ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}/bin/tls-toolkit.sh server -c ${var.nifi-ca-hostname} -t ${var.ca_token}'

    EOF

}