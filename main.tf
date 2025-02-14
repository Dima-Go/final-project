provider "aws" {
  region = var.aws_region
}

# Create VPC using AWS module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name            = "jenkins-vpc"
  cidr            = var.vpc_cidr
  azs             = var.az
  private_subnets = var.private_subnets
  public_subnets  = var.subnet_cidr

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  map_public_ip_on_launch = true
}

# IAM Role for EKS
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# Attach EKS Cluster Policy to EKS Role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attach" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Policy for Jenkins to access AWS
resource "aws_iam_policy" "jenkins_policy" {
  name        = "jenkins-aws-access_admin"
  description = "Policy allowing Jenkins to manage AWS resources"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

# IAM Role for Jenkins
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins-eks-role"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

# Attach IAM Policy to Jenkins Role
resource "aws_iam_policy_attachment" "jenkins_policy_attach" {
  name       = "jenkins-policy-attach"
  roles      = [aws_iam_role.jenkins_role.name]
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

# IAM Instance Profile for Jenkins Role
resource "aws_iam_instance_profile" "jenkins_instance_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_role.name
}

# Attach EKS Cluster Policy to Jenkins Role
resource "aws_iam_role_policy_attachment" "jenkins_eks_cluster_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Attach EKS Worker Node Policy to Jenkins Role
resource "aws_iam_role_policy_attachment" "jenkins_eks_worker_node_policy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Security Group for Jenkins EC2
resource "aws_security_group" "jenkins_sg" {
  name   = var.jenkins_sg_name
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instance for Jenkins
resource "aws_instance" "jenkins_ec2" {
  ami                         = "ami-04b4f1a9cf54c11d0"
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.jenkins_instance_profile.name
  tags = {
    Name = "jenkins-ec2"
  }

  user_data = <<-EOF
  #!/bin/bash
  set -ex

  # Log output to /var/log/user_data.log
  exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

  # Update and install dependencies
  sudo apt-get update -y && \
  sudo apt-get install -y snapd software-properties-common && \
  
  # Install OpenJDK 21
  sudo apt-get install -y openjdk-21-jdk && \
  
  # Install AWS CLI using snap
  sudo snap install aws-cli --classic && \

  # Install kubectl using snap
  sudo snap install kubectl --classic && \

  # Add the Jenkins repository key
  sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null && \
  
  # Add the Jenkins repository
  sudo echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | tee /etc/apt/sources.list.d/jenkins.list > /dev/null && \

  sudo apt-get update -y && \
  sudo apt-get install -y jenkins && \

  # Enable and start Jenkins
  sudo systemctl enable jenkins && \
  sudo systemctl start jenkins && \
  
  # Install eksctl using curl
  sudo curl -sSLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" && \
  sudo tar -xzf eksctl_Linux_amd64.tar.gz && \
  sudo mv eksctl /usr/local/bin/ && \
  sudo rm eksctl_Linux_amd64.tar.gz

  EOF
}

module "eks" {
  source                   = "terraform-aws-modules/eks/aws"
  cluster_name             = "my-terra-cluster"
  cluster_version          = "1.31"
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets
  vpc_id                   = module.vpc.vpc_id


  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    terra-eks = {
      min_size     = 1
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
    }

  }
# Cluster access entry
# To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true
}
