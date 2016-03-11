resource "aws_eip" "nat" {
    vpc = true
}

resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.nat.id}"
    subnet_id = "${aws_subnet.subnet-public-A.id}"
    depends_on = ["aws_internet_gateway.igw"]
}

resource "aws_launch_configuration" "node_conf" {
    name = "node_launch_config"
    image_id = "${var.amis.amzn-ami}"
    instance_type = "${var.misc.node-type}"
    spot_price = "0.05"
    security_groups = ["${aws_security_group.cassandra-internode.id}","${aws_security_group.bastion-ingress.id}"]
    key_name = "SpotInstanceKeyPair"
}

resource "aws_autoscaling_group" "cassandra-spot-nodes" {
    vpc_zone_identifier = ["${aws_subnet.subnet-private-A.id}"]
    name = "cassandra-autoscaling"
    launch_configuration = "${aws_launch_configuration.node_conf.name}"
    max_size = 3
    min_size = 3
    tag {
        key = "Name"
        value = "Cassandra Node"
        propagate_at_launch = true
    }
    tag {
        key = "role"
        value = "cassandra-node"
        propagate_at_launch = true
    }
    tag {
        key = "environment"
        value = "cassandra"
        propagate_at_launch = true
    }
}

resource "aws_instance" "cassandra-seed" {
	ami = "${var.amis.amzn-ami}"
	instance_type = "${var.misc.node-type}"
	subnet_id = "${aws_subnet.subnet-private-A.id}"
	key_name = "SpotInstanceKeyPair"
	vpc_security_group_ids = ["${aws_security_group.cassandra-internode.id}","${aws_security_group.bastion-ingress.id}"]
	tags {
		Name = "Cassandra Node"
		role = "cassandra-node"
		seed = "yes"
		environment = "cassandra"
	}
}

resource "aws_instance" "bastion" {
	ami = "${var.amis.amzn-ami}"
	instance_type = "t2.nano"
	subnet_id = "${aws_subnet.subnet-public-A.id}"
	key_name = "SpotInstanceKeyPair"
	vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
	tags {
		Name = "Bastion Host"
		Role = "bastion"
		environment = "cassandra"
	}
}

resource "aws_security_group" "bastion" {
	name = "bastion-host-sg"
	description = "Allow inbound SSH connections on standard port"
	vpc_id = "${aws_vpc.vpc.id}"
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
	tags {
		Name = "Bastion Host SG"
	}
}

resource "aws_security_group" "cassandra-internode" {
	name = "cassandra-internode-sg"
	description = "Allow inter-node communication on standard ports"
	vpc_id = "${aws_vpc.vpc.id}"
	ingress {
		from_port = 7000
		to_port = 7000
		protocol = "tcp"
		self = true
	}
	ingress {
		from_port = 9042
		to_port = 9042
		protocol = "tcp"
		self = true
	}
	ingress {
		from_port = 7199
		to_port = 7199
		protocol = "tcp"
		self = true
	}
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
	tags {
		Name = "Cassandra internode"
	}
}

resource "aws_security_group" "bastion-ingress" {
	name = "bastion-ingress-sg"
	description = "Allow inbound SSH from bastion servers"
	vpc_id = "${aws_vpc.vpc.id}"
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		security_groups = ["${aws_security_group.bastion.id}"]
	}
	tags {
		Name = "Bastion SSH ingress"
	}
}