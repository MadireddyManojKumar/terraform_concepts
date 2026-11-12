resource "aws_security_group" "roboshop" {

    for_each = var.instances

    ingress {
        from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    egress  {
         from_port = 0
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    
    }

    tags = {
        Name= "${var.project_name}-${each.key}"
    }

}

resource "aws_security_group" "common" {

    egress {
         from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name= "${var.project_name}-common"
    }

}



