# ╔══════════════════════════════════════════════════════════════════╗
# ║  ACME — centralized certificate management                       ║
# ╚══════════════════════════════════════════════════════════════════╝
{ config, ... }:
{
  host.partition.persist.extraDirectories = [
    {
      directory = "/var/lib/acme";
      user = "acme";
      group = "acme";
      mode = "0750";
    }
  ];

  sops.secrets = {
    cloudflare_dns_serv_api_token = {
      owner = "acme";
      group = "acme";
    };
    cloudflare_dns_auth_api_token = {
      owner = "acme";
      group = "acme";
    };
  };

  users.groups.cert-readers = { };
  users.users.kanidm.extraGroups = [ "cert-readers" ];
  users.users.traefik.extraGroups = [ "cert-readers" ];

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "admin@templelabs.net";
      dnsProvider = "cloudflare";
    };

    # ── templelabs.net (auth) ───────────────────────────────────
    # 
    certs."idm.templelabs.net" = {
      environmentFile = config.sops.secrets.cloudflare_dns_auth_api_token.path;
      group = "cert-readers";
      reloadServices = [ "kanidm.service" ];
    };

    # ── templelabs.org (services) ───────────────────────────────
    certs."auth.templelabs.org" = {
      environmentFile = config.sops.secrets.cloudflare_dns_serv_api_token.path;
      group = "cert-readers";
    };
  };
}
