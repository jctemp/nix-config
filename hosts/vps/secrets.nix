_: {
  sops.secrets = {
    grafana_admin_password = {
      owner = "grafana";
      group = "grafana";
    };
    traefik_admin_password = {
      owner = "traefik";
      group = "docker";
    };
    cloudflare_dns_api_token = {
      owner = "traefik";
      group = "docker";
    };
    authelia_session_enc_key = {
      owner = "authelia-home";
      group = "authelia-home";
    };
    authelia_storage_enc_key = {
      owner = "authelia-home";
      group = "authelia-home";
    };
    authelia_jwt_key = {
      owner = "authelia-home";
      group = "authelia-home";
    };
    authelia_users_db = {
      owner = "authelia-home";
      group = "authelia-home";
    };
  };
}
