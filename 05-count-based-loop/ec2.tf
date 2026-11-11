resource "aws_instance" "roboshop" {
    count= length(var.instances)
    ami = var.ami_id
    instance_type = var.instance_type

    tags ={
        Name= "${var.project}-${var.environment}-${var.instances[count.index]}"
    }

    vpc_security_group_ids = [ aws_security_group.common.id, aws_security_group.roboshop[count.index].id ]
}


resource "aws_security_group" "common" {
    name = "${var.project}-${var.environment}-common"
    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    
    tags = {
      Name = "${var.project}-${var.environment}-common"
    }
}



resource "aws_security_group" "roboshop" {
    count= length(var.instances)
    name= "${var.project}-${var.environment}-${var.instances[count.index]}"

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    ingress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }
    
}


