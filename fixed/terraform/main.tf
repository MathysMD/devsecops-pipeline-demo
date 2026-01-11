terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "demo"
      Project     = "devsecops"
      ManagedBy   = "terraform"
    }
  }
}

# Data source for current VPC
data "aws_vpc" "default" {
  default = true
}

# FIXED: Security group with restricted ingress rules
resource "aws_security_group" "devsecops_demo_sg" {
  name        = "devsecops-demo-sg"
  description = "Security group for DevSecOps demo - Restricted access"
  vpc_id      = data.aws_vpc.default.id

  # FIXED: HTTP access restricted to specific CIDR (replace with your IP/CIDR)
  ingress {
    description = "HTTP from trusted network"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Restricted to private network
  }

  # FIXED: HTTPS access restricted to specific CIDR
  ingress {
    description = "HTTPS from trusted network"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Restricted to private network
  }

  # FIXED: SSH access restricted to bastion host or specific IP
  ingress {
    description = "SSH from bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Restricted to bastion subnet
  }

  # Egress rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devsecops-demo-sg-secure"
  }
}

# FIXED: S3 bucket with encryption and versioning enabled
resource "aws_s3_bucket" "devsecops_demo_bucket" {
  bucket = "devsecops-demo-bucket-secure-12345"

  tags = {
    Name = "DevSecOps Demo Bucket - Secure"
  }
}

# FIXED: Enable versioning
resource "aws_s3_bucket_versioning" "devsecops_demo_versioning" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# FIXED: Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "devsecops_demo_encryption" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# FIXED: Block public access
resource "aws_s3_bucket_public_access_block" "devsecops_demo_public_access_block" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# FIXED: Private ACL instead of public
resource "aws_s3_bucket_acl" "devsecops_demo_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.devsecops_demo_ownership]

  bucket = aws_s3_bucket.devsecops_demo_bucket.id
  acl    = "private"
}

# Bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "devsecops_demo_ownership" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# FIXED: Enable logging
resource "aws_s3_bucket_logging" "devsecops_demo_logging" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id

  target_bucket = aws_s3_bucket.devsecops_demo_bucket.id
  target_prefix = "logs/"
}

# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "devsecops-demo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-demo-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 instance configuration with security best practices
resource "aws_instance" "devsecops_demo_instance" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.micro"  # Updated instance type

  vpc_security_group_ids = [aws_security_group.devsecops_demo_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # FIXED: Enable detailed monitoring
  monitoring = true

  # FIXED: Root volume encryption enabled
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # FIXED: IMDSv2 required (more secure than IMDSv1)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Require IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # FIXED: Enable EBS optimization
  ebs_optimized = true

  # User data for initial configuration
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent
              EOF

  tags = {
    Name = "devsecops-demo-instance-secure"
  }
}

# CloudWatch log group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/devsecops-demo"
  retention_in_days = 30

  tags = {
    Name = "devsecops-demo-logs"
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.devsecops_demo_instance.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.devsecops_demo_instance.private_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.devsecops_demo_bucket.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.devsecops_demo_bucket.arn
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.devsecops_demo_sg.id
}
