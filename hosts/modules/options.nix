{ lib, ... }: {

  options.host = {
    settings = {
      name = lib.mkOption { type = lib.types.str; };
      stateVersion = lib.mkOption { type = lib.types.str; };
      timeZone = lib.mkOption { type = lib.types.str; };
      defaultLocale = lib.mkOption { type = lib.types.str; };
      extraLocale = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
      keyboardLayout = lib.mkOption { type = lib.types.str; default = "us"; };
    };
    users = {
      primary = lib.mkOption { type = lib.types.str; };
      collection = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
      admins = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
      };
    };
    partition = {
      device = lib.mkOption { type = lib.types.str; };
      persist.path = lib.mkOption {
        default = "/persist";
        type = lib.types.str;
      };
      boot.size = lib.mkOption {
        default = "1M";
        type = lib.types.str;
      };
      esp.size = lib.mkOption {
        default = "512M";
        type = lib.types.str;
      };
      swap.size = lib.mkOption {
        default = "4G";
        type = lib.types.str;
      };
      root.size = lib.mkOption {
        default = "100%";
        type = lib.types.str;
      };
    };
  };
}
