# layers/20-services/21-networking/nfp-services.nix
# Consumer engine binding nfp.services contracts to Caddy, Prometheus, Restic, and Firewall.
{ config, lib, ... }:
with lib;
let
  enabledServices = filterAttrs (_name: svc: svc.enable) (config.nfp.services or { });

  # Caddy reverse-proxy virtual hosts — tailnet contracts use tailnetDomain, never generic domain.
  # Public WAN routes remain on publicDomain via explicit Caddy virtualHosts in machine configs.
  contractVirtualHosts = mapAttrs' (
    _name: svc:
    let
      hostDomain = "${svc.tailnetName}.${config.layers.meta.tailnetDomain}";
    in
    nameValuePair "${hostDomain}" {
      extraConfig = ''
        reverse_proxy ${svc.bind}:${toString svc.port}
      '';
    }
  ) (filterAttrs (_: s: s.tls != "none") enabledServices);

  # Prometheus scrape configs
  metricsServices = filterAttrs (_: s: s.metrics.enable && s.metrics.port > 0) enabledServices;
  contractScrapeConfigs = mapAttrsToList (name: svc: {
    job_name = "contract-${name}";
    static_configs = [
      {
        targets = [ "${svc.bind}:${toString svc.metrics.port}" ];
        labels = {
          service = name;
          machine = svc.host;
        };
      }
    ];
  }) metricsServices;

  # Aggregated backup paths
  contractBackupPaths = concatLists (mapAttrsToList (_: s: s.backup.paths) enabledServices);
in
{
  imports = [
    ../../80-lib/81-helpers/mkServiceContract.nix
  ];

  config = mkMerge [
    (mkIf ((config.services.caddy.enable or false) && contractVirtualHosts != { }) {
      services.caddy.virtualHosts = contractVirtualHosts;
    })

    (mkIf ((config.services.prometheus.enable or false) && contractScrapeConfigs != [ ]) {
      services.prometheus.scrapeConfigs = contractScrapeConfigs;
    })

    (mkIf
      ((config.layers.layer-20.services.backups.restic.enable or false) && contractBackupPaths != [ ])
      {
        layers.layer-20.services.backups.restic.paths = contractBackupPaths;
      }
    )
  ];
}
