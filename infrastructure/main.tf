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

# Demo: NAT Gateway cost regression
resource "aws_nat_gateway" "this" {
  allocation_id = "eipalloc-1234567890abcdef0"
  subnet_id     = "subnet-1234567890abcdef0"

  tags = {
    Name = "devx-demo-nat"
  }
}
