#!/usr/bin/env bash

# === Create temporary workspace ===
WS=$(mktemp -d)
trap 'rm -rf "$WS"' EXIT
KEY_PATH="$WS/id_ed25519"
EXTRA_FILES="$WS/extra"

# --- Extract host keys for nixos-anywhere ---
install -d -m755 "$EXTRA_FILES/persist/etc/ssh/mnt"
sops -d --extract '["ssh_host_ed25519_key"]' "$SECRETS" \
     > "$EXTRA_FILES/persist/etc/ssh/mnt/ssh_host_ed25519_key"
sops -d --extract '["ssh_host_ed25519_key_pub"]' "$SECRETS" \
     > "$EXTRA_FILES/persist/etc/ssh/mnt/ssh_host_ed25519_key.pub"
chmod 600 "$EXTRA_FILES/persist/etc/ssh/mnt/ssh_host_ed25519_key"

# --- Extract deployment key for SSH access ---
sops -d --extract '["id_ed25519"]' "$SECRETS" > "$KEY_PATH"
chmod 600 "$KEY_PATH"

# === 5. Probe: Determine if NixOS is already running ===
export HCLOUD_TOKEN=$(sops -d --extract '["hetzner_api_token"]' "$SECRETS")
REMOTE_IP4=$(hcloud server ip "$HETZNER_SERVER_NAME")
echo "🔍 Probing $REMOTE_IP4 for environment state..."

if ssh -i "$KEY_PATH" "$VIRT_USER@$REMOTE_IP4" "[ -e /run/current-system ]"; then
    # --- 6a. Update: Run nixos-rebuild switch (In-place) ---
    echo "✅ NixOS detected. Updating via nixos-rebuild..."

    # Set the SSH options for the duration of this command
    export NIX_SSHOPTS="-i $KEY_PATH"
    nixos-rebuild switch \
        --flake "$FLAKE_ROOT#prod-remote" \
        --target-host "$VIRT_USER@$REMOTE_IP4" \
        --build-host "$VIRT_USER@$REMOTE_IP4" \
        --sudo

else
    # --- 6b. Install: Run nixos-anywhere (Fresh VPS) ---
    echo "🐣 Fresh VPS detected. Initializing with nixos-anywhere..."
    nix run github:nix-community/nixos-anywhere -- \
        --flake "$FLAKE_ROOT#prod-remote" \
        --extra-files "$EXTRA_FILES" \
        --target-host "root@$REMOTE_IP4" \
        -i "$KEY_PATH" \
        --build-on remote
fi
