# See https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#configuring_ingress_features_through_backendconfig_parameters
resource "kubernetes_manifest" "backend_config" {
  provider = kubernetes-alpha

  manifest = {
    apiVersion = "cloud.google.com/v1beta1"
    kind       = "BackendConfig"

    metadata = {
      name      = var.backend_config
      namespace = var.kubernetes_namespace
      labels    = var.kubernetes_labels
    }

    spec = {
      timeoutSec = var.timeout_sec

      cdn = {
        enabled = var.cdn.enabled
        cachePolicy = { for k, v in {
          includeHost          = var.cdn.policy.include_host
          includeProtocol      = var.cdn.policy.include_protocol
          includeQueryString   = var.cdn.policy.include_query_string
          queryStringBlacklist = var.cdn.policy.query_string_blacklist
          queryStringWhitelist = var.cdn.policy.query_string_whitelist
          } : k => v if v != null
        }
      }

      connectionDraining = {
        drainingTimeoutSec = var.connection_draining_timeout_sec
      }

      healthCheck = { for k, v in {
        checkIntervalSec   = var.health_check.interval
        timeoutSec         = var.health_check.timeout
        healthyThreshold   = var.health_check.health_threshold
        unhealthyThreshold = var.health_check.unhealthy_threshold
        type               = var.health_check.protocol
        requestPath        = var.health_check.path
        port               = var.health_check.port
      } : k => v if v != null }

      securityPolicy = {
        name = var.cloud_armor_policy
      }

      logging = {
        enable     = var.logging.enable
        sampleRate = var.logging.sample_rate
      }

      iap = {
        enabled = var.iap != ""
        oauthclientCredentials = {
          secretName = var.iap
        }
      }

      sessionAffinity = {
        affinityType         = var.session_affinity.type
        affinityCookieTtlSec = coalesce(var.session_affinity.cookie_ttl_sec, 0)
      }

      customRequestHeaders = {
        headers = [for k, v in var.custom_request_headers : "${k}:${v}"]
      }
    }
  }
}
