# Module evaluation & VM check — verifies homepage-dashboard module evaluates and runs correctly
{
  name = "homepage-dashboard-module";
  nodes.machine =
    { lib, ... }:
    {
      imports = [
        ../../80-lib/81-helpers/mkServiceContract.nix
        ../../20-services/26-monitoring/homepage-dashboard.nix
      ];

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

        nfp.services.caddy = {
          enable = true;
          host = "luffy";
          bind = "127.0.0.1";
          port = 2019;
          tailnetName = "caddy";
          tls = "headscale";
          healthcheck = {
            enable = true;
            path = "/config/";
            expectedStatus = [ 200 ];
          };
          homepage = {
            enable = true;
            category = "zoro";
            title = "Caddy";
            subtitle = "Santoryu Navigation Routes";
            icon = "caddy";
          };
        };

        layers.layer-10.system.config.impermanence.enable = false;
        networking.hostName = "luffy";
        system.stateVersion = "25.05";
      };
    };

  testScript = ''
    machine.wait_for_unit("homepage-dashboard.service")
    machine.wait_for_open_port(3007)

    # 1. Dashboard HTML serves NIX FLAKE PIRATES brand title (no GRANDLIX) and local theme assets
    html = machine.succeed("curl -s http://localhost:3007")
    assert "NIX FLAKE PIRATES" in html, "HTML missing NIX FLAKE PIRATES brand title"
    assert "GRANDLIX" not in html, "HTML still contains obsolete GRANDLIX brand title"
    assert "/assets/css/theme.css" in html, "HTML missing theme CSS link"
    assert "/assets/js/app.js" in html, "HTML missing app JS link"
    assert "http://" not in html and "https://" not in html, "HTML contains external URL references"

    # 2. /api/config lists contract-driven categories, bookmarks, and widget_map
    config_json = machine.succeed("curl -s http://localhost:3007/api/config")
    assert "categories" in config_json, "/api/config missing categories"
    assert "bookmarks" in config_json, "/api/config missing bookmarks"
    assert "widget_map" in config_json, "/api/config missing widget_map"
    assert "caddy" in config_json, "/api/config missing enabled caddy contract"

    # 3. Stubbed /api/widget/ returns clean status JSON without raw exception dumps
    widget_json = machine.succeed("curl -s http://localhost:3007/api/widget/caddy")
    assert "status" in widget_json or "bountyStat" in widget_json, "/api/widget/ response invalid"
  '';
}
