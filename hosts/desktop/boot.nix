_: {
  boot = {
    #       BOOTLOADER
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi.canTouchEfiVariables = true;
    };

    #       EMULATION SUPPORT
    binfmt.emulatedSystems = [
      "x86_64-windows"
      "aarch64-linux"
    ];

    #       KERNEL PARAMETERS
    kernel.sysctl = {
      # TCP optimizations
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_syncookies" = 1;
    };
  };
}
