variable "route53_zone" {
  description = "The domain used in the URL"
  type        = string
}

variable "route53_subdomain" {
  description = "The subdomain of the URL"
  type        = string
}

variable "cert_email" {
  description = "Email address used to obtain SSL certificate"
  type        = string
}

variable "region" {
  type        = string
  description = "The region to deploy resources in"
}

variable "tfe_encryption_password" {
  description = "TFE encryption password"
  type        = string
}

variable "tfe_release" {
  description = "Which release version of TFE to install"
  type        = string
}

variable "tfe_license" {
  description = "Value from the License file"
  type        = string
}

variable "replica_count" {
  description = "Number of Pods/replicas"
  type        = string
}
