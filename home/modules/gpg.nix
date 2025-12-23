{ pkgs, ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      # Use stronger algorithms
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";

      # Default key preferences
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";

      # When verifying a signature, ensure the key is valid
      verify-options = "show-uid-validity";
      list-options = "show-uid-validity";

      # Use full 16-character key IDs
      keyid-format = "0xlong";
      with-fingerprint = true;

      # Don't include version in output
      no-emit-version = true;
      no-comments = true;

      # Display photo ID
      photo-viewer = "${pkgs.feh}/bin/feh %i";

      # Use smartcard (Nitrokey)
      use-agent = true;
    };
  };

  services.gpg-agent = {
    enable = true;
    enableBashIntegration = true;

    defaultCacheTtl = 3600;
    defaultCacheTtlSsh = 3600;
    maxCacheTtl = 7200;
    maxCacheTtlSsh = 7200;

    pinentry.package = pkgs.pinentry-curses;

    extraConfig = ''
      # Smartcard daemon
      scdaemon-program ${pkgs.gnupg}/libexec/scdaemon
    '';
  };

  home.packages = with pkgs; [
    paperkey
  ];
}
