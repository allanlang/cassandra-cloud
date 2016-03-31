# cassandra-cloud
Deploy Cassandra to various cloud environments with automation

## Vagrant

To deploy on Vagrant:

You will need vagrant and virtualbox installed, and internet access in order to download box files. Then:

    vagrant up
    ansible-playbook -i inventory-vagrant.txt main.yml

## Amazon Web Services (AWS)

To deploy on AWS:

You will need account credentials with privileges to create VPCs and EC2 instances. You will need terraform installed, with the necessary dependencies.

You will also need:

`terraform-aws/credentials.tf` looking something like this:

    provider "aws" {
        access_key = "YOUR ACCESS KEY"
        secret_key = "YOUR SECRET ACCESS KEY"
        region = "TARGET REGION"
    }

You should also set your credentials in the AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID environment variables, and `ssh-add` your AWS private key before running the `inv-gen-aws.sh` script or playbooks.

    cd terraform
    terraform apply
    cd ..
    ruby inv-gen-aws.sh > inventory-aws.txt
    ansible -i inventory-aws.txt -m ping all
    ansible-playbook -i inventory-aws.txt main.yml

The terraform script will provision:

- 1x new VPC
- 2x public subnets across two AZs
- 2x private subnets across two AZs
- 1x on-demand t2.nano bastion host in a public subnet
- 1x on-demand m4.xlarge cassandra seed node in a private subnet
- 3x spot m4.xlarge cassandra seed instances in a private subnet

*You will be charged* for the above resources. Spot instances are used to minimise the cost and you may adjust the instance types as required in `terraform-aws/variables.tf`.

## Google Compute Engine (GCE)

To deploy on GCE:

You will need account credentials with privileges to create VPCs and EC2 instances. You will need terraform installed, with the necessary dependencies. You will need the gcloud CLI installed and logged in to your account and project in order to use the inventory generation facility.

You will also need:

`terraform-gce\credentials.tf` looking something like this:

    provider "google" {
      credentials = "${file("PATH_TO_CREDENTIALS.json")}"
      project     = "PROJECT_ID"
      region      = "PROJECT_ZONE"
    }

Create the necessary environment using:

    cd terraform-gce
    terraform apply
    cd ..
    ruby inv-gen-gce.rb > inventory-gce.txt
    ansible -i inventory-gce.txt -m ping all
    ansible-playbook -i inventory-gce.txt main.yml
	
The terraform script will provision:

- 1x new network called `cassandra`
- 2x subnetworks called `private` and `public`
- 1x non-preemptible f1-micro bastion host in the public subnetwork
- 1x non-preemptible f1-micro nat host in the public subnetwork
- 1x non-preemptible n1-standard-2 cassandra seed node in the private subnetwork with local SSD storage
- 2x preemptible cassandra nodes in the private subnetwork with local SSD storage

*You will be charged* for the above resources. Preemptible instances are used to minimise the cost and you may adjust the instance types as required by modifying the appropriate `.tf` files.

## Checking Cassandra cluster status

SSH to one of the cassandra nodes (shouldn't matter which) either directly (for Vagrant):

    vagrant ssh node1

or via the bastion host, for AWS:

    ssh-add PATH_TO_SSH_KEY
    ssh -A ec2-user@BASTION_PUBLIC_IP
    ssh NODE_IP

or via the bastion host, for GCE:

    ssh-add PATH_TO_SSH_KEY
    ssh -A cassandra@BASTION_PUBLIC_IP
    ssh NODE_IP

Once connected, switch to the cassandra user (if not already) then:

    cd /opt/cassandra/apache-cassandra-3.3
    bin/nodetool status

You should hopefully see all of the nodes as members of the cluster, similar to the following:

    [cassandra@cassandra-node-seed apache-cassandra-3.3]$ bin/nodetool status
    Datacenter: europe-west1
    ========================
    Status=Up/Down
    |/ State=Normal/Leaving/Joining/Moving
    --  Address    Load       Tokens       Owns    Host ID                               Rack
    UN  10.0.10.2  112.05 KB  256          ?       e14f0945-07ed-4dc7-aee0-3c1bf41588e8  europe-west1-b
    UN  10.0.10.3  15.31 KB   256          ?       b40802b3-0986-40c7-8488-4149b3f62fa0  europe-west1-b
    UN  10.0.10.4  96.92 KB   256          ?       2103dd56-b3a9-4eae-a7bd-362c2fa8e7bd  europe-west1-b

    Note: Non-system keyspaces don't have the same replication settings, effective ownership information is meaningless
