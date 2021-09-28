resource "google_compute_instance" "zookeeper" {
    name         = "${var.zookeeper-hostname}"
    machine_type = "${var.zookeeper-machine-type}"

    tags = ["zookeeper"]

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
        access_config { }
    }

    metadata_startup_script =   <<EOF

        apt-get -yq install gnupg curl dirmngr apt-transport-https
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
        curl -O https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-2_all.deb
        apt-get -y install ./zulu-repo_1.0.0-2_all.deb
        apt-get update
        apt-get -y install zulu11-jdk

        ZOOK_UID=10000
        ZOOK_GID=10000

        groupadd -g $${ZOOK_GID} zookeeper || groupmod -n zookeeper `getent group $${ZOOK_GID} | cut -d: -f1` \
            && useradd --shell /bin/bash -u $${ZOOK_UID} -g $${ZOOK_GID} -m zookeeper \
            && mkdir -p /opt/zookeeper \
            && mkdir -p /var/lib/zookeeper \
            && echo 1 > /var/lib/zookeeper/myid \
            && chown -R zookeeper:zookeeper /opt/zookeeper \
            && chown -R zookeeper:zookeeper /var/lib/zookeeper

        gsutil cp ${var.nifi_bucket}/apache-zookeeper-${var.zookeeper_version}-bin.tar.gz /opt/zookeeper/.
        chown zookeeper:zookeeper /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin.tar.gz
        su zookeeper -c 'cd /opt/zookeeper/ && tar -xvzf /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin.tar.gz'
        su zookeeper -c 'rm /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin.tar.gz'

        echo "tickTime=2000" > /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin/conf/zoo.cfg
        echo "dataDir=/var/lib/zookeeper" >> /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin/conf/zoo.cfg
        echo "clientPort=2181" >> /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin/conf/zoo.cfg
        chown zookeeper:zookeeper /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin/conf/zoo.cfg

        su zookeeper -c 'cd /home/zookeeper && /opt/zookeeper/apache-zookeeper-${var.zookeeper_version}-bin/bin/zkServer.sh start'

    EOF

}