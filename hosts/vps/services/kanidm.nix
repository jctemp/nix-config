{ config, pkgs, ... }:
let
  domain = "idm.templelabs.net";
  port = 8443;
in
{
  # ── 1. Persistence ──────────────────────────────────────────────
  host.partition.persist.extraDirectories = [
    {
      directory = "/var/lib/kanidm";
      user = "kanidm";
      group = "kanidm";
      mode = "0750";
    }
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/kanidm/backups 0700 kanidm kanidm -"
  ];

  # ── 2. Secrets ──────────────────────────────────────────────────
  sops.secrets = {
    "kanidm/admin-password" = {
      owner = "kanidm";
      group = "kanidm";
    };
    "kanidm/idm-admin-password" = {
      owner = "kanidm";
      group = "kanidm";
    };
  };

  # ── 3. Service ──────────────────────────────────────────────────
  services.kanidm = {
    enableServer = true;
    enableClient = true;
    package = pkgs.kanidmWithSecretProvisioning_1_9;
    serverSettings = {
      version = "2";
      bindaddress = "127.0.0.1:${toString port}";
      db_fs_type = "other"; # zfs as fs type requires 64k record size
      tls_chain = "/var/lib/acme/idm.templelabs.net/fullchain.pem";
      tls_key = "/var/lib/acme/idm.templelabs.net/key.pem";
      inherit domain;
      origin = "https://${domain}";
      http_client_address_info.x-forward-for = [ "127.0.0.1" ];
      online_backup = {
        path = "/var/lib/kanidm/backups";
        schedule = "0 0 1,14 * *"; # backup first and 14th day of the month
      };
    };
    clientSettings = {
      uri = "https://${domain}:${toString port}";
      verify_ca = true;
      verify_hostnames = true;
    };
    provision = {
      enable = true;
      instanceUrl = "https://${domain}:${toString port}";
      autoRemove = true;
      adminPasswordFile = config.sops.secrets."kanidm/admin-password".path;
      idmAdminPasswordFile = config.sops.secrets."kanidm/idm-admin-password".path;
      groups = {
        oauth2_proxy_access = { };
      };
    };
  };

  # ── 4. Traefik ──────────────────────────────────────────────────
  # kanidm-auth middleware defined in oauth2-proxy.nix
  services.traefik.dynamicConfigOptions = {
    http = {
      serversTransports.kanidm = {
        serverName = domain;
      };

      routers.idm = {
        rule = "Host(`${domain}`)";
        entryPoints = [ "websecure" ];
        service = "idm";
        tls = { };
      };

      services.idm.loadBalancer = {
        servers = [{ url = "https://127.0.0.1:${toString port}"; }];
        serversTransport = "kanidm";
      };
    };

    tls.certificates = [
      {
        certFile = "/var/lib/acme/${domain}/fullchain.pem";
        keyFile = "/var/lib/acme/${domain}/key.pem";
      }
    ];
  };

  # ── 5. Backups ──────────────────────────────────────────────────
  # Add to Restic include list: /var/lib/SERVICE_DIR

  # ── 6. Monitoring ───────────────────────────────────────────────
  # Uptime Kuma: https://SERVICE_NAME.templelabs.org/health
  # Prometheus exporter if available

  # ── 7. Firewall ─────────────────────────────────────────────────
  # No ports opened — Traefik proxies, service binds to 127.0.0.1
  #
  systemd.services.kanidm = {
    after = [ "acme-finished-idm.templelabs.net.target" ];
    wants = [ "acme-finished-idm.templelabs.net.target" ];
    serviceConfig.BindReadOnlyPaths = [ "/var/lib/acme/idm.templelabs.net" ];
  };

  networking.hosts = {
    "127.0.0.1" = [ "idm.templelabs.net" ];
  };
}
