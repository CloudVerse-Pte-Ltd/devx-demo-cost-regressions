terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Demo toggle: NAT Gateway disabled on main (count = 0)
variable "enable_nat_gateway" {
  type    = bool
  default = true
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? 8 : 0

  allocation_id = "eipalloc-1234567890abcdef0"
  subnet_id     = "subnet-1234567890abcdef0"

  tags = {
    Name = "devx-demo-nat"
  }
}
