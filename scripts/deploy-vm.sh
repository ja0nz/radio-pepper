#!/usr/bin/env bash

if ! nc -z localhost 2222 2>/dev/null; then
    echo "🌐 SSH port 2222 is closed. Starting a new VM..."

    SSH_KEY_DIR="$FLAKE_ROOT/.dev-host-key"
    SSH_HOST_KEY="$SSH_KEY_DIR/ssh_host_ed25519_key"

    # Create directory if it doesn't exist
    mkdir -p "$SSH_KEY_DIR"

    # Extract Private Key
    sops -d --extract '["ssh_host_ed25519_key"]' "$FLAKE_ROOT/secrets.enc.yaml" | \
        tee "$SSH_HOST_KEY" > /dev/null
    chmod 600 "$SSH_HOST_KEY"

    nix run $FLAKE_ROOT#dev-local
else
    echo "✅ VM is already running on port 2222. Switching configuration..."

    # --- Original switch-vm logic ---
    # Build the VM configuration on the host
    echo "🔨 Building VM configuration..."
    TARGET_PATH=$(nix build --no-substitute $FLAKE_ROOT#nixosConfigurations.dev-local.config.system.build.toplevel --print-out-paths)

    if [ -z "$TARGET_PATH" ]; then
        echo "❌ Build failed"
        exit 1
    fi

    echo "🚀 Switching running VM to: $TARGET_PATH"

    # Extracting the remote SSH key with sops
    KEY_PATH=$(mktemp)
    trap 'rm -f "$KEY_PATH"' EXIT
    chmod 600 "$KEY_PATH"
    sops -d --extract '["id_ed25519"]' "$FLAKE_ROOT/secrets.enc.yaml" \
        > "$KEY_PATH"

    export NIX_SSHOPTS="-o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p 2222 -i $KEY_PATH"
    # Find the HM generation path referenced by the service and copy its closure
    HM_GEN_PATH=$(grep -oP '/nix/store/\S+-home-manager-generation' \
        "$TARGET_PATH/etc/systemd/system/home-manager-containers.service" | head -1)
    if [ -z "$HM_GEN_PATH" ]; then
        echo "⚠️  No HM generation found in service file, skipping copy"
    else
        echo "📦 Copying HM generation to remote: $HM_GEN_PATH"
        nix copy --no-substitute --to "ssh://$USER@localhost" "$HM_GEN_PATH"
    fi

    # Run the switch command inside the VM via SSH
    ssh $NIX_SSHOPTS $USER@localhost "sudo $TARGET_PATH/bin/switch-to-configuration switch"
fi
