output "tfe_url" {
  description = "URL of TFE FDO"
  value       = "https://${var.route53_subdomain}.${var.route53_zone}"
}