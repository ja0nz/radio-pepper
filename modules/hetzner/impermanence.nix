{
  config,
  lib,
  pkgs,
  userName,
  ...
}:

{
  environment.persistence."/persist" = {
    directories = [
      "/etc/ssh"
      "/var/log"
      "/var/lib/nixos" # CRITICAL for User/Group ID consistency
      "/var/lib/systemd" # Keeps timers and back-end state
      "/var/lib/containers" # Your Podman images and volumes
      "/var/lib/caddy" # Caddy SSL/State
    ];
    files = [
      "/etc/machine-id" # CRITICAL for journald and network logs
    ];
    users.${userName} = {
      files = [
        ".bash_history" # Keep command history for convenience
      ];
    };
  };
}
