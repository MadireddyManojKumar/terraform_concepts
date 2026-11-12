variable "ami_id" {
    type = string
    default = "ami-0055977a6e828a4f4"
    description = "EC2 Instance ami id"
}

variable "instance_type" {
    type = string
    default = "t3.micro"
    description = "default instance type for EC2"
}


variable "project_name" {
    default = "Roboshop"
  
}

variable "domain_name" {
    default = "manojkumar.blog"
}

# variable "instances" {
#     default = ["mongodb", "mysql", "rabbitmq", "redis"]
# }

variable "hosted_zone_id" {
  default = "Z01055423405K8ZU51PTN"
}

variable "instances" {
    default = {
        mongodb = {
            instance_type="t3.micro"
        },
        redis = {
            instance_type = "t3.small"
        },
        mysql = {
            instance_type="t3.micro"
        },
        rabbitmq = {
            instance_type = "t3.small"
        }
    }
    
}
