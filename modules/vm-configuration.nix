{
  config,
  lib,
  vars,
  ...
}:

let
  secretDir = "/etc/ssh/mnt";
in
{
  # Disable login prompt / SSH only
  systemd.services."serial-getty@ttyS0".enable = false;
  fileSystems."${secretDir}".neededForBoot = true;

  microvm = {
    # Resources
    mem = 4096;
    vcpu = 4;
    volumes = [
      {
        mountPoint = "/var";
        image = "./.dev-var.img";
        size = 7000; # 7GB
      }
    ];
    shares = [
      {
        proto = "9p";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        readOnly = true;
      }
      {
        proto = "9p";
        tag = "dev-host-key";
        source = ".dev-host-key";
        mountPoint = "${secretDir}";
      }
    ];

    interfaces = [
      {
        type = "user";
        id = "vm-eth0";
        mac = "02:00:00:00:00:01";
      }
    ];
    forwardPorts = [
      {
        from = "host";
        host.port = 8080;
        guest.port = 80;
      }
      {
        from = "host";
        host.port = 8443;
        guest.port = 443;
      }
      {
        from = "host";
        host.port = vars.DEV_SSH_PORT;
        guest.port = 22;
      }
      # Azuracast
      {
        from = "host";
        host.port = 2022;
        guest.port = 2022;
      }
      {
        from = "host";
        host.port = 8000;
        guest.port = 8000;
      }
    ];

    hypervisor = "qemu";
    socket = "control.socket";
  };

  # [22.01.2026] Fix: fix for hanging endless in shutdown sequence
  # See:
  # https://github.com/microvm-nix/microvm.nix/commit/736d43ae8552653ea8ad51fc8c79288668c866a5
  # https://github.com/microvm-nix/microvm.nix/pull/381
  systemd.mounts = lib.mkIf config.boot.initrd.systemd.enable [
    {
      what = "store";
      where = "/nix/store";
      # Generate a `nix-store.mount.d/overrides.conf`
      overrideStrategy = "asDropin";
      unitConfig.DefaultDependencies = false;
    }
  ];
}
