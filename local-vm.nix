{
  config,
  pkgs,
  modulesPath,
  lib,
  ...
}:

{
  # Import base VM configuration
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  # VM settings
  virtualisation = {
    # Non graphic
    graphics = false;

    # Memory for the VM
    memorySize = 2048;

    # Disk size
    diskSize = 10000; # 10GB

    # Forward ports from VM to host
    forwardPorts = [
      {
        from = "host";
        host.port = 8080;
        guest.port = 80;
      } # HTTP
      {
        from = "host";
        host.port = 8443;
        guest.port = 443;
      } # HTTPS
      {
        from = "host";
        host.port = lib.toInt (builtins.getEnv "SSH_PORT");
        guest.port = lib.toInt (builtins.getEnv "SSH_PORT");
      } # SSH
    ];
  };

  boot = {
    loader.grub.enable = true;
    kernelParams = [
      "console=ttyS0"
    ];
  };

  # Disable login
  systemd.services."serial-getty@ttyS0".enable = false;

  # Welcome Banner
  systemd.services.boot-banner = {
    description = "Print Welcome Banner to Console";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      # StandardOutput=tty tells systemd to send this specifically to the console
      StandardOutput = "tty";
      TTYPath = "/dev/ttyS0";
      RemainAfterExit = true;
    };

    script = ''
      echo -e "\n\e[1;32m============================================\e[0m"
      echo -e "\e[1;32m   🚀 NIXOS CLOUD VM IS READY\e[0m"
      echo -e "\e[1;32m============================================\e[0m"
      echo -e "   Mode:      Local Development"
      echo -e "   Services:  Caddy -> http://whoami.local:8080"
      echo -e "              Whoami -> Port 8081"
      echo -e ""
      echo -e "   Access:    Run 'dev-ssh' in a new terminal"
      echo -e "\e[1;32m============================================\e[0m\n"
    '';
  };
}
