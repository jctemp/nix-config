_: {
  sops.secrets = {
    grafana_admin_password = {
      owner = "grafana";
      group = "grafana";
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
