# In general tf var failes will be added to .git ignore file, because it may contain sensitive information,
# If there is no sensitive information we can add variables as key = value pairs in terraform*.tfvars
# when we execute terraform, terraform.tfvars fill be loaded automatically.

ami_id="ami-0055977a6e828a4f4"
aws_instance_type="t3.micro"