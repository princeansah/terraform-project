# terraform creates a private s3 bucket named "terraformproject23"
# run "terraform init, then terraform validate to see if the configuration files are correct"
# webgraphviz.com

resource "aws_s3_bucket" "prod_tf_course" {
    bucket = "terraformproject23"  # to save your plan in a separate file, "terraform plan -'destroy' -out=name_of_file" to create an out file.
    acl    = "private"
}

resource "aws_default_vpc" "default" {}

resource "aws_security_group" "prod_web" {
    name        = "prod_web"
    description = "Allow standard http and https ports inbound and everything outbound"

    ingress {              # this is 
        from_port   = 80   # this lets you define an inbound port range
        to_port     = 80   # however because we have same port number and not a range we maintain same numbers
        protocol    = "tcp"
        cidr_blocks = ["98.156.133.14/32"]
    }
    ingress {
        from_port    = 443
        to_port      = 443
        protocol     = "tcp"
        cidr_blocks  = ["98.156.133.14/32"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"           # allowing traffic from anywhere
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        "Terraform"   : "true"   # this provides a handy way to tell which resources are managed by terraform when you log in to 
    }                            # aws UI
}

resource "aws_instance" "prod_web" {
    count = 2

    ami = "ami-019c091d13a1fa156"
    instance_type  = "t2.nano"

    vpc_security_group_ids = [
        aws_security_group.prod_web.id   # this reference the security group configured above in the script.
    ]

    tags = {
        "Terraform" : "true"
    }
}

resource "aws_eip_association" "prod_web" {   # here i decoupled the eip association so that it can be reassociated with another instance if need be
    instance_id   = aws_instance.prod_web.0.id  # the .0 means the IP should be attached to the first instance of the 2 instances
    allocation_id = aws_eip.prod_web.id         # using a .* will mean to refer to all instances.
}

resource "aws_eip" "prod_web" {
    tags = {
        "Terraform" : "true"
    }
}