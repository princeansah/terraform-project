 # load balancer
resource "aws_elb" "this" {
    name               = "${var.web_app}-web"
    subnets            = var.subnets # the subnets are provided in array because i have multiple subnets
    security_groups    = var.security_groups  # its provided in array because the terraform documentation on the website expects multiple SG

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

 # auto scaling group
resource "aws_launch_template" "this" {     # this is just the configuration that your ASG should use to lunch new instances
    name_prefix   = "${var.web_app}-web"
    image_id      = var.web_image_id 
    instance_type = var.web_instance_type
}

resource "aws_autoscaling_group" "this" {
  vpc_zone_identifier = var.subnets  #available and used subnets
  desired_capacity    = var.web_desired_capacity              
  max_size            = var.web_max_size 
  min_size            = var.web_min_size

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
  tag {
      key                  = "Terraform"
      value                = "True"
      propagate_at_launch  = true  # this means it will assign that key "Terraform on launch"
  }
}

resource "aws_autoscaling_attachment" "this" {
  autoscaling_group_name = aws_autoscaling_group.this.id
  elb                    = aws_elb.this.id
}           