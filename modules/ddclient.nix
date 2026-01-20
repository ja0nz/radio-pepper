{ pkgs, config, ... }:

{
  sops.secrets."dyndns_namecheap_token" = { };

  # https://search.nixos.org/options?query=ddclient
  services.ddclient = {
    enable = true;
    ssl = true;
    usev4 = "webv4, webv4=api.ipify.org, webv4=ipv4.icanhazip.com";
    protocol = "namecheap";
    server = "dynamicdns.park-your-domain.com";
    username = "radiopepper.website";
    passwordFile = config.sops.secrets."dyndns_namecheap_token".path;
    domains = [
      "@"
      "*"
    ];
  };
}
