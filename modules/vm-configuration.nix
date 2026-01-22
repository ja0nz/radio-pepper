{
  config,
  pkgs,
  modulesPath,
  lib,
  vars,
  ...
}:

{
  # SOPS-NIX
  sops = {
    defaultSopsFormat = "yaml";
    defaultSopsFile = ../secrets/dev/dev.enc.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  environment.etc."ssh/ssh_host_ed25519_key" = {
    source = ../secrets/dev/ssh_host_ed25519_key;
    mode = "0600";
  };

  environment.etc."ssh/ssh_host_ed25519_key.pub" = {
    source = ../secrets/dev/ssh_host_ed25519_key.pub;
    mode = "0644";
  };

  # Disable login prompt / SSH only
  systemd.services."serial-getty@ttyS0".enable = false;

  microvm = {
    # Resources
    mem = 4096;
    vcpu = 4;
    volumes = [
      {
        mountPoint = "/var";
        image = "./.dev-local.img";
        size = 10000; # 10GB
      }
    ];
    shares = [
      {
        proto = "9p";
        tag = "ro-store";
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
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
        host.port = 2222;
        guest.port = vars.sshPort;
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
