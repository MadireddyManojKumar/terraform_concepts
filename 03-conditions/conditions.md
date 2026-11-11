# Terraform Conditional Patterns

A quick reference for writing conditional logic in Terraform, using an AWS web server as the running example.

- [Part 1: Conditional patterns for a web server (`var.env`)](#part-1-conditional-patterns-for-a-web-server-varenv)
- [Part 2: Picking an instance type from `var.tags.Environment`](#part-2-picking-an-instance-type-from-vartagsenvironment)
- [What to use](#what-to-use)

---

## Part 1: Conditional patterns for a web server (`var.env`)

### 1. Ternary expression: choose the instance size

```hcl
resource "aws_instance" "web" {
  instance_type = var.env == "prod" ? "m5.large" : "t3.micro"
}
```

### 2. `count`: a static IP only in prod

```hcl
resource "aws_eip" "web" {
  count    = var.env == "prod" ? 1 : 0
  instance = aws_instance.web.id
}

output "web_ip" {
  value = one(aws_eip.web[*].public_ip)   # null in dev
}
```

### 3. `for_each` with a filter: one server per public subnet

```hcl
resource "aws_instance" "web" {
  for_each  = { for k, s in var.subnets : k => s if s.public }
  subnet_id = each.value.id
}
```

### 4. `for` with `if`: list only the private subnets

```hcl
locals {
  private_subnet_ids = [for s in var.subnets : s.id if !s.public]
}
```

### 5. `dynamic` block: an extra disk only in prod

```hcl
resource "aws_instance" "web" {
  dynamic "ebs_block_device" {
    for_each = var.env == "prod" ? [1] : []
    content {
      device_name = "/dev/sdf"
      volume_size = 100
    }
  }
}
```

### 6. `null`: encrypt only in prod

```hcl
root_block_device {
  encrypted  = var.env == "prod"
  kms_key_id = var.env == "prod" ? var.kms_key_arn : null
}
```

### 7. Module `count`: monitoring only in prod

```hcl
module "monitoring" {
  source      = "./modules/monitoring"
  count       = var.env == "prod" ? 1 : 0
  instance_id = aws_instance.web.id
}
```

### 8. Functions: safe defaults for the web server

```hcl
locals {
  ami_id   = coalesce(var.custom_ami, data.aws_ami.default.id)  # first non-null value
  web_port = try(var.app_config.port, 8080)                     # fallback if the key is missing
  is_valid = contains(["dev", "prod"], var.env)
}
```

### 9. Operators: high availability only in prod with logging on

```hcl
locals {
  replicas = var.env == "prod" && var.enable_logs ? 3 : 1
}
```

### 10. `validation`: reject a bad env

```hcl
variable "env" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "env must be dev or prod."
  }
}
```

### 11. `precondition` and `postcondition`: guard the web server

```hcl
resource "aws_instance" "web" {
  lifecycle {
    precondition {
      condition     = var.env != "prod" || var.kms_key_arn != null
      error_message = "Prod web server needs a KMS key."
    }
    postcondition {
      condition     = self.private_ip != ""
      error_message = "Web server must have a private IP."
    }
  }
}
```

---

## Part 2: Picking an instance type from `var.tags.Environment`

Each method below starts from this line:

```hcl
instance_type = var.tags.Environment
```

> **Note:** As written, that line sets the instance type to the text `"prod"` or `"dev"`, which AWS rejects because it isn't a real instance type. Conditions are how you turn the environment name into a valid type.

```hcl
variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"      # dev | stage | prod
    Owner       = "manoj"
  }
}
```

### 1. Ternary

```hcl
instance_type = var.tags.Environment == "prod" ? "m5.large" : "t3.micro"
```

### 2. Nested ternary

```hcl
instance_type = (
  var.tags.Environment == "prod"  ? "m5.large"  :
  var.tags.Environment == "stage" ? "t3.medium" :
  "t3.micro"
)
```

### 3. Map lookup (cleanest)

```hcl
locals {
  instance_sizes = {
    dev   = "t3.micro"
    stage = "t3.medium"
    prod  = "m5.large"
  }
}

instance_type = local.instance_sizes[var.tags.Environment]   # errors if the key is missing
```

### 4. `lookup()` with a default

```hcl
instance_type = lookup(local.instance_sizes, var.tags.Environment, "t3.micro")
```

### 5. `try()`, for when the Environment tag itself might be missing

```hcl
instance_type = try(local.instance_sizes[var.tags.Environment], "t3.micro")
```

### 6. `coalesce()` with an override variable

```hcl
variable "instance_type_override" {
  type    = string
  default = null
}

instance_type = coalesce(
  var.instance_type_override,
  lookup(local.instance_sizes, var.tags.Environment, "t3.micro")
)
```

### 7. `contains()`: one size for a group of environments

```hcl
instance_type = contains(["prod", "stage"], var.tags.Environment) ? "m5.large" : "t3.micro"
```

### 8. String functions

```hcl
# Matches "prod", "prod-us", "prod-eu", and so on
instance_type = startswith(var.tags.Environment, "prod") ? "m5.large" : "t3.micro"

# Ignores case: "PROD" and "Prod" both count
instance_type = lower(var.tags.Environment) == "prod" ? "m5.large" : "t3.micro"
```

### 9. Operators that combine two tags

```hcl
instance_type = (
  var.tags.Environment == "prod" && lookup(var.tags, "Tier", "") == "critical"
  ? "m5.2xlarge" : "t3.micro"
)
```

### 10. `locals` that name the condition

```hcl
locals {
  is_prod       = var.tags.Environment == "prod"
  instance_type = local.is_prod ? "m5.large" : "t3.micro"
}

resource "aws_instance" "web" {
  instance_type = local.instance_type
  tags          = var.tags
}
```

### 11. `validation`: reject a bad Environment tag up front

```hcl
variable "tags" {
  type = map(string)
  validation {
    condition     = contains(["dev", "stage", "prod"], lookup(var.tags, "Environment", ""))
    error_message = "tags.Environment must be dev, stage, or prod."
  }
}
```

### 12. `precondition`: guard the resource

```hcl
resource "aws_instance" "web" {
  instance_type = lookup(local.instance_sizes, var.tags.Environment, "t3.micro")

  lifecycle {
    precondition {
      condition     = can(var.tags.Environment)
      error_message = "tags must include an Environment key."
    }
  }
}
```

### 13. `postcondition`: check the result

```hcl
  lifecycle {
    postcondition {
      condition     = var.tags.Environment != "prod" || self.instance_type != "t3.micro"
      error_message = "Prod must not run on t3.micro."
    }
  }
```

### 14. `count`: a second instance only in prod

```hcl
resource "aws_instance" "web_replica" {
  count         = var.tags.Environment == "prod" ? 1 : 0
  instance_type = local.instance_sizes[var.tags.Environment]
}
```

### 15. `for_each`: one instance per environment, with a filter

```hcl
resource "aws_instance" "web" {
  for_each      = { for env, size in local.instance_sizes : env => size if env != "dev" }
  instance_type = each.value       # stage → t3.medium, prod → m5.large
  tags          = merge(var.tags, { Environment = each.key })
}
```

### 16. `dynamic` block: an extra disk only in prod

```hcl
resource "aws_instance" "web" {
  instance_type = local.instance_sizes[var.tags.Environment]

  dynamic "ebs_block_device" {
    for_each = var.tags.Environment == "prod" ? [1] : []
    content {
      device_name = "/dev/sdf"
      volume_size = 100
    }
  }
}
```

### 17. `null`: set an argument only in some environments

```hcl
  monitoring = var.tags.Environment == "prod" ? true : null   # null leaves the provider default
```

### 18. Template conditional, in `user_data`

```hcl
  user_data = <<-EOT
    #!/bin/bash
    %{ if var.tags.Environment == "prod" }
    echo "Installing monitoring agent"
    %{ else }
    echo "Non-prod: skipping agent"
    %{ endif }
  EOT
```

### 19. `check` block: a warning only, doesn't stop the apply

```hcl
check "env_size_sanity" {
  assert {
    condition     = !(var.tags.Environment == "dev" && aws_instance.web.instance_type == "m5.large")
    error_message = "Dev is running a large instance. Check costs."
  }
}
```

---

## What to use

| Need | Pattern |
| --- | --- |
| Pick a value per environment | Map lookup (#3) or `lookup()` with a default (#4) |
| Fail early on a bad tag | `validation` (#11) |
| Safety rules on the resource | `precondition` / `postcondition` (#12, #13) |
| Simple two-way choice | Ternary (#1) |
| Avoid | Long nested ternaries (#2), which are hard to read |