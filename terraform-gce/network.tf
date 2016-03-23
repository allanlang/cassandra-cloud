resource "google_compute_network" "cassnet" {
    name = "cassnet"
}

resource "google_compute_subnetwork" "public" {
    name = "public"
    ip_cidr_range = "10.0.0.0/24"
    network = "${google_compute_network.cassnet.self_link}"
    region = "europe-west1"
}

resource "google_compute_subnetwork" "private" {
    name = "private"
    ip_cidr_range = "10.0.10.0/24"
    network = "${google_compute_network.cassnet.self_link}"
    region = "europe-west1"
}

resource "google_compute_firewall" "fw-internal-ssh" {
    name = "private-ssh"
    network = "${google_compute_network.cassnet.name}"

    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_tags = ["bastion-host"]
}

resource "google_compute_firewall" "fw-bastion-ssh" {
    name = "bastion-ssh"
    network = "${google_compute_network.cassnet.name}"

    allow {
        protocol = "tcp"
        ports = ["22"]
    }

    source_ranges = ["0.0.0.0/0"]

    target_tags = ["bastion-host"]
}

resource "google_compute_firewall" "fw-nat-tcp" {
    name = "nat-internal"
    network = "${google_compute_network.cassnet.name}"

    allow {
        protocol = "tcp"
    }

    source_tags = ["no-ip"]

    target_tags = ["nat"]
}

resource "google_compute_route" "noip-internet-route" {
    name = "noip-internet-route"
    dest_range = "0.0.0.0/0"
    network = "${google_compute_network.cassnet.name}"
    next_hop_instance = "${google_compute_instance.nat.name}"
    next_hop_instance_zone = "${google_compute_instance.nat.zone}"
    priority = 800
    tags = ["no-ip"]
}

resource "google_compute_firewall" "fw-cassandra-internode" {
    name = "cassandra-internode"
    network = "${google_compute_network.cassnet.name}"

    allow {
        protocol = "tcp"
        ports = ["7000", "9042", "7199"]
    }

    source_tags = ["cassandra-node"]

    target_tags = ["cassandra-node"]
}
