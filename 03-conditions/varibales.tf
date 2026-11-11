variable "ami_id" {
    type = string
    default = "ami-0055977a6e828a4f4"
    description = "Ami id for ec2 instance for roboshop project"
}


variable "instance_type" {
    type = string
    default = "t3.medium"
    description = "instance type for roboshop project"
}


variable "tags" {
    description = "roboshop instance default tage"
    default = {
        Name = "Roboshop - condition"
        Environment = "DEV"
        ManagedBy = "Terraform"
        Project = "Roboshop"
        owner = "Madireddy manoj kumar"
    }
  
}



variable "from_port" {
    default = 0
    type = number
    description = "from port for security group"    
}

variable "to_port" {
  type = number
  default = 0
  description = "to port for aws security group"
}