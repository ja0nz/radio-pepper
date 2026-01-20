{
  config,
  pkgs,
  lib,
  sshPort,
  userName,
  ...
}:

{
  # Basic system configuration
  system.stateVersion = "24.05";
  boot = {
    supportedFilesystems = [ "zfs" ];
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.postDeviceCommands = lib.mkAfter ''
      # Verify pool is imported
      if ! zpool list zroot >/dev/null 2>&1; then
        echo "Importing zroot pool..."
        zpool import -f zroot
      fi

      # Rollback to blank snapshot
      echo "Rolling back root to blank state..."
      zfs rollback -r zroot/local/root@blank
    '';
  };
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };
  services.zfs.autoSnapshot.enable = true;

  # SOPS-NIX
  sops = {
    defaultSopsFormat = "yaml";
    defaultSopsFile = ../secrets/prod.enc.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
