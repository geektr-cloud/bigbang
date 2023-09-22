terraform {
  backend "local" { path = "../.secret/tfstates/cloud-infra/terraform.tfstate" }
}
