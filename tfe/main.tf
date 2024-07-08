data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

data "azurerm_kubernetes_cluster" "tfe" {
  name                = data.terraform_remote_state.infra.outputs.cluster_name
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.tfe.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.tfe.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.tfe.kube_config.0.cluster_ca_certificate)
  }
}

locals {
  full_chain = "${acme_certificate.certificate.certificate_pem}${acme_certificate.certificate.issuer_pem}"
}

# SSL certificate
resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.cert_private_key.private_key_pem
  email_address   = var.cert_email
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = "${var.route53_subdomain}.${var.route53_zone}"

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.selected.zone_id
    }
  }
}

resource "aws_acm_certificate" "cert" {
  private_key       = acme_certificate.certificate.private_key_pem
  certificate_body  = acme_certificate.certificate.certificate_pem
  certificate_chain = acme_certificate.certificate.issuer_pem
}

resource "kubernetes_namespace" "terraform-enterprise" {
  metadata {
    name = "terraform-enterprise"
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name      = "terraform-enterprise"
    namespace = "terraform-enterprise"
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "images.releases.hashicorp.com": {
      "auth": "${base64encode("terraform:${var.tfe_license}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "helm_release" "tfe" {
  name       = "terraform-enterprise"
  repository = "helm.releases.hashicorp.com"
  chart      = "hashicorp/terraform-enterprise"
  namespace  = "terraform-enterprise"

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count            = var.replica_count
      fqdn                     = "${var.route53_subdomain}.${var.route53_zone}"
      full_chain               = "${base64encode(local.full_chain)}"
      private_key              = "${base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))}"
      pg_dbname                = data.terraform_remote_state.infra.outputs.pg_dbname
      pg_user                  = data.terraform_remote_state.infra.outputs.pg_user
      pg_password              = data.terraform_remote_state.infra.outputs.pg_password
      pg_address               = data.terraform_remote_state.infra.outputs.pg_address
      pg_dbname                = data.terraform_remote_state.infra.outputs.pg_dbname
      storage_account          = data.terraform_remote_state.infra.outputs.storage_account
      storage_account_key      = data.terraform_remote_state.infra.outputs.storage_account_key
      container_name           = data.terraform_remote_state.infra.outputs.container_name
      redis_host               = data.terraform_remote_state.infra.outputs.redis_host
      redis_primary_access_key = data.terraform_remote_state.infra.outputs.redis_primary_access_key
      tfe_license              = var.tfe_license
      tfe_release              = var.tfe_release
      enc_password             = var.tfe_encryption_password
    })
  ]
  depends_on = [
    kubernetes_secret.example, kubernetes_namespace.terraform-enterprise
  ]
}

data "kubernetes_service" "tfe" {
  metadata {
    name      = "terraform-enterprise"
    namespace = "terraform-enterprise"
  }
  depends_on = [helm_release.tfe]
}

# DNS
data "aws_route53_zone" "selected" {
  name         = var.route53_zone
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.route53_subdomain}.${var.route53_zone}"
  type    = "A"
  ttl     = "300"
  records = [data.kubernetes_service.tfe.status.0.load_balancer.0.ingress.0.ip]

  depends_on = [helm_release.tfe]
}