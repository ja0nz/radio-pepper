# Radio Pepper

A NixOS-based internet radio station setup with WordPress for content management and AzuraCast for broadcasting.

## Features

- **WordPress**: Content management system for radio station website
- **AzuraCast**: Professional internet radio broadcasting software
- **NixOS**: Declarative system configuration with reproducible builds
- **Cloudflare Tunnels**: Secure local development with HTTPS access
- **Multi-environment**: Supports both local development and production deployments

## Development Workflow

### Local Development

The development environment uses Cloudflare tunnels to expose local services at `https://dev-*` URLs:

- **WordPress**: https://dev-wp.radiopepper.website
- **AzuraCast**: https://dev-azura.radiopepper.website

**Key Development Features:**
- Services are accessible via HTTPS using Cloudflare tunnels
- Tunnel points to `http://localhost:443` where Caddy handles reverse proxying
- Zero public firewall exposure required
- Automatic SSL termination at Cloudflare edge

### Starting Development

**Important**: Development deployment should only be started using `deploy-vm`, not manually with `nix run .#dev-local`, because some secrets need to be populated.

1. **Deploy development VM**:
   ```bash
   deploy-vm
   ```

2. **Setup Cloudflare DNS routes** for development subdomains:
   ```bash
   cloudflared tunnel route dns $CF_TUNNEL dev-wp.radiopepper.website
   cloudflared tunnel route dns $CF_TUNNEL dev-azura.radiopepper.website
   ```
   **Note**: This requires cloudflared to be authenticated with Cloudflare. If you haven't authenticated, run `cloudflared tunnel login` first.

3. **Access services** via Cloudflare tunnel URLs:
   - WordPress: https://dev-wp.radiopepper.website
   - AzuraCast: https://dev-azura.radiopepper.website

### Alternative Access (Cloudflare Tunnels Not Available)

If Cloudflare tunnels are not possible, you can access services directly via localhost:8443, but this requires setup with `/etc/hosts` or other tools:

```bash
# Add to /etc/hosts
127.0.0.1 dev-wp.radiopepper.website
127.0.0.1 dev-azura.radiopepper.website
```

Then access:
- WordPress: http://dev-wp.radiopepper.website:8443
- AzuraCast: http://dev-azura.radiopepper.website:8443

## CLI Tools

The project includes several useful CLI tools available in `./scripts`:

### Deployment Scripts
- `deploy-vm`: Deploy to local development VM (recommended over manual nix run)
- `deploy-remote`: Deploy to remote production server

### Remote Deployment Setup

For remote deployment, first set up a Hetzner instance manually:

1. **Extract and add SSH key**:
   ```bash
   sops -d --extract '["id_ed25519_pub"]' ./secrets.enc.yaml > pub.key
   # Add this key to your Hetzner server
   ```

2. **Create Hetzner instance** (any OS is fine, NixOS will be deployed)

3. **Deploy to remote**:
   ```bash
   deploy-remote
   ```

   The script will connect and deploy using nixos-anywhere if successful.

### SSH Connections
- `ssh-local`: Connect to local development SSH on port 2222
- `ssh-remote`: Connect to remote production server via Hetzner

**Usage Example**:
```bash
# Access development shell with all tools
nix develop

# Connect to development VM
ssh-local

# Connect to production server
ssh-remote
```

## Architecture

### Production Deployment
- **Host**: Hetzner VPS
- **Domain**: radiopepper.website
- **Services**: WordPress, AzuraCast
- **Networking**: Cloudflare DNS + tunnel for public access
- **State Management**: Uses impermanence - ALL state is wiped on reboot except what's declared to persist

### Development Environment
- **Local**: MicroVM running NixOS
- **Networking**: Cloudflare tunnel pointing to localhost:443
- **Reverse Proxy**: Caddy handles HTTP to HTTPS conversion locally
- **State Management**: Development VM is ephemeral by design

## Configuration

### Environment Variables
Key configuration is stored in `env.json`:
- `DOMAIN`: Main domain (radiopepper.website)
- `VIRT_USER`: SSH user for virtual machines
- `DEV_SSH_PORT`: Local SSH port (2222)
- `HETZNER_SERVER_NAME`: Production server name
- `CF_TUNNEL`: Cloudflare tunnel ID

### State Persistence
- **Impermanence**: Used in production to ensure only declared directories persist across reboots
- **Secrets**: Encrypted secrets managed with SOPS
- **Persistent Storage**: Database data, container volumes, and user data are preserved; temporary files and caches are wiped

### Secrets
- Encrypted secrets managed with SOPS
- Database passwords, API tokens, and SSH keys stored securely

## Services

### WordPress
- **Container**: WordPress with MariaDB database
- **Features**: Full CMS with media management
- **Network**: Internal + public networks
- **Storage**: Persistent volume for uploads

### AzuraCast
- **Container**: Latest AzuraCast image
- **Features**: Radio broadcasting, DJ management, streaming
- **Ports**: 8000-8050 for streams, 2022 for SFTP
- **Storage**: Separate volumes for stations, backups, uploads

## Getting Started

### Prerequisites

1. **Install Nix and direnv**:
   - **Nix**: Follow the official installation guide
     - [Nix Installation](https://nixos.org/download.html)
   - **direnv**: Install via your system package manager or Nix
     ```bash
     nix profile install nixpkgs#direnv
     ```
   - **Setup direnv**:
     ```bash
     echo "eval "$(direnv hook bash)"" >> ~/.bashrc
     source ~/.bashrc
     ```

2. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd radio-pepper
   ```

3. **Setup SOPS (Secrets Management)**:
   **Option A: Get your key added by admin**
   - Contact the admin to have your GPG key added to the project's `.sops.yaml`

   **Option B: Start from scratch**
   ```bash
   # Generate a new GPG key
   gpg --full-generate-key
   # Add your key to .sops.yaml
   ```

   Verify your setup:
   ```bash
   sops --decrypt secrets.enc.yaml | head -n 5
   ```

### Configuration

1. **Environment Configuration**:
   - Review and update `env.json` with your specific domain and server details
   - This file contains non-sensitive configuration like domain names and server identifiers

2. **Secrets Overview**:
   `secrets.enc.yaml` contains the following sensitive data (encrypted):
   - Database passwords for WordPress and AzuraCast
   - SSH private key for accessing virtual machines
   - Cloudflare tunnel credentials
   - Hetzner API token for server management
   - WordPress and MariaDB root passwords

   **Note**: Never commit secrets or share them publicly.

### Deployment

1. **Start Development Environment**:
   ```bash
   deploy-vm
   ```
   This will:
   - Create and configure the development MicroVM
   - Deploy all services (WordPress, AzuraCast)
   - Set up networking and tunnels

2. **Setup Cloudflare DNS Routes** (after deployment completes):
   ```bash
   cloudflared tunnel route dns $CF_TUNNEL dev-wp.radiopepper.website
   cloudflared tunnel route dns $CF_TUNNEL dev-azura.radiopepper.website
   ```

3. **Access Services**:
   - WordPress: https://dev-wp.radiopepper.website
   - AzuraCast: https://dev-azura.radiopepper.website

### Development Shell

For access to development tools and utilities:
```bash
nix develop
```

This provides:
- Container management tools
- SSH clients
- Cloudflare utilities
- Code quality tools (pre-commit, etc.)

## Maintenance

### Backups
- Restic integration planned for automated backups
- AzuraCast includes built-in backup functionality

### Updates
- NixOS declarative updates via `nix flake update`
- Container updates managed through NixOS rebuilds

## Development Notes

- **Subdomain Prefix**: Development subdomains use "dev-" prefix (e.g., dev-wp.radiopepper.website)
- **Impermanence**: Critical for production - ensures only declared state persists, automatic cleanup of temporary files
- **Container Management**: Uses `quadlet-nix` for Podman containers
- **Local Development**: MicroVM for efficient testing
- **Code Quality**: Pre-commit hooks enforced

## License

This project is part of Radio Pepper - an internet radio station initiative.
