resource "aws_vpc" "vpc" {
	cidr_block = "10.0.0.0/16"
	tags {
		Name = "vpc-cassandra"
	}
}

resource "aws_subnet" "subnet-public-A" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.1.0/24"
	availability_zone = "eu-west-1a"
	map_public_ip_on_launch = true
	tags {
		Name = "subnet-public-A"
	}
}

resource "aws_subnet" "subnet-private-A" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.10.0/24"
	availability_zone = "eu-west-1a"
	map_public_ip_on_launch = false
	tags {
		Name = "subnet-private-A"
	}
}

resource "aws_subnet" "subnet-public-B" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.2.0/24"
	availability_zone = "eu-west-1b"
	map_public_ip_on_launch = true
	tags {
		Name = "subnet-public-B"
	}
}

resource "aws_subnet" "subnet-private-B" {
	vpc_id = "${aws_vpc.vpc.id}"
	cidr_block = "10.0.20.0/24"
	availability_zone = "eu-west-1b"
	map_public_ip_on_launch = false
	tags {
		Name = "subnet-private-B"
	}
}

resource "aws_internet_gateway" "igw" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "igw"
    }
}

resource "aws_route_table" "route-table-public" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.igw.id}"
    }
    tags {
        Name = "public-route"
    }
}

resource "aws_route_table" "route-table-private" {
    vpc_id = "${aws_vpc.vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_nat_gateway.nat.id}"
    }
    tags {
        Name = "private-route"
    }
}

resource "aws_route_table_association" "apA" {
    subnet_id = "${aws_subnet.subnet-public-A.id}"
    route_table_id = "${aws_route_table.route-table-public.id}"
}

resource "aws_route_table_association" "apB" {
    subnet_id = "${aws_subnet.subnet-public-B.id}"
    route_table_id = "${aws_route_table.route-table-public.id}"
}

resource "aws_route_table_association" "apvA" {
    subnet_id = "${aws_subnet.subnet-private-A.id}"
    route_table_id = "${aws_route_table.route-table-private.id}"
}

resource "aws_route_table_association" "apvB" {
    subnet_id = "${aws_subnet.subnet-private-B.id}"
    route_table_id = "${aws_route_table.route-table-private.id}"
}
