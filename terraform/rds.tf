/*

1. rds tf resource
2. security group resource
    -   3306 (mysql)
        -   security-group -> ec2-sg
        -   cidr_block -> ["local ip"]

3. outputs
*/

# rds resource

resource "aws_db_instance" "tf_rds_instance" {
  allocated_storage      = 10
  db_name                = "arav_demo"
  identifier             = "nodejs-rds-mysql"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t2.micro"
  username               = "admin"
  password               = "password"
  parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.tf_rds_sg.id]
}

resource "aws_security_group" "tf_rds_sg" {
  name        = "allow_mysql"
  vpc_id      = var.vpc_id
  description = "Allow MySQL traffic"

  ingress {
    description     = "Allow MySQL traffic from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.tf_module_ec2_sg.security_group_id]
  }

  ingress {
    description = "Demo access from anywhere (replace with stricter rules later)"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow MySQL traffic from EKS VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # EKS VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}
# locals
locals {
  rds_endpoint = element(split(":", aws_db_instance.tf_rds_instance.endpoint), 0)
}
# outputs
output "rds_endpoint" {
  value = local.rds_endpoint
}

output "rds_username" {
  value = aws_db_instance.tf_rds_instance.username
}

output "rds_db_name" {
  value = aws_db_instance.tf_rds_instance.db_name
}