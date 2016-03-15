variable "amis" {
    default = {
        "amzn-ami" = "ami-e1398992"
        "rhel-ami" = "ami-8b8c57f8"
    }
}

variable "misc" {
    default = {
        "node-type" = "m4.xlarge"
        "keypair" = "SpotInstanceKeyPair"
        "spot-count" = 2
    }
}