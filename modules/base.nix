{
  vars,
  ...
}:

let
  hostKey = "/etc/ssh/mnt/ssh_host_ed25519_key";
in
{
  system.stateVersion = "24.05";
  time.timeZone = "Europe/Berlin";

  # SOPS-NIX
  sops = {
    defaultSopsFormat = "yaml";
    defaultSopsFile = ../secrets.enc.yaml;
    age.sshKeyPaths = [ hostKey ];
  };

  # Networking
  networking = {
    hostName = "pepper";
    hostId = "dbb1698a"; # random; needed for zfs
    firewall = {
      enable = true;
      trustedInterfaces = [ "podman1" ];
      allowedTCPPorts = [
        80
        443
      ];
    };
  };

  # SSH
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = hostKey;
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
  users.users.${vars.VIRT_USER} = {
    isNormalUser = true;
    uid = 1000;
    linger = true;
    description = "Container User";
    extraGroups = [
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEaSLRKnMbzk0OtGKEclUyUZytRdUL/CjZaFup5xcgoL"
    ];
  };

  security.sudo.extraRules = [
    {
      users = [ "${vars.VIRT_USER}" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
