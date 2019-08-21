resource "google_compute_address" "static" {
    name = "nifi-static-address"
}

resource "google_compute_instance" "nifi" {
    name         = "${var.nifi-hostname}"
    machine_type = "${var.nifi-machine-type}"

    depends_on = [google_compute_instance.nifi-ca]

    tags = ["nifi"]
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network            = "${google_compute_subnetwork.default.name}"
        subnetwork         = "${google_compute_subnetwork.default.name}"
        access_config {
            nat_ip = "${google_compute_address.static.address}"
        }
    }

    metadata_startup_script =   <<EOF

        apt-get update && apt-get install openjdk-8-jdk unzip jq -y

        NIFI_UID=10000
        NIFI_GID=10000

        groupadd -g $${NIFI_GID} nifi || groupmod -n nifi `getent group $${NIFI_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${NIFI_UID} -g $${NIFI_GID} -m nifi \
            && mkdir -p ${var.nifi-basedir} \
            && chown -R nifi:nifi ${var.nifi-basedir}

        su nifi -c 'curl -fSL https://www-eu.apache.org/dist/nifi/${var.nifi_version}/nifi-toolkit-${var.nifi_version}-bin.zip -o ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip'
        su nifi -c 'unzip ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip -d ${var.nifi-basedir}'
        su nifi -c 'rm ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}-bin.zip'

        su nifi -c 'curl -fSL https://www-eu.apache.org/dist/nifi/${var.nifi_version}/nifi-${var.nifi_version}-bin.zip -o ${var.nifi-basedir}/nifi-${var.nifi_version}-bin.zip'
        su nifi -c 'unzip ${var.nifi-basedir}/nifi-${var.nifi_version}-bin.zip -d ${var.nifi-basedir}'
        su nifi -c 'rm ${var.nifi-basedir}/nifi-${var.nifi_version}-bin.zip'

        su nifi -c 'cd /home/nifi && ${var.nifi-basedir}/nifi-toolkit-${var.nifi_version}/bin/tls-toolkit.sh client -c ${var.nifi-ca-hostname} -t ${var.ca_token} --subjectAlternativeNames ${var.san}'

        prop_replace () {
            sed -i -e "s|^$1=.*$|$1=$2|"  $3
        }

        NIFI_CONFIG_FILE="${var.nifi-basedir}/nifi-${var.nifi_version}/conf/nifi.properties"
        NIFI_AUTHZ_FILE="${var.nifi-basedir}/nifi-${var.nifi_version}/conf/authorizers.xml"

        KEYSTORE_PASSWORD=`jq -r '.keyStorePassword' /home/nifi/config.json`
        KEY_PASSWORD=`jq -r '.keyPassword' /home/nifi/config.json`
        TRUSTSTORE_PASSWORD=`jq -r '.trustStorePassword' /home/nifi/config.json`

        prop_replace 'nifi.security.keystore'           "/home/nifi/keystore.jks"               "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.keystoreType'       "JKS"                                   "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.keystorePasswd'     "$${KEYSTORE_PASSWORD}"                 "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.keyPasswd'          "$${KEY_PASSWORD}"                      "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.truststore'         "/home/nifi/truststore.jks"             "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.truststoreType'     "JKS"                                   "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.truststorePasswd'   "$${TRUSTSTORE_PASSWORD}"               "$${NIFI_CONFIG_FILE}"

        prop_replace 'nifi.web.proxy.host'              '${var.proxyhost}'                      "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.web.http.port'               ''                                      "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.web.http.host'               ''                                      "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.web.https.port'              "$${NIFI_WEB_HTTPS_PORT:-8443}"         "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.web.https.host'              "$${NIFI_WEB_HTTPS_HOST:-$HOSTNAME}"    "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.remote.input.secure'         'true'                                  "$${NIFI_CONFIG_FILE}"

        prop_replace 'nifi.security.user.oidc.discovery.url'        'https://accounts.google.com/.well-known/openid-configuration'      "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.user.oidc.client.id'            '${var.oauth_clientid}'                                             "$${NIFI_CONFIG_FILE}"
        prop_replace 'nifi.security.user.oidc.client.secret'        '${var.oauth_secret}'                                               "$${NIFI_CONFIG_FILE}"

        sed -i -e 's|<property name="Initial User Identity 1"></property>|<property name="Initial User Identity 1">'"${var.nifi-admin}"'</property>|'   $${NIFI_AUTHZ_FILE}
        sed -i -e 's|<property name="Initial Admin Identity"></property>|<property name="Initial Admin Identity">'"${var.nifi-admin}"'</property>|'     $${NIFI_AUTHZ_FILE}

        su nifi -c 'cd /home/nifi && ${var.nifi-basedir}/nifi-${var.nifi_version}/bin/nifi.sh start'

    EOF

}