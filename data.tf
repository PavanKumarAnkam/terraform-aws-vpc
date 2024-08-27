# data "aws_availability_zone" "zones" {
#   name = "us-east-1"
# }

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "default" {
  default = true
}