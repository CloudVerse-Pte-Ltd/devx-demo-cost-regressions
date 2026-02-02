terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# This is intentionally a demo "cost regression" change:
# - Creates a NAT Gateway + Elastic IP (commonly flagged as ongoing cost)
# - Very easy for FinOps guardrails to detect
# NOTE: Use in a demo/test account only.

resource "aws_eip" "devx_demo_nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "devx_demo_nat" {
  allocation_id = aws_eip.devx_demo_nat_eip.id
  subnet_id     = "subnet-REPLACE_ME" # dummy placeholder for demo PR
  tags = {
    Name = "devx-demo-nat"
    env  = "prod"
  }
}
