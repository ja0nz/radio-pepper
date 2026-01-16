{
  config,
  pkgs,
  lib,
  sshPort,
  ...
}:

let
  username = "radio";
in
{
  # Basic system configuration
  system.stateVersion = "24.05";
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Networking
  networking = {
    hostName = "pepper";
    firewall = {
      enable = true;
      trustedInterfaces = [ "podman1" ];
      allowedTCPPorts = [
        sshPort
        80
        443
      ];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    ports = [
      sshPort
    ];
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Some helpers
  environment.shellAliases = {
    sd = "sudo shutdown now";
    sc = "systemctl";
    scs = "systemctl status";
    scu = "systemctl --user";
    start = "sudo systemctl start";
    stop = "sudo systemctl stop";
    restart = "sudo systemctl restart";
    jc = "journalctl";
    jcx = "journalctl -xeu";
    jcf = "journalctl -f";
    jcb = "journalctl -b";
    jcu = "journalctl -u";
    p = "sudo podman";
    pr = "sudo podman run -ti";
    ".." = "cd ..";
  };

  # User for running containers
  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    linger = true;
    description = "Container User";
    extraGroups = [
      "podman"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKVYORHTB+a29UzmlZNFU9UkEvIHhBZKzDgiof8Q4xkO remote-radio-pepper-key"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONWYt7n5qJC99fRPLxCcgzfB46qfAKXm3F+sgvbeT03 local-radio-pepper-key"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "${username}" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
