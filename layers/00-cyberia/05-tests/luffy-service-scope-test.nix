# Test: luffy service scope & netdata card default policy
{
  pkgs ? import <nixpkgs> { },
  lib ? pkgs.lib,
  nixosConfigurations ? { },
}:
let
  luffyConfig = nixosConfigurations.luffy.config or { };
  namiConfig = nixosConfigurations.nami.config or { };
  z0r0Config = nixosConfigurations.z0r0.config or { };
in
{
  name = "luffy-service-scope-test";

  testScope = ''
    # 1. Luffy must NOT run Ollama, Open WebUI, SillyTavern, or Kong Gateway
    assert "${
      toString (luffyConfig.services.ai-services.ollama.enable or false)
    }" == "false", "Luffy Ollama must be disabled"
    assert "${
      toString (luffyConfig.services.ai-services.open-webui.enable or false)
    }" == "false", "Luffy Open WebUI must be disabled"
    assert "${
      toString (luffyConfig.services.sillytavern-app.enable or false)
    }" == "false", "Luffy SillyTavern must be disabled"
    assert "${
      toString (luffyConfig.services.ai-services.kong-gateway.enable or false)
    }" == "false", "Luffy Kong Gateway must be disabled"

    # 2. Netdata enabled on all three nodes
    assert "${
      toString (luffyConfig.layers.layer-20.services.config.netdata.enable or false)
    }" == "true", "Luffy Netdata must be enabled"
    assert "${
      toString (namiConfig.layers.layer-20.services.config.netdata.enable or false)
    }" == "true", "Nami Netdata must be enabled"
    assert "${
      toString (z0r0Config.layers.layer-20.services.config.netdata.enable or false)
    }" == "true", "Z0r0 Netdata must be enabled"

    # 3. Netdata homepage card disabled by default
    assert "${
      toString (luffyConfig.nfp.services.netdata.homepage.enable or false)
    }" == "false", "Netdata homepage card must be false by default"

    # 4. Luffy requested media/indexer services retained
    assert "${
      toString (luffyConfig.services.searxng.enable or false)
    }" == "true", "Luffy SearXNG must be enabled"
    assert "${
      toString (luffyConfig.services.calibre-web-app.enable or false)
    }" == "true", "Luffy Calibre-Web must be enabled"
    assert "${
      toString (luffyConfig.layers.layer-20.services.config.nixarr-stack.enable or false)
    }" == "true", "Luffy Nixarr stack must be enabled"
    assert "${
      toString (luffyConfig.layers.layer-20.services.config.jackett.enable or false)
    }" == "true", "Luffy Jackett must be enabled"
  '';
}
