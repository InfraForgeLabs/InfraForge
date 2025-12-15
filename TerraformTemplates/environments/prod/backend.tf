
# Remote backend (fill in values or use addons/remote-backend.tf)
# terraform {
#   backend "s3" {
#     bucket         = "{{PROJECT}}-tfstate"
#     key            = "env/terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     dynamodb_table = "{{PROJECT}}-lock"
#   }
# }
