terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "your-terraform-state-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}

provider "aws" {
  region = "us-west-2"
}

provider "random" {}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_username" {
  description = "Database username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password (optional - will generate if not provided)"
  type        = string
  sensitive   = true
  default     = ""
}

module "vpc" {
  source = "../../modules/vpc"

  cluster_name    = "demo-devops-${var.environment}"
  vpc_cidr        = "10.0.0.0/16"
  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  environment     = var.environment
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = "demo-devops-${var.environment}"
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  environment     = var.environment
}

module "rds" {
  source = "../../modules/rds"

  cluster_name      = "demo-devops-${var.environment}"
  vpc_id            = module.vpc.vpc_id
  private_subnets   = module.vpc.private_subnets
  environment       = var.environment
  db_name           = "appdb"
  db_username       = var.db_username
  db_password       = var.db_password
  db_instance_class = "db.t3.micro"
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = false
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = module.rds.db_secret_arn
  sensitive   = false
}