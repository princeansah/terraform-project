resource "aws_s3_bucket" "tf_course" {
    bucket = "terraformproject23"
    acl    = "private"
}