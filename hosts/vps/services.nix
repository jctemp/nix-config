{ config, ... }:
let
  domain = "jamie-temple.dev";
  ports = {
    grafana = 3000;
    authelia = 4000;
    prometheus = 9090;
    exporter = {
      node = 9091;
      zfs = 9092;
      wireguard = 9093;
      authelia = 9094;
      docker = 9095;
    };
  };
in
{
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  host.partition.persist.extraDirectories = [
    {
      directory = "/var/lib/grafana";
      user = "grafana";
      group = "grafana";
      mode = "0700";
    }
    {
      directory = "/var/lib/prometheus2";
      user = "prometheus";
      group = "prometheus";
      mode = "0700";
    }
    {
      directory = "/var/lib/traefik";
      user = "traefik";
      group = "docker";
      mode = "0700";
    }
    {
      directory = "/var/lib/authelia-home";
      user = "authelia-home";
      group = "authelia-home";
      mode = "0700";
    }
  ];

  services = {
    fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "24h";
      bantime-increment = {
        enable = true;
        multipliers = "1 2 4 8 16 32 64";
        maxtime = "168h";
        overalljails = true;
      };
      jails = {
        sshd = {
          enabled = true;
          settings = {
            backend = "systemd";
          };
        };
      };
    };

    # group = authelia-home
    authelia.instances.home = {
      enable = true;
      settings = {
        theme = "auto";
        telemetry.metrics = {
          enabled = true;
          address = "tcp://127.0.0.1:${toString ports.exporter.authelia}";
        };
        # We could a socket. For ease, we use localhost
        server.address = "tcp://127.0.0.1:${toString ports.authelia}/";
        default_2fa_method = "webauthn"; # fido2
        session = {
          name = "authelia_session";
          # https://owasp.org/www-community/SameSite
          same_site = "lax";
          # https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html
          inactivity = "5m";
          expiration = "1h";
          remember_me = "1M";
          cookies = [{
            domain = "jamie-temple.dev";
            authelia_url = "https://auth.jamie-temple.dev";
            name = "authelia_session";
          }];
        };
        storage = {
          local = { path = "/var/lib/authelia-home/db.sqlite3"; }; # Setup SQLite3 server
        };
        access_control = {
          default_policy = "deny";
          rules = [
            # { # TODO: add public website 
            #   domain = "jamie-temple.dev";
            #   policy = "bypass";
            # }
            {
              domain = "auth.jamie-temple.dev";
              policy = "bypass";
            }
            {
              domain = "grafana.jamie-temple.dev";
              subject = [ "group:admins" ];
              policy = "two_factor";
            }
            {
              domain = "*.jamie-temple.dev";
              subject = [ "group:users" "group:admins" ];
              policy = "two_factor";
            }
          ];
        };
        authentication_backend = {
          file.path = config.sops.secrets.authelia_users_db.path;
        };
        notifier = {
          filesystem.filename = "/var/lib/authelia-home/notifications.txt";
        };
      };
      secrets = {
        sessionSecretFile = config.sops.secrets.authelia_session_enc_key.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia_storage_enc_key.path;
        jwtSecretFile = config.sops.secrets.authelia_jwt_key.path;
        # oidcIssuerPrivateKeyFile = config.sops.secrets.authelia_oidc_issu_key.path;
        # oidcHmacSecretFile = config.sops.secrets.authelia_oidc_hmac_key.path;
      };
    };

    traefik = {
      enable = true;
      group = "docker";
      environmentFiles = [
        "${config.sops.secrets.traefik_admin_password.path}"
        "${config.sops.secrets.cloudflare_dns_api_token.path}"
      ];
      staticConfigOptions = {
        certificatesResolvers = {
          letsencrypt.acme = {
            email = "jamie.c.temple@gmail.com";
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            storage = "/var/lib/traefik/acme.json";
            dnsChallenge = {
              provider = "cloudflare";
              resolvers = [
                # Cloudflare DNS
                "1.1.1.1:53"
                "1.0.0.1:53"
              ];
            };
          };
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
        providers = {
          docker = {
            endpoint = "unix:///var/run/docker.sock";
            exposedByDefault = false;
          };
        };
      };
      dynamicConfigOptions = {
        tls = {
          options = {
            default = {
              minVersion = "VersionTLS13";
              sniStrict = true;
            };
          };
        };
        http = {
          middlewares = {
            auth.forwardAuth = {
              address = "http://127.0.0.1:${toString ports.authelia}/api/authz/forward-auth";
              trustForwardHeader = true;
              authResponseHeaders = [
                "Remote-User"
                "Remote-Groups"
                "Remote-Email"
                "Remote-Name"
              ];
            };
          };
          routers = {
            grafana-route = {
              service = "grafana";
              entryPoints = [ "websecure" ];
              rule = "Host(`grafana.jamie-temple.dev`)";
              tls.certResolver = "letsencrypt";
              middlewares = [ "auth" ];
              # observability = {
              #   metrics = true;
              #   accessLogs = true;
              #   tracing = true;
              # };
            };
            authelia-route = {
              service = "authelia";
              entryPoints = [ "websecure" ];
              rule = "Host(`auth.jamie-temple.dev`)";
              tls.certResolver = "letsencrypt";
            };
          };
          services = {
            grafana.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString ports.grafana}"; }];
            authelia.loadBalancer.servers = [{ url = "http://127.0.0.1:${toString ports.authelia}"; }];
          };
        };
      };
    };

    cadvisor = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = ports.exporter.docker;
    };

    prometheus = {
      enable = true;
      listenAddress = "127.0.0.1";
      port = ports.prometheus;
      retentionTime = "30d";
      globalConfig.scrape_interval = "30s";

      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" "processes" ];
          listenAddress = "127.0.0.1";
          port = ports.exporter.node;
        };
        zfs = {
          enable = true;
          listenAddress = "127.0.0.1";
          port = ports.exporter.zfs;
        };
      };

      scrapeConfigs = map
        (src:
          {
            job_name = src;
            static_configs = [{
              targets = [ "127.0.0.1:${toString ports.exporter.${src}}" ];
            }];
          }
        ) [ "node" "zfs" "docker" "authelia" ];
    };

    grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = ports.grafana;
          domain = "grafana.${domain}";
        };

        analytics.reporting_enabled = false;

        users = {
          allow_sign_up = false;
          allow_org_create = false;
        };

        auth = {
          disable_login_form = false;
        };

        security = {
          admin_user = "admin";
          admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
        };
      };

      provision = {
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:${toString config.services.prometheus.port}";
            isDefault = true;
          }
        ];
        dashboards.settings.providers = [
          {
            name = "default";
            options.path = "/etc/grafana/dashboards";
          }
        ];
      };
    };
  };
}

