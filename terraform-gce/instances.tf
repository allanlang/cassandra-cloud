resource "google_compute_instance" "bastion" {
    name = "bastion-host"
    machine_type = "f1-micro"
    zone = "europe-west1-b"
    tags = ["bastion-host"]

    disk {
        image = "centos-7-v20160301"
    }

    network_interface {
        subnetwork = "${google_compute_subnetwork.public.name}"
        access_config {
            // Ephemeral IP
        }
    }

    metadata {
        role = "bastion"
    }

}

resource "google_compute_instance" "nat" {
    name = "nat"
    machine_type = "f1-micro"
    zone = "europe-west1-b"
    tags = ["nat"]
    can_ip_forward = true

    metadata_startup_script = "${file("nat-startup.sh")}"

    metadata {
        role = "nat"
    }

    disk {
        image = "debian-7-wheezy-v20160301"
    }

    network_interface {
        subnetwork = "${google_compute_subnetwork.public.name}"
        access_config {
            // Ephemeral IP
        }
    }

}

resource "google_compute_instance" "cassandra-node-seed" {
    name = "cassandra-node-seed"
    machine_type = "n1-standard-2"
    zone = "europe-west1-b"
    tags = ["cassandra-node", "seed", "no-ip"]

    metadata_startup_script = "${file("node-startup.sh")}"

    metadata {
        role = "cassandra-node"
    }

    disk {
        image = "centos-7-v20160301"
    }

    network_interface {
        subnetwork = "${google_compute_subnetwork.private.name}"
    }
	
    disk {
        type = "local-ssd"
        scratch = true
    }

}

resource "google_compute_instance_template" "cassandra-node" {
    name = "cassandra-node"
    description = "Cassandra ring node instance template"
    instance_description = "Cassandra ring node"
    machine_type = "n1-standard-2"
    can_ip_forward = false

    tags = ["cassandra-node", "no-ip"]

    disk {
        source_image = "centos-7-v20160301"
        auto_delete = true
        boot = true
    }

    metadata {
        startup-script = "${file("node-startup.sh")}"
        role = "cassandra-node"
    }

    disk {
        disk_type = "local-ssd"
        type = "SCRATCH"
    }

    network_interface {
        subnetwork = "${google_compute_subnetwork.private.name}"
    }

    scheduling {
        automatic_restart = false
        preemptible = true
    }
	
}

resource "google_compute_instance_group_manager" "node-group" {
    description = "Cassandra node instance group manager"
    name = "cassandra-node-group"
    instance_template = "${google_compute_instance_template.cassandra-node.self_link}"
    update_strategy= "NONE"
    base_instance_name = "cassandra-node"
    zone = "europe-west1-b"
    target_size = 2

    named_port {
        name = "cassandra-internode"
        port = 7000
    }

    named_port {
        name = "cassandra-client"
        port = 9042
    }

    named_port {
        name = "cassandra-jmx"
        port = 7199
    }

}
