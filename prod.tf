# terraform creates a private s3 bucket named "terraformproject23"
# run "terraform init, then terraform validate to see if the configuration files are correct"
# webgraphviz.com

resource "aws_s3_bucket" "prod_tf_course" {
    bucket = "terraformproject23"  # to save your plan in a separate file, "terraform plan -'destroy' -out=name_of_file" to create an out file.
    acl    = "private"
}

resource "aws_default_vpc" "default" {}