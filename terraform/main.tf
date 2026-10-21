locals {
  name_prefix = var.project_name
}

module "functions" {
  source      = "./modules/functions"
  name_prefix = local.name_prefix
  location    = var.location
  environment = var.environment
}
