terraform {
  backend "local" { path = "../.secret/tfstates/startup/terraform.tfstate" }
  required_providers {
    onepasswordorg = {
      source  = "golfstrom/onepasswordorg"
      version = "1.0.0-rc.5"
    }
  }
}
