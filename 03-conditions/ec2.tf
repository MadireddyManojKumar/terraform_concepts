resource "aws_instance" "conditions" {
    ami = var.ami_id

 # with condition we're checking if the environment is prod we're assigning t3.micro or elase we're assigning t3.large   
    instance_type =var.tags.Environment == "prod" ? "t3.micro" : "t3.small"

    tags = var.tags

    security_groups = [ "aws_security_group.roboshop-condition" ]

}




resource "aws_security_group" "roboshop-condition" {


    ingress {
        from_port        = var.from_port
        to_port          = var.to_port
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }


    egress {
        from_port        = var.from_port
        to_port          = var.to_port
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

  
}