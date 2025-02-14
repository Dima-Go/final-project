variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins"
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name for EC2"
  default     = "aws_hw4_key"   # Replace with your key pair name
}

variable "jenkins_sg_name" {
  description = "Name of the security group for Jenkins EC2"
  default     = "jenkins-sg"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type        = list(string)
  description = "CIDR block for the subnet"
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDR blocks"
  default     = ["10.0.30.0/24", "10.0.40.0/24"]
}

variable "az" {
  type        = list(string)
  description = "Availability Zone for the subnet"
  default     = ["us-east-1a", "us-east-1b"]
}

