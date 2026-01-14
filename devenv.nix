{ pkgs, config, ... }:

{
  # Development packages
  packages = with pkgs; [
    git
    hcloud # Command-line interface for Hetzner Cloud
    secretspec # Declarative secrets, every environment, any provider
  ];

  # Environment variables
  env = {
    USER = "radio";
    SSH_PORT = "22";
    REMOTE_IP4 = "91.98.131.171";

    # Used: ./configuration.nix
    SSH_PUB = config.secretspec.secrets.SSH_PUB;
  };

  git-hooks.hooks = {
    # format *.nix
    nixfmt-rfc-style.enable = true;
  };

  # Scripts for local development and deployment
  scripts = {
    # Run locally in a VM
    vm-start.exec = ''
      echo "🚀 Starting local VM..."
      echo "This will start a NixOS VM with your configuration"
      echo "The VM will be accessible at: http://localhost:8080"
      echo ""

      mkdir -p "$DEVENV_ROOT/.devenv/state/vm"
      export NIX_DISK_IMAGE="$DEVENV_ROOT/.devenv/state/vm/local.qcow2"

      $DEVENV_ROOT/build/vm/bin/run-pepper-vm
    '';

    # Build the VM without starting it
    vm-build.exec = ''
      echo "Building VM..."

      nix build --impure "$DEVENV_ROOT#nixosConfigurations.dev-local.config.system.build.vm" -o "$DEVENV_ROOT/build/vm"
      echo "✅ VM built! Run 'vm-start' to launch it"
    '';

    # # Test build without running
    # test-build.exec = ''
    #   echo "Testing configuration build..."
    #   nix build .#nixosConfigurations.dev-local.config.system.build.toplevel
    #   echo "✅ Configuration builds successfully!"
    # '';

    # Deploy to remote server (when ready)
    deploy.exec = ''
      echo "Deploying to $REMOTE_IP4..."
      nix run --extra-experimental-features \
        'nix-command flakes' github:nix-community/nixos-anywhere -- \
          --flake .#prod-remote \
          --target-host root@$REMOTE_IP4 \
          --build-on-remote
    '';

    # SSH into local vm
    dev-ssh.exec = ''
      export SECRETSPEC_PROFILE=development 
      echo "waiting for local VM to accept connections..."
      # Wait until SSH is actually listening on port $SSH_PORT
      until nc -z localhost $SSH_PORT; do sleep 1; done

      ssh -i $(${pkgs.secretspec}/bin/secretspec get SSH_KEY) \
        -o IdentitiesOnly=yes \
        -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        $USER@localhost -p $SSH_PORT
    '';

    # SSH into remote
    prod-ssh.exec = ''
      export SECRETSPEC_PROFILE=production

      ssh -i $(${pkgs.secretspec}/bin/secretspec get SSH_KEY) \
        -o IdentitiesOnly=yes \
        $USER@$REMOTE_IP4 -p $SSH_PORT
    '';
  };

  # Startup message
  enterShell = ''
    echo "🌥️  Radio Pepper"
    echo ""
    echo "📍 Local development mode"
    echo ""
    echo "Available commands:"
    echo "  vm-build      - Build the test VM"
    echo "  vm-start      - Start the test VM"
    echo "  test-build    - Test configuration without VM"
    echo ""
    echo "📍 Remote deployment mode"
    echo "Server: $REMOTE_IP4"
    echo ""
    echo "Available commands:"
    echo "  deploy        - Deploy to remote server"
    echo "  dev-ssh       - SSH into local server"
    echo "  prod-ssh      - SSH into prodo server"
    echo ""
  '';
}
