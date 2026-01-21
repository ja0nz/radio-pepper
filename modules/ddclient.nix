{ pkgs, config, ... }:

{
  sops.secrets."dyndns_namecheap_token" = { };

  # https://search.nixos.org/options?query=ddclient
  # https://github.com/ddclient/ddclient/blob/main/ddclient.conf.in
  services.ddclient = {
    enable = true;
    usev4 = "webv4, webv4=api.ipify.org, webv4=ipv4.icanhazip.com";
    usev6 = "webv6, webv6=api6.ipify.org, webv6=icanhazip.com";
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
