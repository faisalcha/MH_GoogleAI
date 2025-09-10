terraform { required_version = ">= 1.5.0" required_providers { aws = { source="hashicorp/aws", version="~> 5.47" } } } provider "aws" { region = var.region }
variable "region" { default = "ap-south-1" } variable "api_gw_arn" { type = string } variable "db_secret_name" { type = string, default = "mazdoorhub/db/app_user" }
