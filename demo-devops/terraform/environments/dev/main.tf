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
  description = "Database password"
  type        = string
  sensitive   = true
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

  cluster_name     = "demo-devops-${var.environment}"
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  environment      = var.environment
  db_name          = "appdb"
  db_username      = var.db_username
  db_password      = var.db_password
  db_instance_class = "db.t3.micro"
}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  cluster_name = "demo-devops-${var.environment}"
  environment  = var.environment
  db_username  = var.db_username
  db_password  = var.db_password
  db_host      = module.rds.db_instance_endpoint
  db_port      = "5432"
  db_name      = "appdb"

  depends_on = [module.eks, module.rds]
}

output "cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "db_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = module.secrets_manager.db_secret_arn
}

output "irsa_role_arn" {
  description = "IRSA role ARN"
  value       = module.secrets_manager.irsa_role_arn
}