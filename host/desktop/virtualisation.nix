{ pkgs, ... }:
{
  # ===============================================================
  #       CONTAINERS
  # ===============================================================
  virtualisation = {
    containers.enable = true;
    oci-containers.backend = "docker";
    docker = {
      enable = true;
      rootless.enable = true;
      autoPrune = {
        enable = true;
        dates = "weekly";
      };
    };
  };

  # ===============================================================
  #       LIBVIRT / KVM
  # ===============================================================
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.packages = [ pkgs.OVMFFull.fd ];
      };
    };
  };

  programs.virt-manager.enable = true;

  # ===============================================================
  #       VIRTUALISATION PACKAGES
  # ===============================================================
  environment.systemPackages = with pkgs; [
    dnsmasq
    libguestfs
  ];
}
