###############################################################################
# BIG + BAD Terraform demo
# Purpose: reliably trigger EXACTLY 3 CostLint IaC rules (and nothing else).
# Do NOT apply.
#
# Targets (3 rules):
# 1) TF_UNBOUNDED_COUNT_VARIABLE        (blocking)  - count driven by an unbounded var
# 2) TF_MODULE_VERSION_NOT_PINNED       (warn)      - module uses unpinned ref
# 3) AWS_EBS_GP2_INSTEAD_OF_GP3         (warn)      - EBS volume type gp2 and 3 and 4 and 5
###############################################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

################################################################################
# Vars
################################################################################

variable "region" {
  type    = string
  default = "us-east-1"
}

# INTENTIONALLY DANGEROUS:
# Unbounded var used directly for `count` → should trigger rule (1).
# Keep default small so this doesn't accidentally create a lot if someone applies.
variable "instance_count" {
  type    = number
  default = 2
  # Note: no validation block on purpose (that's the point)
}

################################################################################
# 1) Unbounded resource expansion via count (Rule 1)
################################################################################

resource "aws_security_group" "demo" {
  name        = "devx-demo-sg"
  description = "demo sg (do not apply)"
  vpc_id      = "vpc-00000000000000000" # placeholder to avoid accidental apply

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bad_count" {
  count         = var.instance_count
  ami           = "ami-00000000000000000" # placeholder to avoid accidental apply
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.demo.id]

  tags = {
    Name        = "devx-demo-${count.index}"
    Environment = "demo"
    Owner       = "devx"
  }
}

################################################################################
# 2) Unpinned module version (Rule 2)
################################################################################
# Module source without a pinned ref (no ?ref=... and not a versioned registry module).
# Should trigger "module version not pinned".
module "bad_unpinned_module" {
  source = "github.com/CloudVerse-Pte-Ltd/devx-demo-cost-regressions//terraform/modules/example"
  # intentionally no version pin / ref
}

################################################################################
# 3) gp2 EBS volume (Rule 3)
################################################################################

resource "aws_ebs_volume" "gp2_volume" {
  availability_zone = "us-east-1a"
  size              = 200
  type              = "gp2" # should trigger gp2→gp3 recommendation

  tags = {
    Name        = "devx-demo-gp2"
    Environment = "demo"
    Owner       = "devx"
  }
}
