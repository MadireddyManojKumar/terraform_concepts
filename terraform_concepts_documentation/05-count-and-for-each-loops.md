# Terraform Loops: `count` and `for_each`

Both `count` and `for_each` let one `resource` block create many copies of a resource. This doc walks through the Roboshop examples in [05-count-based-loop](../05-count-based-loop/) and [06-for-each-loop](../06-for-each-loop/). Each example creates one EC2 instance, one security group and one Route 53 record per component (mongodb, redis, mysql, …).

---

## Part 1: Count-based loops

### 1.1 The input: a list

`count` works on a number, so the natural input is a **list**. Its length gives the number of copies.

```hcl
# 05-count-based-loop/variables.tf
variable "instances" {
    default = ["mongodb", "redis", "rabbitmq", "mysql", "frontend"]
}
```

### 1.2 `count` and `count.index`

```hcl
# 05-count-based-loop/ec2.tf
resource "aws_instance" "roboshop" {
    count         = length(var.instances)          # 5
    ami           = var.ami_id
    instance_type = var.instance_type

    tags = {
        Name = "${var.project}-${var.environment}-${var.instances[count.index]}"
    }

    vpc_security_group_ids = [ aws_security_group.common.id, aws_security_group.roboshop[count.index].id ]
}
```

- `count = length(var.instances)` tells Terraform to create 5 instances.
- `count.index` is the current copy's number, from `0` to `4`.
- `var.instances[count.index]` turns that number into a name:

| `count.index` | `var.instances[count.index]` | Tag `Name` |
|---|---|---|
| 0 | mongodb  | roboshop-PROD-mongodb  |
| 1 | redis    | roboshop-PROD-redis    |
| 2 | rabbitmq | roboshop-PROD-rabbitmq |
| 3 | mysql    | roboshop-PROD-mysql    |
| 4 | frontend | roboshop-PROD-frontend |

### 1.3 Resources with and without `count`

The `common` security group has no `count`, so there is exactly one, and it's referenced as `aws_security_group.common.id`.

The per-component security group uses the same `count`, so there are 5 of them, and it's referenced **by index**:

```hcl
# 05-count-based-loop/ec2.tf
resource "aws_security_group" "roboshop" {
    count = length(var.instances)
    name  = "${var.project}-${var.environment}-${var.instances[count.index]}"
    ...
}
```

```hcl
aws_security_group.roboshop[count.index].id
```

Instance `[2]` (rabbitmq) gets security group `[2]` (rabbitmq). This works only because both resources loop over the same list in the same order.

### 1.4 Using one counted resource in another

The Route 53 records loop over the same list and read the matching instance's IP by index:

```hcl
# 05-count-based-loop/r53.tf
resource "aws_route53_record" "roboshop" {
  count   = length(var.instances)
  zone_id = var.hosted_zone_id
  name    = "${var.instances[count.index]}.${var.domain_name}"   # mongodb.manojkumar.blog
  type    = "A"
  ttl     = 1
  records = [aws_instance.roboshop[count.index].private_ip]
}
```

### 1.5 `count` as an on/off switch

`count = 0` creates nothing and `count = 1` creates one. With a condition, this makes a resource optional:

```hcl
# 05-count-based-loop/r53.tf
resource "aws_route53_record" "frontend" {
  count   = contains(var.instances, "frontend") ? 1 : 0
  zone_id = var.hosted_zone_id
  name    = "${var.domain_name}"                                  # manojkumar.blog
  type    = "A"
  ttl     = 1
  records = [aws_instance.roboshop[index(var.instances, "frontend")].public_ip]
}
```

- `contains(var.instances, "frontend")` checks whether `frontend` is in the list.
- `index(var.instances, "frontend")` returns its position (`4`), so the record gets the **public** IP of `aws_instance.roboshop[4]`.

### 1.6 Output of a counted resource

```hcl
# 05-count-based-loop/output.tf
output "roboshop" {
  value = aws_instance.roboshop
}
```

A counted resource is a **list**, so this output is a list of 5 instance objects. To get one attribute from all of them, use a splat expression:

```hcl
value = aws_instance.roboshop[*].private_ip
```

### 1.7 The problem with `count`: index shifting

Terraform tracks counted resources by number: `aws_instance.roboshop[0]`, `[1]`, and so on. If you remove `"redis"` from the middle of the list:

```hcl
["mongodb", "rabbitmq", "mysql", "frontend"]
```

then every item after it moves up one position. Terraform now sees `[1]` as rabbitmq instead of redis, `[2]` as mysql instead of rabbitmq, and so on. It will **rename, replace or destroy instances you didn't mean to touch**, and remove `[4]`. `for_each` solves this.

---

## Part 2: `for_each` loops

### 2.1 The input: a map

`for_each` takes a **map** (or a set of strings). Each key becomes the resource's identity. Here the map also stores a different `instance_type` per component, which a plain list can't do:

```hcl
# 06-for-each-loop/variables.tf
variable "instances" {
    default = {
        mongodb  = { instance_type = "t3.micro" }
        redis    = { instance_type = "t3.small" }
        mysql    = { instance_type = "t3.micro" }
        rabbitmq = { instance_type = "t3.small" }
    }
}
```

### 2.2 `each.key` and `each.value`

```hcl
# 06-for-each-loop/ec2.tf
resource "aws_instance" "roboshop" {
    for_each      = var.instances
    ami           = var.ami_id
    instance_type = each.value.instance_type

    tags = {
        Name = "${var.project_name}-${each.key}"
    }

    vpc_security_group_ids = [ aws_security_group.common.id, aws_security_group.roboshop[each.key].id ]
}
```

On each pass:

| `each.key` | `each.value` | `each.value.instance_type` | Resource address |
|---|---|---|---|
| mongodb  | `{ instance_type = "t3.micro" }` | t3.micro | `aws_instance.roboshop["mongodb"]`  |
| mysql    | `{ instance_type = "t3.micro" }` | t3.micro | `aws_instance.roboshop["mysql"]`    |
| rabbitmq | `{ instance_type = "t3.small" }` | t3.small | `aws_instance.roboshop["rabbitmq"]` |
| redis    | `{ instance_type = "t3.small" }` | t3.small | `aws_instance.roboshop["redis"]`    |

Resources are addressed **by key, not by number**.

### 2.3 Matching resources by key

The security group loops over the same map:

```hcl
# 06-for-each-loop/security_group.tf
resource "aws_security_group" "roboshop" {
    for_each = var.instances
    ...
    tags = {
        Name = "${var.project_name}-${each.key}"
    }
}
```

The instance picks its own group with `aws_security_group.roboshop[each.key].id`. The `mongodb` instance gets the `mongodb` group, whatever order the map is in.

### 2.4 Looping over another resource

A resource that uses `for_each` is itself a map, so you can pass it straight to another `for_each`:

```hcl
# 06-for-each-loop/r53.tf
resource "aws_route53_record" "roboshop" {
  for_each = aws_instance.roboshop

  zone_id         = var.hosted_zone_id
  name            = "${each.key}.${var.domain_name}"   # mongodb.manojkumar.blog
  type            = "A"
  ttl             = 1
  records         = [each.value.private_ip]
  allow_overwrite = true
}
```

Here `each.key` is the component name and `each.value` is the **whole EC2 instance object**, so `each.value.private_ip` is that instance's IP. You get one DNS record per instance without repeating the list.

`allow_overwrite = true` lets Terraform take over a record that already exists in the hosted zone instead of failing.

### 2.5 Mixing `for_each` and `count`

The apex record still uses `count` as an on/off switch, but with map functions:

```hcl
# 06-for-each-loop/r53.tf
resource "aws_route53_record" "frontend" {
  count           = contains(keys(var.instances), "frontend") ? 1 : 0
  zone_id         = var.hosted_zone_id
  name            = "${var.domain_name}"                         # manojkumar.blog
  type            = "A"
  ttl             = 1
  records         = [lookup(aws_instance.roboshop, "frontend").public_ip]
  allow_overwrite = true
}
```

- `keys(var.instances)` returns `["mongodb", "mysql", "rabbitmq", "redis"]`.
- `lookup(aws_instance.roboshop, "frontend")` gets the instance by key. `aws_instance.roboshop["frontend"]` does the same thing.

In the current `variables.tf` there is no `frontend` key, so `count = 0` and this record isn't created. Add a `frontend = { instance_type = "t3.micro" }` entry and both the instance and the apex record appear.

### 2.6 Why index shifting doesn't happen

If you remove `redis` from the map, Terraform plans to destroy only `aws_instance.roboshop["redis"]`, its security group and its DNS record. `mongodb`, `mysql` and `rabbitmq` keep their addresses and aren't touched.

---

## Part 3: `count` vs `for_each`

| | `count` (05) | `for_each` (06) |
|---|---|---|
| Input | a number, usually `length(list)` | a map or a set of strings |
| Loop variables | `count.index` | `each.key`, `each.value` |
| Resource address | `aws_instance.roboshop[0]` | `aws_instance.roboshop["mongodb"]` |
| Resource type | list | map |
| Different settings per item | needs a second list kept in the same order | built in, via `each.value.<attr>` |
| Removing an item from the middle | shifts indexes, other resources change | only that item is destroyed |
| Get all IPs | `aws_instance.roboshop[*].private_ip` | `[for i in aws_instance.roboshop : i.private_ip]` or `values(aws_instance.roboshop)[*].private_ip` |

### What to use

- **Use `for_each`** to create several distinct things (mongodb, redis, mysql…). This is the default choice.
- **Use `count`** for identical copies, where it doesn't matter which one is which (e.g. 3 web servers).
- **Use `count = condition ? 1 : 0`** to make a resource optional, as both `frontend` records do.
- `for_each` also accepts a list if you convert it: `for_each = toset(var.instances)`. Then `each.key` and `each.value` are both the name.
- A resource can't have both `count` and `for_each`.

---

## Things to fix in the example code

- **`06-for-each-loop/security_group.tf`:** the ingress and egress rules use `protocol = "tcp"` with `from_port = 0` and `to_port = 0`, which allows only TCP port 0, so effectively no traffic. Use `protocol = "-1"` for all traffic, or a real port range such as `0`–`65535`.
- **`05-count-based-loop/ec2.tf`:** the per-component security groups allow **all inbound traffic from `0.0.0.0/0`**. That's fine for a lab but not for real environments.
- **`05-count-based-loop/output.tf`:** the description says "public IP address", but the value is the full list of instance objects.
