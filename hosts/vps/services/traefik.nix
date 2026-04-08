_:
{
  # ── Persistence ──────────────────────────────────────────────
  host.partition.persist.extraDirectories = [
    {
      directory = "/var/lib/traefik";
      user = "traefik";
      group = "traefik";
      mode = "0750";
    }
  ];

  # ── Service ──
  networking.firewall.allowedTCPPorts = [ 443 ];
  services = {
    traefik = {
      enable = true;
      staticConfigOptions = {
        api = {
          insecure = true;
          dashboard = true;
        };
        entryPoints = {
          web = {
            address = ":80";
            http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
              permanent = true;
            };
          };
          websecure = {
            address = ":443";
          };
        };
      };
      dynamicConfigOptions.tls.options = {
        default = {
          minVersion = "VersionTLS13";
          sniStrict = true;
        };
      };
    };
  };

  systemd.services.traefik = {
    after = [
      "acme-finished-idm.templelabs.net.target"
      "acme-finished-auth.templelabs.org.target"
    ];
    wants = [
      "acme-finished-idm.templelabs.net.target"
      "acme-finished-auth.templelabs.org.target"
    ];
  };
}
