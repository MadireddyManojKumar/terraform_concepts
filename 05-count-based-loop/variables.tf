variable "ami_id" {
    default = "ami-0055977a6e828a4f4"
}

variable "instance_type" {
    default = "t3.micro"
}


variable "environment" {
  default = "PROD"
}

variable "domain_name" {
  default = "manojkumar.blog"
}


variable "project" {
  default = "roboshop"
}

variable "instances" {
    default = ["mongodb", "redis", "rabbitmq", "mysql", "frontend"]
}

variable "hosted_zone_id" {
  default = "Z01055423405K8ZU51PTN"
}