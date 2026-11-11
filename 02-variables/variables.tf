variable "ami_id" {
    type = string
    description = "AMI id for EC2 instance"
}


variable "aws_instance_type" {
  type = string
  description = "AWS instance type for microservices in Dev environment"
}