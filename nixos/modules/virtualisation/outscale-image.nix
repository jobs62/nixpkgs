{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../profiles/headless.nix
    # Note: While we do use the headless profile, we also explicitly
    # turn on the serial console on ttyS0 below.
    ../profiles/qemu-guest.nix
  ];

  config = {
    boot.growPartition = true;

    fileSystems."/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
      autoResize = true;
    };

    boot.initrd.kernelModules = ["virtio_pci" "virtio_scsi" "sd_mod" "virtio_blk"];
    boot.kernelParams = [
      "console=tty0"
      "console=ttyS0,115200"
      "earlyprintk=ttyS0,115200"
      "consoleblank=0"
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.device = "/dev/xvdf";
    boot.loader.timeout = 1;
    boot.loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_output console serial
      terminal_input console serial
    '';

    # Allow root logins only using the SSH key that the user specified
    # at instance creation time.
    services.openssh.enable = true;
    services.openssh.settings.PermitRootLogin = "prohibit-password";

    # Enable the serial console on ttyS0
    systemd.services."serial-getty@ttyS0".enable = true;

    # Creates symlinks for block device names.
    services.udev.packages = [pkgs.osc-udev-rules];

    # Force getting the hostname from metadata server.
    networking.hostName = lib.mkDefault "";

    # udisks has become too bloated to have in a headless system
    # (e.g. it depends on GTK).
    services.udisks2.enable = false;

    # Setup cloud-init for first boot configuration
    services.cloud-init = {
      enable = true;
      network.enable = true;
      settings = {
        disable-ec2-metadata = false;
        datasource_list = ["Ec2"];
        datasource.Ec2 = {
          strict_id = false;
          metadata_urls = ["http://169.254.169.254:80"];
          timeout = 5;
          max_wait = 10;
        };
      };
    };
  };

  meta.maintainers = with lib.maintainers; [jobs62];
}
