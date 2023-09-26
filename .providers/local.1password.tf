# ln -s ../.secret/1password.tfvars ./1password.auto.tfvars
# ln -s ../.providers/local.1password.tf ./prov.1password.tf

#   onepasswordorg = {
#     source  = "golfstrom/onepasswordorg"
#     version = "1.0.0-rc.5"
#   }

variable "op_address" {
  type    = string
  default = "https://my.1password.com"
}
variable "op_email" { type = string }
variable "op_password" { type = string }
variable "op_secret_key" { type = string }

provider "onepasswordorg" {
  address    = var.op_address
  email      = var.op_email
  password   = var.op_password
  secret_key = var.op_secret_key
}
