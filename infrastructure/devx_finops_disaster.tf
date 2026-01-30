###############################################################################
# DEVX FINOPS DISASTER DEMO (Terraform)
# Purpose: Trigger HIGH-IMPACT DevX IaC findings.
# DO NOT APPLY. Placeholders included to prevent accidental apply.
#
# What this file demonstrates:
# - Unbounded scaling (count & autoscaling max)
# - Expensive networking defaults (NAT gateway per AZ, internet-facing ALB)
# - gp2 volumes instead of gp3
# - Missing required cost allocation tags
# - Unpinned module source (supply-chain + drift risk)
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.4"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" { type = string default = "us-east-1" }

# HIGH: Unbounded scale input (no validation)
variable "web_count" {
  type    = number
  default = 11
}

# HIGH: Open-ended autoscaling max (no upper bound)
variable "asg_max" {
  type    = number
  default = 1000
}

# Missing org cost tags (intentionally)
locals {
  required_tags = {
    # Owner      = "team-x"
    # CostCenter = "cc-123"
    # Env        = "prod"
    # Repo       = "demo"
  }
}

# WARN: Unpinned module version (supply-chain / drift)
module "vpc_unpinned" {
  source = "github.com/some-org/terraform-aws-vpc//modules/vpc" # no ref pin on purpose
}

# Placeholder VPC/Subnets to prevent accidental apply
resource "aws_vpc" "demo" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "devx-demo-vpc"
  }
}

# EXPENSIVE PATTERN: NAT Gateway per AZ
# (can rack up real monthly spend; demo purpose only)
resource "aws_eip" "nat_eip" {
  count = 3
  vpc   = true
}

resource "aws_nat_gateway" "nat" {
  count         = 3
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = "subnet-00000000000000000" # placeholder
  tags = {
    Name = "devx-demo-nat-${count.index}"
  }
}

# EXPENSIVE PATTERN: Internet-facing ALB + default log off
resource "aws_lb" "public_alb" {
  name               = "devx-demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-00000000000000000"]     # placeholder
  subnets            = ["subnet-00000000000000000"] # placeholder

  # Intentionally missing access_logs block (audit/cost visibility)
  tags = {
    Name = "devx-demo-alb"
  }
}

# HIGH: Security group wide open (should be flagged)
resource "aws_security_group" "wide_open" {
  name        = "devx-wide-open"
  description = "demo sg - DO NOT APPLY"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# HIGH: Unbounded `count` for EC2 fleet + missing tags + gp2 volumes
resource "aws_instance" "web" {
  count         = var.web_count
  ami           = "ami-00000000000000000" # placeholder
  instance_type = "m5.large"

  vpc_security_group_ids = [aws_security_group.wide_open.id]

  root_block_device {
    volume_size = 200
    volume_type = "gp2" # should trigger gp2 -> gp3
  }

  # Intentionally missing required tags
  tags = {
    Name = "devx-demo-web-${count.index}"
    # missing Owner, CostCenter, Env, Repo
  }
}

# HIGH: AutoScaling group with crazy max and no cost guardrails
resource "aws_autoscaling_group" "web_asg" {
  name                 = "devx-demo-asg"
  min_size             = 2
  max_size             = var.asg_max
  desired_capacity     = 2
  vpc_zone_identifier  = ["subnet-00000000000000000"] # placeholder

  # Missing tags propagation
  tag {
    key                 = "Name"
    value               = "devx-demo-asg"
    propagate_at_launch = true
  }
}
