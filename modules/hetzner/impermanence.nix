{
  config,
  lib,
  pkgs,
  userName,
  ...
}:

{
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/var/lib/sops-nix" # CRITICAL key needed on server
      "/var/lib/nixos" # CRITICAL for User/Group ID consistency
      "/var/lib/systemd" # Keeps timers and back-end state
      "/var/lib/containers" # Your Podman images and volumes
      {
        directory = "/var/lib/caddy"; # Caddy SSL/State -> must be caddy:caddy
        user = "caddy";
        group = "caddy";
      }
    ];
    files = [
      "/etc/machine-id" # CRITICAL for journald and network logs
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
    users.${userName} = {
      files = [
        ".bash_history" # Keep command history for convenience
      ];
    };
  };
}
