variable "ami_id" {
  type        = string
  description = "This is the AMI ID for the EC2 instance"
  default     = "ami-0360c520857e3138f"
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "app_name" {
  type    = string
  default = "Nodejs-server"
}

variable "vpc_id" {
  default = "vpc-075b52eb2d5f7da61"
}