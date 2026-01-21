{
  vars,
  ...
}:

{
  # Networking
  networking = {
    hostName = "pepper";
    hostId = "dbb1698a";
    firewall = {
      enable = true;
      trustedInterfaces = [ "podman1" ];
      allowedTCPPorts = [
        vars.sshPort
        80
        443
      ];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    ports = [
      vars.sshPort
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
    pr = "sudo podman exec -ti";
    ".." = "cd ..";
  };

  # User for running containers
  users.users.${vars.userName} = {
    isNormalUser = true;
    uid = 1000;
    linger = true;
    description = "Container User";
    extraGroups = [
      "podman"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaSLRKnMbzk0OtGKEclUyUZytRdUL/CjZaFup5xcgoL production"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKqGxrOa157jODZxdEH9RBclmSE8YmwO40S5owCAtDKU development"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "${vars.userName}" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
