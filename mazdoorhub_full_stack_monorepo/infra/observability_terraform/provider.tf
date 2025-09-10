terraform {
  required_version = ">= 1.5.0"
  required_providers { aws = { source = "hashicorp/aws", version = "~> 5.47" } }
}
provider "aws" { region = var.region }
variable "region" { default = "ap-south-1" }
variable "alarm_email" { type = string }
variable "dashboard_name" { type = string  default = "MazdoorHub-Prod" }
variable "rds_instance_id" { type = string }
variable "api_gateway_id" { type = string }   # HTTP API ID
variable "ws_api_id" { type = string }        # WebSocket API ID
variable "lambda_function_names" { type = list(string), default = [] }
