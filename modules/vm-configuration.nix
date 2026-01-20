{
  config,
  pkgs,
  modulesPath,
  lib,
  sshPort,
  ...
}:

{
  # Import base VM configuration
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];
  system.stateVersion = "24.05";

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

  virtualisation = {
    # Non graphic / terminal only
    graphics = false;
    memorySize = 2048;
    diskSize = 10000;

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
        guest.port = sshPort;
      }
    ];
  };

  boot.kernelParams = [
    "console=ttyS0"
  ];

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
