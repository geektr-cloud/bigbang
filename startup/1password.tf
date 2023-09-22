resource "onepasswordorg_vault" "terraform" {
  name        = "Terraform"
  description = "Managed by Terraform"
}

resource "onepasswordorg_item" "aliyun" {
  vault    = onepasswordorg_vault.terraform.id
  title    = "terraform/aliyun-ram"
  category = "login"

  username = var.ali_key
  password = var.ali_secret
  url      = "https://terraform.io"
  tags     = ["terraform"]
}
