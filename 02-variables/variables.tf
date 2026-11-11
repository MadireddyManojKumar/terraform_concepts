variable "ami_id" {
    type = string
    default = "ami-0055977a6e828a4f4"
    description = "AMI id for EC2 instance"
}


variable "aws_instance_type" {
  default = "t3.micro"
  type = string
  description = "AWS instance type for microservices in Dev environment"
}