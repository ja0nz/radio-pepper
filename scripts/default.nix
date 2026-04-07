{
  pkgs,
}:
let
  sopsExe = pkgs.lib.getExe pkgs.sops;
  # sysCtl = pkgs.lib.getExe' pkgs.systemd "systemctl";
  jCtl = pkgs.lib.getExe' pkgs.systemd "journalctl";
  script = pkgs.writeShellScriptBin;

  mkscript =
    name: body:
    script name ''
      set -e
      NAME="$1"
      if [ -z "$NAME" ]; then
        echo "Usage: ${name} <name>"
        exit 1
      fi
      ${body}
    '';
in
{
  deploy-vm = script "deploy-vm" (builtins.readFile ./deploy-vm.sh);
  deploy-remote = script "deploy-remote" (builtins.readFile ./deploy-remote.sh);

  ssh-local = script "ssh-local" ''
    # Connect SSH on port $DEV_SSH_PORT ...

    echo "waiting for local VM to accept connections..."
    until nc -z localhost "$DEV_SSH_PORT"; do sleep 1; done

    # Extracting the SSH key with sops
    KEY_PATH=$(mktemp)
    trap 'rm -f "$KEY_PATH"' EXIT
    chmod 600 "$KEY_PATH"
    ${sopsExe} -d --extract '["id_ed25519"]' "$SECRETS" > "$KEY_PATH"

    export NIX_SSHOPTS="-o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p $DEV_SSH_PORT -i $KEY_PATH"
    ssh $NIX_SSHOPTS $VIRT_USER@localhost
  '';

  ssh-remote = script "ssh-remote" ''
    # Connect SSH on port 22...

    export HCLOUD_TOKEN=$(sops -d --extract '["hetzner_api_token"]' "$SECRETS")
    # Check if the variable is empty
    if [ -z "$HCLOUD_TOKEN" ]; then
        echo "❌ Error: HCLOUD_TOKEN is not set."
        echo "💡 Hint: Ensure you can access $SECRETS for the token."
        exit 1
    fi

    echo "waiting for remote VM to accept connections..."
    REMOTE_IP4=$(hcloud server ip "$HETZNER_SERVER_NAME")
    until nc -z $REMOTE_IP4 22; do sleep 1; done

    KEY_PATH=$(mktemp)
    trap 'rm -f "$KEY_PATH"' EXIT
    chmod 600 "$KEY_PATH"
    ${sopsExe} -d --extract '["id_ed25519"]' "$SECRETS" > "$KEY_PATH"

    export NIX_SSHOPTS="-o IdentitiesOnly=yes -i $KEY_PATH"
    ssh $NIX_SSHOPTS $VIRT_USER@$REMOTE_IP4
  '';

  vm-log-follow = mkscript "vm-log-follow" ''
    ${jCtl} -u microvm@$NAME.service -f
  '';
}
