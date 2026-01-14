{
  config,
  pkgs,
  lib,
  ...
}:

let
  username = builtins.getEnv "USER";
in
{
  # Basic system configuration
  system.stateVersion = "24.05";

  # Networking
  networking = {
    hostName = "pepper";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        (lib.toInt (builtins.getEnv "SSH_PORT"))
        80
        443
      ];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    ports = [
      (lib.toInt (builtins.getEnv "SSH_PORT"))
    ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
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
      (builtins.getEnv "SSH_PUB")
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
