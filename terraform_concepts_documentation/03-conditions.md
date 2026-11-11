# Terraform Conditionals: Choosing `instance_type` by Environment

Different ways to choose an EC2 `instance_type` (and related settings) based on `var.tags.Environment`.

---

## 1. Ternary

```hcl
instance_type = var.tags.Environment == "prod" ? "m5.large" : "t3.micro"
```

## 2. Nested ternary

```hcl
instance_type = (
  var.tags.Environment == "prod"  ? "m5.large"  :
  var.tags.Environment == "stage" ? "t3.medium" :
  "t3.micro"
)
```

## 3. Map lookup (cleanest)

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

## 4. `lookup()` with a default

```hcl
instance_type = lookup(local.instance_sizes, var.tags.Environment, "t3.micro")
```

## 5. `try()`, for when the Environment tag itself might be missing

```hcl
instance_type = try(local.instance_sizes[var.tags.Environment], "t3.micro")
```

## 6. `coalesce()` with an override variable

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

## 7. `contains()`: one size for a group of environments

```hcl
instance_type = contains(["prod", "stage"], var.tags.Environment) ? "m5.large" : "t3.micro"
```

## 8. String functions

```hcl
# Matches "prod", "prod-us", "prod-eu", and so on
instance_type = startswith(var.tags.Environment, "prod") ? "m5.large" : "t3.micro"

# Ignores case: "PROD" and "Prod" both count
instance_type = lower(var.tags.Environment) == "prod" ? "m5.large" : "t3.micro"
```

## 9. Operators that combine two tags

```hcl
instance_type = (
  var.tags.Environment == "prod" && lookup(var.tags, "Tier", "") == "critical"
  ? "m5.2xlarge" : "t3.micro"
)
```

## 10. `locals` that name the condition

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

---

## Guardrails

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

---

## Conditional resources and blocks

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

- **In real code:** write **#3** or **#4** (a map lookup).
- **Add #11** (validation) so a bad tag fails early.
- **Use #12 or #13** for safety rules.
- **A ternary (#1)** is fine for a simple two-way choice.
- **Avoid long nested ternaries (#2)** because they're hard to read.