/*
1. ec2 instance resource
2. security group resource
    -   22 (ssh)
    -   443 (https)
    -   3000 (nodejs) // ip:3000
*/

resource "aws_instance" "tf_ec2_instance" {
  ami                         = var.ami_id # ubuntu image
  instance_type               = var.instance_type
  associate_public_ip_address = true
  key_name                    = "terraform-ec2"

  vpc_security_group_ids = [module.tf_module_ec2_sg.security_group_id]

  depends_on = [aws_s3_object.tf_s3_object]

  user_data_replace_on_change = true


# 2^3 2^2 2^1 2^0

# 0   0   0   1   =>  1

# 0   0   1   0   =>  2
# 0   0   1   1   =>  3
# 0 1 0 0 => 4
# 0 1 0 1 => 5
# 0 1 1 0 => 6
# 0 1 1 1 => 7

# 1 0 0 0 => 8
# 1 0 0 1 => 9
# 1 0 1 0 => 10
# 1 0 1 1 => 11
# 1 1 0 0 => 12

# 1 1 0 1 => 13
# 1 1 1 0 => 14
# 1 1 1 1 => 15



  user_data = <<-EOF
                #!/bin/bash

                # Git clone 
                git clone https://github.com/aravpatel19/nodejs-mysql.git /home/ubuntu/nodejs-mysql
                cd /home/ubuntu/nodejs-mysql

                # install nodejs
                sudo apt update -y
                sudo apt install -y nodejs npm

                # edit env vars
                echo "DB_HOST=${local.rds_endpoint}" | sudo tee .env
                echo "DB_USER=${aws_db_instance.tf_rds_instance.username}" | sudo tee -a .env
                sudo echo "DB_PASS=${aws_db_instance.tf_rds_instance.password}" | sudo tee -a .env
                echo "DB_NAME=${aws_db_instance.tf_rds_instance.db_name}" | sudo tee -a .env
                echo "TABLE_NAME=users" | sudo tee -a .env
                echo "PORT=3000" | sudo tee -a .env

                # start server
                npm install
                nohup node server.js > /tmp/server.log 2>&1 &
                EOF

  tags = {
    Name = var.app_name
  }
}

# Security group

# resource "aws_security_group" "tf_ec2_sg" {
#   name        = "nodejs-server-sg"
#   description = "Allow SSH and HTTP traffic"
#   vpc_id      = var.vpc_id

#   ingress {
#     description = "TLS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # allow from all IPs
#   }

#   ingress {
#     description = "SSH"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # allow from all IPs
#   }

#   ingress {
#     description = "TCP"
#     from_port   = 3000 # for nodejs app
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] # allow from all IPs
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# ec2 security group module
module "tf_module_ec2_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  vpc_id = var.vpc_id
  name   = "tf_module_ec2_sg"

  ingress_with_cidr_blocks = [
    {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      description = "for nodejs app"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "https-443-tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      rule        = "ssh-tcp"
      cidr_blocks = "0.0.0.0/0"
    },

  ]
  egress_rules = ["all-all"]

  tags = {
    Name = "tf_module_ec2_sg"
  }
}

# output
output "ec2_public_ip" {
  value = "ssh -i ~/.ssh/terraform-ec2.pem ubuntu@${aws_instance.tf_ec2_instance.public_ip}"
}