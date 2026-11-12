resource "aws_instance" "roboshop" {
    for_each = var.instances
    ami = var.ami_id
    instance_type = each.value.instance_type
  
    tags = {
        Name= "${var.project_name}-${each.key}"
    }

    vpc_security_group_ids = [ aws_security_group.common.id, aws_security_group.roboshop[each.key].id ]
}