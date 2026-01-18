resource "aws_db_instance" "demo" {
  identifier             = "devx-demo-db"
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = "db.r6g.2xlarge"   # intentionally expensive
  allocated_storage      = 2000              # 2TB
  storage_type           = "gp3"
  multi_az               = true              # doubles compute
  backup_retention_period = 14

  username = "demo"
  password = "demo-password-12345678"

  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name       = "devx-demo-db"
    CostCenter = "DEMO"
    Env        = "prod"
  }
}
