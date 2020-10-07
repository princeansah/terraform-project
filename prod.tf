# terraform creates a private s3 bucket named "terraformproject23"
# run "terraform init, then terraform validate to see if the configuration files are correct"
# webgraphviz.com

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

# auto scaling group
resource "aws_launch_template" "prod_web" {     # this is just the configuration that your ASG should use to lunch new instances
    name_prefix   = "prod-web"
    image_id      = "ami-019c091d13a1fa156"
    instance_type = "t2.nano"
}

resource "aws_autoscaling_group" "prod_web" {
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]  #available and used subnets
  desired_capacity    = 2             
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }
  tag {
      key                  = "Terraform"
      value                = "True"
      propagate_at_launch  = true  # this means it will assign that key "Terraform on launch"
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id
}

# load balancer
resource "aws_elb" "prod_web" {
    name               = "prod-web"
    subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id] # the subnets are provided in array because i have multiple subnets
    security_groups    = [aws_security_group.prod_web.id]  # its provided in array because the terraform documentation on the website expects multiple SG

    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    tags                  = {
        "Terraform" : "true"
    }    
} 