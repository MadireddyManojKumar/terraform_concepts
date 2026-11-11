Different ways of writing variables in Terraform

1. Default values
2. terraform.tfvars or *.tfvars
3. env variables
4. command line
5. prompt


1.Default values:
---------------
Create a file with variables.tf and defind all commonly used variables

variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "Toggle to enable public IP assignment"
  type        = bool
  default     = false
}

main.tf
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = var.instance_type
}

- default way of declaring variables will be committed to git. do put any sensitive information in variables.
 

2. terraform.tfvars
-----------------
1. when you declare variables in terraform.tfvars it will be automatically loaded 
2. When Terraform automatically reads your terraform.tfvars file, the values are stored in-memory during execution and ultimately written to your Terraform state file (terraform.tfstate)
3. even if the value is marked as sensitive, terraform stores those values in terraform.tfstate as a plain text
4. avoid writing sensitive information to terraform.tfvars file.

# terraform.tfvars
instance_type = "t3.medium"

to access 

3. environment variable:
-------------------------
export TF_VAR_instance_type="t3.small". --> to set 
unset TF_VAR_instance_type. --> to unset

terraform plan  # instance_type = t3.small

Environment variables can leak through shell history, CI logs, or env dumps in debug output. They’re invisible in the code, so it’s easy to forget one is set and get unexpected values.

4. passing variables fom command line :
terraform plan -var="instance_type=c5.xlarge"


5. 



