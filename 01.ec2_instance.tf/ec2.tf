resource "aws_instance" "mongodb"{
    ami = ami-0055977a6e828a4f4
    instance = "t3.micro"

    tags =  {
        name = "MONGODB"
        terraform = "YES"
        environment = "PROD"       

    }
}


resource "aws_security_group" "ec2-common" {
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