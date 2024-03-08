resource "helm_release" "vault-installation" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault" 
  

  values = [
    "${file("values.yaml")}"
  ]
}