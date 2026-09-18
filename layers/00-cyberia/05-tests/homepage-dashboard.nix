# Module evaluation & VM check — verifies homepage-dashboard module evaluates and runs correctly
{
  name = "homepage-dashboard-module";
  nodes.machine =
    { lib, ... }:
    {
      imports = [ ../../20-services/26-monitoring/homepage-dashboard.nix ];

      options = {
        layers.layer-10.system.config.impermanence.enable = lib.mkEnableOption "impermanence";
        environment.persistence = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
        sops.templates = lib.mkOption {
          type = lib.types.attrs;
          default = { };
        };
      };

      config = {
        layers.layer-20.services.config.homepage-dashboard = {
          enable = true;
          port = 3007;
        };
        layers.layer-10.system.config.impermanence.enable = false;
        networking.hostName = "luffy";
        system.stateVersion = "25.05";
      };
    };

  testScript = ''
    machine.wait_for_unit("homepage-dashboard.service")
    machine.wait_for_open_port(3007)

    # 1. Dashboard HTML serves with theme assets and vendored fonts (no external URLs)
    html = machine.succeed("curl -s http://localhost:3007")
    assert "GRANDLIX" in html, "HTML missing brand title"
    assert "/assets/css/theme.css" in html, "HTML missing theme CSS link"
    assert "/assets/js/app.js" in html, "HTML missing app JS link"
    assert "http://" not in html and "https://" not in html, "HTML contains external URL references"

    # 2. /api/config lists categories, bookmarks, and widgets
    config_json = machine.succeed("curl -s http://localhost:3007/api/config")
    assert "categories" in config_json, "/api/config missing categories"
    assert "bookmarks" in config_json, "/api/config missing bookmarks"
    assert "widget_map" in config_json, "/api/config missing widget_map"

    # 3. Stubbed /api/widget/ returns JSON
    widget_json = machine.succeed("curl -s http://localhost:3007/api/widget/glances")
    assert "status" in widget_json or "error" in widget_json, "/api/widget/ response invalid"
  '';
}
