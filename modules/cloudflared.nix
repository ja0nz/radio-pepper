/**
  NixOS Module: Cloudflare Tunnel & Caddy Local Gateway
  * Purpose:
  This module configures a Cloudflare Tunnel (cloudflared) to expose local services
  to the internet without opening firewall ports. Caddy is used as the local
  reverse proxy.

  Why 'auto_https off' and 'http_port 443'? (Testing/Architecture):
  1. SSL Termination: In this setup, Cloudflare handles the public SSL/TLS
  certificates at the edge.
  2. Protocol Optimization: By disabling Caddy's 'auto_https', we prevent Caddy
  from attempting to fetch Let's Encrypt certificates locally, which would
  fail since the server is not directly reachable via port 80/443.
  3. Local Port Mapping: Caddy is configured to listen for plain HTTP traffic
  on port 443. The Cloudflare Tunnel is then pointed to 'http://localhost:443'.
  This allows the internal traffic to remain unencrypted (saving CPU/overhead
  during testing) while the external connection to the user remains secure.

  Services:
  - cloudflared: Connects the local machine to the Cloudflare edge using a specific
  tunnel token.
  - caddy: Acts as the entry point for traffic coming out of the tunnel.
*/
{ pkgs, ... }:

{
  services.caddy.globalConfig = ''
    auto_https off
    http_port 443
  '';

  environment.systemPackages = [ pkgs.cloudflared ];

  # After loggin in you could run
  # cloudflared tunnel --no-autoupdate run --token XXX

}
