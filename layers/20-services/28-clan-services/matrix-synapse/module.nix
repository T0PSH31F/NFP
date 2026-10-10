{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
in
{
  _class = "clan.service";
  manifest.name = "clan-core/matrix-synapse";
  manifest.description = "Official Matrix Synapse homeserver for secure communication";
  manifest.readme = builtins.readFile ./README.md;
  manifest.categories = [ "Communication" ];

  roles.default = {
    description = "The default role provides both the synapse homeserver and element web client";
    interface.options = {
      server_tld = mkOption {
        type = types.str;
        default = "matrix.local";
        description = "The domain name of the Matrix homeserver";
      };

      app_domain = mkOption {
        type = types.str;
        default = "element.local";
        description = "The domain name of the Element web client";
      };

      acmeEmail = mkOption {
        type = types.str;
        description = "Email address for ACME registration";
      };

      users = mkOption {
        type = types.attrsOf (
          types.submodule {
            options.admin = mkOption {
              type = types.bool;
              default = false;
            };
          }
        );
        default = { };
        description = "Users to create";
      };

      # Following the pattern from clan docs for official services
      enable = mkEnableOption "Matrix Synapse homeserver";
    };

    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            nfp.services.matrix-synapse = {
              enable = true;
              host = config.networking.hostName;
              bind = "127.0.0.1";
              port = 8008;
              tailnetName = "matrix";
              tls = "headscale";
              healthcheck = {
                enable = true;
                path = "/_matrix/client/versions";
                expectedStatus = [ 200 ];
              };
              homepage = {
                enable = true;
                category = "chopper";
                order = 25;
                title = "Matrix Synapse";
                subtitle = "Transponder Snail Comms";
                icon = "matrix";
                dashboardUrl = "https://${settings.app_domain}";
                metric = {
                  mode = "health-only";
                };
              };
            };

            services.matrix-synapse = {
              enable = true;
              settings = {
                server_name = settings.server_tld;
                database = {
                  name = "psycopg2";
                  allow_unsafe_locale = true; # Critical for existing database compatibility
                  args = {
                    user = "matrix-synapse";
                    database = "matrix-synapse";
                  };
                };
              };
            };

            # Matrix Synapse homeserver reverse proxy — matrix.lovelain.duckdns.org
            services.nginx.virtualHosts.${settings.server_tld} = {
              enableACME = true;
              forceSSL = true;
              locations."/" = {
                proxyPass = "http://127.0.0.1:8008";
                proxyWebsockets = true;
                extraConfig = ''
                  client_max_body_size 100M;
                '';
              };
            };

            # Element Web client — with custom config that doesn't rely on vector.im
            services.nginx.virtualHosts.${settings.app_domain} = {
              enableACME = true;
              forceSSL = true;
              root = lib.mkDefault (
                pkgs.runCommand "element-web-custom" { } ''
                  cp -a ${pkgs.element-web} $out
                  chmod +w $out/config.json
                  cp ${
                    builtins.toFile "config.json" (
                      builtins.toJSON {
                        default_server_config = {
                          "${"m.homeserver"}" = {
                            base_url = "https://${settings.app_domain}:443";
                            server_name = settings.server_tld;
                          };
                        };
                        disable_custom_urls = false;
                        disable_guests = true;
                        disable_login_language_selector = false;
                        disable_3pid_login = false;
                        force_verification = false;
                        brand = "Element";
                        integrations_ui_url = "";
                        integrations_rest_url = "";
                        integrations_widgets_urls = [ ];
                        default_widget_container_height = 280;
                        default_country_code = "US";
                        show_labs_settings = false;
                        features = { };
                        default_federate = true;
                        default_theme = "dark";
                        setting_defaults.breadcrumbs = true;
                        jitsi.preferred_domain = "meet.element.io";
                        element_call = {
                          url = "https://call.element.io";
                          brand = "Element Call";
                        };
                      }
                    )
                  } $out/config.json
                ''
              );
            };

            # Infrastructure requirements
            services.postgresql = {
              enable = true;
              ensureDatabases = [ "matrix-synapse" ];
              ensureUsers = [
                {
                  name = "matrix-synapse";
                  ensureDBOwnership = true;
                }
              ];
            };

            # Persistence integration
            environment.persistence."/persist" = mkIf config.layers.layer-10.system.config.impermanence.enable {
              directories = [
                "/var/lib/matrix-synapse"
              ];
            };
          };
      };
  };
}
