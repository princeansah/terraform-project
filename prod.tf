# terraform creates a private s3 bucket named "terraformproject23"
# run "terraform init, then terraform validate to see if the configuration files are correct"
# webgraphviz.com


#variable definition block
variable "profile" {
    type = string
}
variable "region" {
    type = string
}
variable "ip_range" {
    type = list(string)
}              
variable "web_image_id" {
    type = string
}           
variable "web_instance_type"  {
    type = string
}     
variable "web_desired_capacity"  {
    type = number
}           
variable "web_max_size" {
    type = number
}           
variable "web_min_size"  {
    type = number
}          

# s3 bucket
resource "aws_s3_bucket" "prod_tf_course" {
    bucket = "terraformproject23"  # to save your plan in a separate file, "terraform plan -'destroy' -out=name_of_file" to create an out file.
    acl    = "private"
}

# VPC
resource "aws_default_vpc" "default" {}

# Subnet creation
resource "aws_default_subnet" "default_az1" {      # I set up my resources in multi AZ to be able to do load balancing
    availability_zone = "us-west-2a"
    tags              = {
        "Terraform" : "true"
    }
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = "us-west-2b"
    tags              = {
        "Terraform" : "true"
    }
}

# security groups
resource "aws_security_group" "prod_web" {
    name        = "prod_web"
    description = "Allow standard http and https ports inbound and everything outbound"

    ingress {               
        from_port   = 80   # this lets you define an inbound port range
        to_port     = 80   # however because we have same port number and not a range we maintain same numbers
        protocol    = "tcp"
        cidr_blocks = var.ip_range
    }
    ingress {
        from_port    = 443
        to_port      = 443
        protocol     = "tcp"
        cidr_blocks  = var.ip_range
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"           # allowing traffic from anywhere
        cidr_blocks = var.ip_range
    }
    tags = {
        "Terraform"   : "true"   # this provides a handy way to tell which resources are managed by terraform when you log in to 
    }                            # aws UI
}            

module "web_app" {
    source                   = "./modules/web_app"

    web_image_id             = var.web_image_id
    web_instance_type        = var.web_instance_type
    web_desired_capacity     = var.web_desired_capacity
    web_max_size             = var.web_max_size
    web_min_size             = var.web_min_size
    subnets                  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]  
    security_groups          = [aws_security_group.prod_web.id]
    web_app                  = "prod"
}