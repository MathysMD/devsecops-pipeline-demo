terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# MISCONFIGURATION 1: Security group allows unrestricted ingress from 0.0.0.0/0
resource "aws_security_group" "devsecops_demo_sg" {
  name        = "devsecops-demo-sg"
  description = "Security group for DevSecOps demo"
  vpc_id      = "vpc-12345678"

  # Wide open to the internet - BAD PRACTICE
  ingress {
    description = "Allow all HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Unrestricted access - MISCONFIGURATION
  }

  ingress {
    description = "Allow all HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Unrestricted access - MISCONFIGURATION
  }

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH open to world - CRITICAL MISCONFIGURATION
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devsecops-demo-sg"
    Environment = "demo"
  }
}

# MISCONFIGURATION 2: S3 bucket without encryption at rest
resource "aws_s3_bucket" "devsecops_demo_bucket" {
  bucket = "devsecops-demo-bucket-12345"

  tags = {
    Name        = "DevSecOps Demo Bucket"
    Environment = "demo"
  }

  # NO encryption configuration - MISCONFIGURATION
  # NO versioning enabled - MISCONFIGURATION
  # NO public access block - MISCONFIGURATION
}

# MISCONFIGURATION 3: S3 bucket with public ACL
resource "aws_s3_bucket_acl" "devsecops_demo_bucket_acl" {
  bucket = aws_s3_bucket.devsecops_demo_bucket.id
  acl    = "public-read"  # Public access - MISCONFIGURATION
}

# EC2 instance configuration
resource "aws_instance" "devsecops_demo_instance" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.devsecops_demo_sg.id]

  # MISCONFIGURATION 4: No encryption for root volume
  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    # encrypted = false (default) - MISCONFIGURATION
  }

  # MISCONFIGURATION 5: IMDSv1 enabled (should use IMDSv2)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "optional"  # Should be "required" for IMDSv2 - MISCONFIGURATION
  }

  tags = {
    Name        = "devsecops-demo-instance"
    Environment = "demo"
  }
}

output "instance_public_ip" {
  value       = aws_instance.devsecops_demo_instance.public_ip
  description = "Public IP of the EC2 instance"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.devsecops_demo_bucket.id
  description = "Name of the S3 bucket"
}
