//Declare → Pass → Accept → Create → Output → Reuse


module "networking" {
  source              = "./modules/networking"
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}



module "security" {
  source       = "./modules/security"
  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region
  vpc_id       = module.networking.vpc_id
}

module "rds" {
  source                = "./modules/rds"
  project_name          = var.project_name
  environment           = var.environment
  db_name               = var.db_name
  private_subnet_ids    = module.networking.private_subnet_id
  rds_security_group_id = module.security.rds_security_group_id
}

module "ec2" {
  source                = "./modules/ec2"
  project_name          = var.project_name
  environment           = var.environment
  subnet_id             = module.networking.private_subnet_id[0]
  ec2_security_group_id = module.security.ec2_security_group_id
}

module "vpc_endpoints" {
  source                     = "./modules/vpc_endpoints"
  project_name               = var.project_name
  environment                = var.environment
  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_subnet_id
  endpoint_security_group_id = module.security.ssm_endpoint_security_group_id
  aws_region                 = var.aws_region
  private_route_table_ids    = [module.networking.private_route_table_id]
}