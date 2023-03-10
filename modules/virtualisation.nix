{ pkgs, ... }:
{
  config = {
    # Not using NixOS containers currently
    boot.enableContainers = false;

    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true; # docker alias
      };
      oci-containers.backend = "podman";
    };

    xameer.persistence.dirs = [
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"
    ];

    environment.systemPackages = with pkgs; [
      virt-manager
      virtiofsd
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        ovmf.enable = true;
        runAsRoot = false;
      };
      onBoot = "ignore";
      onShutdown = "shutdown";
    };
  };
}
