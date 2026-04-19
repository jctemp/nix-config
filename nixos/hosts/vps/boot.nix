_: {
  boot = {
    #       BOOTLOADER (GRUB)
    loader = {
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true;
        zfsSupport = true;
        device = "nodev";
      };
      efi.canTouchEfiVariables = false;
    };

    #       KERNEL PARAMETERS
    kernel.sysctl = {
      # TCP optimizations
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_syncookies" = 1;

      # Increase connection tracking for Docker
      "net.netfilter.nf_conntrack_max" = 262144;
    };
  };
}
