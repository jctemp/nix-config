{ config, ... }:
let
  domain = "auth.templelabs.org";
  port = "4180";
  kanidmDomain = "idm.templelabs.net";
  clientId = "oauth2-proxy";
in
{
  # ── 1. Persistence ──────────────────────────────────────────────
  # oauth2-proxy is stateless — no persistence needed

  # ── 2. Secrets ──────────────────────────────────────────────────
  sops.secrets = {
    "kanidm/oauth2-basic-secrets/oauth2-proxy" = {
      owner = "kanidm";
      group = "kanidm";
      mode = "0440";
    };
    "oauth2-proxy/env" = {
      owner = "oauth2-proxy";
    };
  };

  # ── 3. Service ──────────────────────────────────────────────────
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = clientId;
    oidcIssuerUrl = "https://${kanidmDomain}/oauth2/openid/${clientId}";

    httpAddress = "127.0.0.1:${port}";
    reverseProxy = true;
    setXauthrequest = true;

    email.domains = [ "*" ]; # Kanidm handles authorization via groups

    cookie = {
      domain = ".templelabs.org";
      secure = true;
      httpOnly = true;
      expire = "72h";
      refresh = "30m";
    };

    extraConfig = {
      skip-provider-button = true; # go straight to Kanidm login
      code-challenge-method = "S256";
    };

    keyFile = config.sops.secrets."oauth2-proxy/env".path;
  };

  # ── 4. Kanidm OIDC client ──────────────────────────────────────
  services.kanidm.provision.systems.oauth2.${clientId} = {
    displayName = "OAuth2 Proxy";
    originUrl = "https://${domain}/oauth2/callback";
    originLanding = "https://${domain}/";
    preferShortUsername = true;
    basicSecretFile = config.sops.secrets."kanidm/oauth2-basic-secrets/oauth2-proxy".path;
    scopeMaps.oauth2_proxy_access = [ "openid" "email" "profile" ];
  };

  services.kanidm.provision.groups.oauth2_proxy_access = { };

  # ── 5. Traefik ──────────────────────────────────────────────────
  services.traefik.dynamicConfigOptions = {
    http = {
      # The forwardAuth middleware — every other service references this
      middlewares.kanidm-auth.forwardAuth = {
        address = "http://127.0.0.1:${port}/oauth2/auth";
        trustForwardHeader = true;
        authResponseHeaders = [
          "X-Auth-Request-User"
          "X-Auth-Request-Email"
          "X-Auth-Request-Groups"
        ];
      };

      # oauth2-proxy's own routes
      routers.oauth2-proxy = {
        rule = "Host(`${domain}`)";
        entryPoints = [ "websecure" ];
        service = "oauth2-proxy";
        tls = { };
      };
      services.oauth2-proxy.loadBalancer.servers = [
        { url = "http://127.0.0.1:${port}"; }
      ];
    };
    tls.certificates = [
      {
        certFile = "/var/lib/acme/${domain}/fullchain.pem";
        keyFile = "/var/lib/acme/${domain}/key.pem";
      }
    ];
  };

  # ── 6. Backups ──────────────────────────────────────────────────
  # Stateless — no backups needed

  # ── 7. Monitoring ───────────────────────────────────────────────
  # Uptime Kuma: https://auth.templelabs.org/ping

  # ── 8. Firewall ─────────────────────────────────────────────────
  # No ports opened — Traefik proxies, service binds to 127.0.0.1

}
