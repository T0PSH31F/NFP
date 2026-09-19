{ mkDendriticModule, ... }:
{
  imports = [
    (mkDendriticModule "alertmanager-ntfy" ./alertmanager-ntfy.nix)
    (mkDendriticModule "fleet-healthcheck" ./fleet-healthcheck.nix)
    (mkDendriticModule "glances" ./glances.nix)
    (mkDendriticModule "homepage-dashboard" ./homepage-dashboard.nix)
    (mkDendriticModule "monitoring" ./monitoring.nix)
    (mkDendriticModule "netdata" ./netdata.nix)
    (mkDendriticModule "ntfy-sh" ./ntfy-sh.nix)
  ];
}
