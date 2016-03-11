# cassandra-cloud
Deploy Cassandra to various cloud environments with automation

To deploy on Vagrant:

You will need vagrant and virtualbox installed, and internet access in order to download box files. Then:

    vagrant up
    ansible-playbook -i inventory-vagrant.txt main.yml

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

### TODO

Resolve issue with directory permissions preventing first-time start up for Cassandra
Rationalise / combine / simplify inv-gen.sh and inv-gen.rb
Add some kind of functional validation that Cassandra is up and running
