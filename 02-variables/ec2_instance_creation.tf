resource "aws_instance" "Roboshop" {
    ami = var.ami_id
    instance_type = var.aws_instance_type
    count =2      
    tags= {
        Name = "roboshop instance - ${count.index}"
    }
}