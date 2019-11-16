resource "google_compute_instance" "nifi-ca" {
    name         = "${var.nifi-ca-hostname}"
    machine_type = "${var.nifi-ca-machine-type}"

    tags = ["nifi-ca"]

    service_account {
        scopes = ["storage-rw"]
    }
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network            = "${google_compute_subnetwork.default.name}"
        subnetwork         = "${google_compute_subnetwork.default.name}"
        access_config { }
    }

    metadata_startup_script =   <<EOF

        apt-get update && apt-get install openjdk-8-jdk unzip jq -y

        NIFI_UID=10000
        NIFI_GID=10000

        groupadd -g $${NIFI_GID} nifi || groupmod -n nifi `getent group $${NIFI_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${NIFI_UID} -g $${NIFI_GID} -m nifi \
            && mkdir -p ${var.nifi-basedir} \
            && chown -R nifi:nifi ${var.nifi-basedir}

        gsutil cp ${var.nifi_bucket}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip ${var.nifi-basedir}/.
        chown nifi:nifi ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip
        su nifi -c 'unzip ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip -d ${var.nifi-basedir}'
        su nifi -c 'rm ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip'
        su nifi -c 'cd /home/nifi && ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}/bin/tls-toolkit.sh server -c ${var.nifi-ca-hostname} -t ${var.ca_token} &'

        sleep 5

        cd /root
        ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}/bin/tls-toolkit.sh client -D CN=nifi-lb,OU=NIFI -c ${var.nifi-ca-hostname} --subjectAlternativeNames ${var.san} -t ${var.ca_token}
        KEYSTORE_PASSWORD=`jq -r '.keyStorePassword' /root/config.json`
        KEY_PASSWORD=`jq -r '.keyPassword' /root/config.json`

        keytool -importkeystore -srckeystore keystore.jks -destkeystore keystore.p12 -srcstoretype jks -deststoretype pkcs12 -deststorepass $KEYSTORE_PASSWORD -srcstorepass $KEYSTORE_PASSWORD
        openssl pkcs12 -in keystore.p12 -out key.pem -nodes -passin pass:$KEYSTORE_PASSWORD -nocerts
        openssl pkcs12 -in keystore.p12 -out certs.pem -nodes -passin pass:$KEYSTORE_PASSWORD -nokeys

        gsutil cp key.pem ${var.nifi_bucket}/key.pem
        gsutil cp certs.pem ${var.nifi_bucket}/certs.pem
        
        rm nifi-cert.pem truststore.jks keystore.jks keystore.p12 key.pem certs.pem config.json

    EOF

}