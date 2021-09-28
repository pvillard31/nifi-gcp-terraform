resource "google_compute_address" "static" {
    name = "nifi-registry"
}

resource "google_compute_instance" "nifi-registry" {
    name         = "${var.registry-hostname}"
    machine_type = "${var.registry-machine-type}"

    depends_on = [google_compute_instance.nifi-ca]

    tags = ["nifi"]

    service_account {
        scopes = ["storage-ro"]
    }
    
    boot_disk {
        initialize_params {
            image = "debian-cloud/debian-9"
        }
    }

    network_interface {
        network            = "${google_compute_subnetwork.default.name}"
        subnetwork         = "${google_compute_subnetwork.default.name}"
        access_config {
            nat_ip = google_compute_address.static.address
        }
    }

    metadata_startup_script =   <<EOF

        apt-get update && apt-get install unzip jq -y

        apt-get -yq install gnupg curl dirmngr apt-transport-https
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
        curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
        apt-get -y install ./zulu-repo_1.0.0-2_all.deb
        apt-get update
        apt-get -y install zulu11-jdk

        NIFIREGISTRY_UID=10000
        NIFIREGISTRY_GID=10000

        groupadd -g $${NIFIREGISTRY_GID} nifiregistry || groupmod -n nifiregistry `getent group $${NIFIREGISTRY_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${NIFIREGISTRY_UID} -g $${NIFIREGISTRY_GID} -m nifiregistry \
            && mkdir -p ${var.nifi-basedir} \
            && chown -R nifiregistry:nifiregistry ${var.nifi-basedir}

        gsutil cp ${var.nifi_bucket}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip ${var.nifi-basedir}/.
        chown nifiregistry:nifiregistry ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip
        su nifiregistry -c 'unzip ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip -d ${var.nifi-basedir}'
        su nifiregistry -c 'rm ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}-bin.zip'

        gsutil cp ${var.nifi_bucket}/nifi-registry-${var.nifiregistry_version}-bin.zip ${var.nifi-basedir}/.
        chown nifiregistry:nifiregistry ${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}-bin.zip
        su nifiregistry -c 'unzip ${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}-bin.zip -d ${var.nifi-basedir}'
        su nifiregistry -c 'rm ${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}-bin.zip'

        su nifiregistry -c 'cd /home/nifiregistry && ${var.nifi-basedir}/nifi-toolkit-${var.nifi_toolkit_version}/bin/tls-toolkit.sh client -c ${var.nifi-ca-hostname} -t ${var.ca_token} --subjectAlternativeNames ${var.san-registry}'

        prop_replace () {
            sed -i -e "s|^$1=.*$|$1=$2|"  $3
        }

        NIFIREGISTRY_CONFIG_FILE="${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}/conf/nifi-registry.properties"
        NIFIREGISTRY_AUTHZ_FILE="${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}/conf/authorizers.xml"

        KEYSTORE_PASSWORD=`jq -r '.keyStorePassword' /home/nifiregistry/config.json`
        KEY_PASSWORD=`jq -r '.keyPassword' /home/nifiregistry/config.json`
        TRUSTSTORE_PASSWORD=`jq -r '.trustStorePassword' /home/nifiregistry/config.json`

        prop_replace 'nifi.registry.security.keystore'                      "/home/nifiregistry/keystore.jks"                                   "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.keystoreType'                  "JKS"                                                               "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.keystorePasswd'                "$${KEYSTORE_PASSWORD}"                                             "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.keyPasswd'                     "$${KEY_PASSWORD}"                                                  "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.truststore'                    "/home/nifiregistry/truststore.jks"                                 "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.truststoreType'                "JKS"                                                               "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.truststorePasswd'              "$${TRUSTSTORE_PASSWORD}"                                           "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.needClientAuth'                "false"                                                             "$${NIFIREGISTRY_CONFIG_FILE}"

        prop_replace 'nifi.registry.web.http.host'                          ''                                                                  "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.web.http.port'                          ''                                                                  "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.web.https.port'                         "$${NIFI_REGISTRY_WEB_HTTPS_PORT:-18443}"                           "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.web.https.host'                         "$${NIFI_REGISTRY_WEB_HTTPS_HOST:-$HOSTNAME}"                       "$${NIFIREGISTRY_CONFIG_FILE}"

        prop_replace 'nifi.registry.security.user.oidc.discovery.url'       'https://accounts.google.com/.well-known/openid-configuration'      "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.user.oidc.client.id'           '${var.oauth_clientid}'                                             "$${NIFIREGISTRY_CONFIG_FILE}"
        prop_replace 'nifi.registry.security.user.oidc.client.secret'       '${var.oauth_secret}'                                               "$${NIFIREGISTRY_CONFIG_FILE}"

        sed -i -e 's|# nifi.registry.security.identity.mapping.pattern.dn=.*|nifi.registry.security.identity.mapping.pattern.dn=CN=(.*), OU=.*|'                        $${NIFIREGISTRY_CONFIG_FILE}
        sed -i -e 's|# nifi.registry.security.identity.mapping.value.dn=.*|nifi.registry.security.identity.mapping.value.dn=$1|'                                        $${NIFIREGISTRY_CONFIG_FILE}
        sed -i -e 's|# nifi.registry.security.identity.mapping.transform.dn=NONE|nifi.registry.security.identity.mapping.transform.dn=NONE|'                            $${NIFIREGISTRY_CONFIG_FILE}

        sed -i -e 's|<property name="Initial User Identity 1">.*</property>|<property name="Initial User Identity 0">'"${var.nifi-admin}"'</property>|'                 $${NIFIREGISTRY_AUTHZ_FILE}
        sed -i -e 's|<property name="Initial Admin Identity">.*</property>|<property name="Initial Admin Identity">'"${var.nifi-admin}"'</property>|'                   $${NIFIREGISTRY_AUTHZ_FILE}

        sed -i -e 's|<!--<property name="NiFi Identity 1"></property>-->|<property name="NiFi Identity 1">'"${var.nifi-hostname}-1"'</property>|'                       $${NIFIREGISTRY_AUTHZ_FILE}
        for i in $(seq 2 ${var.instance_count}); do
            sed -i -e '/<property name="NiFi Identity 1">.*/a <property name="NiFi Identity '"$i"'">'"${var.nifi-hostname}-$i"'</property>'                             $${NIFIREGISTRY_AUTHZ_FILE}
        done

        for i in $(seq 1 ${var.instance_count}); do
            sed -i -e '/<property name="Initial User Identity 0">.*/a <property name="Initial User Identity '"$i"'">'"${var.nifi-hostname}-$i"'</property>'             $${NIFIREGISTRY_AUTHZ_FILE}
        done
      
        su nifiregistry -c 'cd /home/nifiregistry && ${var.nifi-basedir}/nifi-registry-${var.nifiregistry_version}/bin/nifi-registry.sh start'

    EOF

}