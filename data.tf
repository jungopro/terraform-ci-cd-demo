### Get ACR Data

/*data "helm_repository" "acr" {
  name     = var.repo_name
  url      = "https://${var.repo_name}.azurecr.io/helm/v1/repo"
  username = var.repo_username
  password = var.repo_password
}

data "helm_repository" "stable" {
  name     = "stable"
  url      = "https://kubernetes-charts.storage.googleapis.com"
}*/