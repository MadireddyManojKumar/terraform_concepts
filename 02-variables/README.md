# Different Ways of Setting Variables in Terraform

There are 6 ways to give values to variables in Terraform:

1. Default values
2. terraform.tfvars or *.tfvars
3. Environment variables
4. Command line
5. Prompt
6. .auto.tfvars or .auto.tfvars.json

---

## 1. Default values

Create a file called `variables.tf` and define all the commonly used variables there.

```hcl
variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

You can use these variables in `main.tf` (or any other `.tf` file) with `var.<variable_name>`.

```hcl
# main.tf
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = var.instance_type
}
```

- Default values get committed to Git with the code, so don't put any sensitive information here.

---

## 2. terraform.tfvars

- If you put values in `terraform.tfvars`, Terraform loads them automatically.
- Don't put sensitive information in this file.
- even though if we declare variable in terraform.tfvard, inorder to refer that value , we need to have avariable in variables.tf file.(but we dont have to give default value in variables.tf file)
ex: 
```hcl
# terraform.tfvars
instance_type = "t3.medium"
```

```hcl
# variables.tf
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}
```
in main.tf file we can refer variable like instance_type=var.instance_type. --> though we havent declared that variable default, terraform will automatically read from  terraform.tf file


```hcl
# terraform.tfvars
instance_type = "t3.medium"
```

If you have multiple environments like Dev1, Dev2, SIT1, SIT2, and Prod, you'll usually keep a separate variables file for each one, like `dev1.tfvars`, `dev2.tfvars`, and `prod.tfvars`.

Terraform won't read these files on its own. You have to pass the file name when you run the command:

```bash
terraform plan  -var-file=dev1.tfvars
terraform apply -var-file=prod.tfvars
```

---

## 3. Environment variables

```bash
export TF_VAR_instance_type="t3.small"   # to set
unset TF_VAR_instance_type               # to unset

terraform plan   # instance_type = t3.small
```

- Environment variables can leak through shell history, CI logs, or env dumps in debug output.
- They don't show up in the code, so it's easy to forget one is set and get a value you didn't expect.

---

## 4. Command line

```bash
terraform plan -var="instance_type=c5.xlarge"
```

---

## 5. Prompt

If you declare a variable without a default value and don't give it a value anywhere else, Terraform asks you to enter the value when you run the command.

```
$ terraform plan
var.instance_type
  Enter a value:
```

---

## 6. .auto.tfvars or .auto.tfvars.json

Terraform loads any file ending in `.auto.tfvars` or `.auto.tfvars.json` automatically, the same way it loads `terraform.tfvars`. You don't need to pass any flag.

---

## Which one takes precedence?

Let's say I set `instance_type` to a different value in all of these places. Which value will Terraform use?

Terraform loads them in this order, and each one overrides the ones before it (the last one wins):

1. Default values (lowest)
2. Environment variables (`TF_VAR_`)
3. `terraform.tfvars`
4. `terraform.tfvars.json`
5. `*.auto.tfvars` / `*.auto.tfvars.json` (in alphabetical order of file names)
6. `-var` and `-var-file` on the command line (highest)

So the **command line always wins**.

Terraform only prompts you if the variable has no value from any of the places above.

---

## Note on sensitive values

Even if a variable is marked as `sensitive = true`, Terraform still stores its value in `terraform.tfstate` as plain text, no matter how you passed it in. So don't commit the state file to Git, and keep secrets out of your variable files.