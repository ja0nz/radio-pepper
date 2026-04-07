{
  vars,
  ...
}:

{
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    directories = [
      "/var/log"
      "/etc/ssh/mnt"
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
      "/etc/zfs/zpool.cache"
    ];
    users.${vars.VIRT_USER} = {
      files = [
        ".bash_history" # Keep command history for convenience
      ];
    };
  };
}
