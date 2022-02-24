variable "cloudflare_email" {
  description = "cloudflare email"
  type        = string
}

variable "cloudflare_api_key" {
  description = "cloudflare api key"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "cloudflare zone id"
  type        = string
}

provider "cloudflare" {
  email   = var.cloudflare_email
  api_key = var.cloudflare_api_key
}

resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = data.hcloud_load_balancer.traefik.ipv4
  type    = "A"
  proxied = true
  ttl     = 1
}
