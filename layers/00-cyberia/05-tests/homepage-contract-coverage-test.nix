{
  pkgs,
  lib,
  nixosConfigurations,
}:
let
  luffyConfig = nixosConfigurations.luffy.config or { };
  namiConfig = nixosConfigurations.nami.config or { };
  z0r0Config = nixosConfigurations.z0r0.config or { };

  # All fleet nfp.services (union across hosts)
  luffyContracts = luffyConfig.nfp.services or { };
  namiContracts = namiConfig.nfp.services or { };
  z0r0Contracts = z0r0Config.nfp.services or { };

  # Services with homepage.enable = true

  # Icon file existence check (at eval time we just verify the name is non-empty)
  hasIcon = svc: (svc.homepage.icon or "") != "";

  # Intentional omissions (backend-only services that don't need cards)
  intentionalOmissions = {
    netdata = "Backend telemetry agent — visible through Grafana dashboards";
    ollama = "Backend LLM runtime — accessed through Open WebUI or oterm";
  };

  # User-facing services that MUST have homepage contracts when enabled
  # Each entry: { name, host, enablePath description }
  requiredServices = [
    # Networking
    {
      name = "caddy";
      host = "luffy";
    }
    {
      name = "adguard";
      host = "luffy";
    }
    {
      name = "headscale";
      host = "luffy";
    }
    # Media
    {
      name = "jellyfin";
      host = "luffy";
    }
    {
      name = "komga";
      host = "luffy";
    }
    {
      name = "audiobookshelf";
      host = "luffy";
    }
    {
      name = "sonarr";
      host = "luffy";
    }
    {
      name = "radarr";
      host = "luffy";
    }
    {
      name = "prowlarr";
      host = "luffy";
    }
    {
      name = "seerr";
      host = "luffy";
    }
    {
      name = "qbittorrent";
      host = "luffy";
    }
    {
      name = "calibre-web";
      host = "luffy";
    }
    {
      name = "romm";
      host = "luffy";
    }
    {
      name = "jackett";
      host = "luffy";
    }
    {
      name = "feishin";
      host = "luffy";
    }
    # Communication
    {
      name = "your-spotify";
      host = "luffy";
    }
    # Data
    {
      name = "syncthing";
      host = "luffy";
    }
    # Monitoring
    {
      name = "ntfy";
      host = "luffy";
    }
    {
      name = "prometheus";
      host = "luffy";
    }
    {
      name = "grafana";
      host = "luffy";
    }
    # Search
    {
      name = "searxng";
      host = "luffy";
    }
    # Agents (nami-hosted)
    {
      name = "polyfloor";
      host = "nami";
    }
    {
      name = "omniroute";
      host = "nami";
    }
    {
      name = "kong-gateway";
      host = "nami";
    }
    {
      name = "open-webui";
      host = "nami";
    }
    {
      name = "sillytavern";
      host = "nami";
    }
    {
      name = "freellmapi";
      host = "nami";
    }
    {
      name = "freellmpool";
      host = "nami";
    }
    # Agents (z0r0-hosted)
    {
      name = "extreme-router";
      host = "z0r0";
    }
  ];

  # Get the right config for a host
  configForHost =
    host:
    if host == "luffy" then
      luffyContracts
    else if host == "nami" then
      namiContracts
    else if host == "z0r0" then
      z0r0Contracts
    else
      { };

  testCoverageScript = lib.concatMapStringsSep "\n" (
    svc:
    let
      contracts = configForHost svc.host;
      contract = contracts.${svc.name} or null;
      isOmitted = intentionalOmissions ? ${svc.name};
      isEnabled = contract != null && (contract.enable or false);
      hasHomepage = isEnabled && (contract.homepage.enable or false);
    in
    if isOmitted then
      "echo 'SKIP ${svc.name}: intentional omission (${intentionalOmissions.${svc.name}})'"
    else if !isEnabled then
      "echo 'SKIP ${svc.name}: service disabled on ${svc.host}'"
    else if hasHomepage then
      "echo 'PASS ${svc.name}: homepage.enable is true'"
    else
      "echo 'FAIL: ${svc.name} enabled on ${svc.host} but homepage.enable is false — add homepage contract metadata' && exit 1"
  ) requiredServices;

  testValidityScript = lib.concatMapStringsSep "\n" (
    svc:
    let
      contracts = configForHost svc.host;
      contract = contracts.${svc.name} or null;
      isEnabled = contract != null && (contract.enable or false);
      hasHomepage = isEnabled && (contract.homepage.enable or false);
    in
    lib.optionalString hasHomepage ''
      if [ "${if hasIcon contract then "1" else "0"}" != "1" ]; then
        echo "FAIL: ${svc.name} homepage.icon is empty"
        exit 1
      fi
      if [ -z "${contract.homepage.title or ""}" ]; then
        echo "FAIL: ${svc.name} homepage.title is empty"
        exit 1
      fi
      if [ "${if (contract.port or 0) > 0 then "1" else "0"}" != "1" ]; then
        echo "FAIL: ${svc.name} port is 0"
        exit 1
      fi
      echo "PASS ${svc.name}: homepage contract valid (icon=${contract.homepage.icon or "?"}, port=${toString (contract.port or 0)})"
    ''
  ) requiredServices;

in
pkgs.runCommand "homepage-contract-coverage-test" { } ''
  echo "Running homepage contract coverage tests..."
  ${testCoverageScript}
  echo "Running homepage contract validity tests..."
  ${testValidityScript}
  touch $out
''
