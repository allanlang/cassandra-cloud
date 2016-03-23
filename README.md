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

`terraform/credentials.tf` looking something like this:

    provider "aws" {
        access_key = "YOUR ACCESS KEY"
        secret_key = "YOUR SECRET ACCESS KEY"
        region = "TARGET REGION"
    }

You should also set your credentials in the AWS_SECRET_ACCESS_KEY and AWS_ACCESS_KEY_ID environment variables before running the inv-gen.sh script.

    cd terraform
    terraform apply
    ./inv-gen.sh
    ansible-playbook -i inventory-aws.txt main.yml

The terraform script will provision:

- 1x new VPC
- 2x public subnets across two AZs
- 2x private subnets across two AZs
- 1x on-demand t2.nano bastion host in a public subnet
- 1x on-demand m4.xlarge cassandra seed node in a private subnet
- 3x spot m4.xlarge cassandra seed instances in a private subnet

*You will be charged* for the above resources. Spot instances are used to minimise the cost and you may adjust the instance types as required in terraform/variables.tf.

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

*You will be charged* for the above resources. Preemptible instances are used to minimise the cost and you may adjust the instance types as required by modifying the appropriate .tf files.

### TODO

Rationalise / combine / simplify inv-gen.sh and inv-gen.rb
Add some kind of functional validation that Cassandra is up and running
