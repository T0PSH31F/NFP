# layers/20-services/23-media/nixarr.nix
# Declarative nixarr media server stack module for NFP.

{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.nixarr-stack;
in
{
  options.layers.layer-20.services.config.nixarr-stack = {
    enable = mkEnableOption "nixarr unified media server stack";

    mediaDir = mkOption {
      type = types.str;
      default = "/data/media";
      description = "Root media library directory owned by root.";
    };

    stateDir = mkOption {
      type = types.str;
      default = "/data/.state/nixarr";
      description = "State directory for nixarr service persistence.";
    };

    mediaUsers = mkOption {
      type = types.listOf types.str;
      default = [ "t0psh31f" ];
      description = "Human user accounts granted access to media directories.";
    };
  };

  config = mkIf cfg.enable {
    # NixOS Nixarr module options
    nixarr = {
      enable = true;
      inherit (cfg) mediaDir stateDir mediaUsers;

      jellyfin.enable = true;
      komga.enable = true;
      audiobookshelf.enable = true;
      seerr.enable = true;
      lidarr.enable = true;
      bazarr.enable = true;
      recyclarr = {
        enable = true;
        configuration = {
          sonarr.web-1080p = {
            base_url = "http://localhost:8989";
            api_key = "!env_var SONARR_API_KEY";
            quality_definition.type = "series";
            quality_profiles = [
              {
                trash_id = "72dae194fc92bf828f32cde7744e51a1"; # WEB-1080p
                reset_unmatched_scores.enabled = true;
              }
            ];
            custom_format_groups.add = [
              { trash_id = "158188097a58d7687dee647e04af0da3"; } # Golden Rule HD
              { trash_id = "85fae4a2294965b75710ef2989c850eb"; } # Streaming Services HD/UHD boost
              { trash_id = "59c3af66780d08332fdc64e68297098f"; } # Unwanted Formats
            ];
          };
          radarr.hd-bluray-web = {
            base_url = "http://localhost:7878";
            api_key = "!env_var RADARR_API_KEY";
            quality_definition.type = "movie";
            quality_profiles = [
              {
                trash_id = "d1d67249d3890e49bc12e275d989a7e9"; # HD Bluray + WEB
                reset_unmatched_scores.enabled = true;
              }
            ];
            custom_format_groups.add = [
              { trash_id = "f8bf8eab4617f12dfdbd16303d8da245"; } # Golden Rule HD
              { trash_id = "a3ac6af01d78e4f21fcb75f601ac96df"; } # Unwanted Formats
            ];
          };
        };
      };
      qbittorrent.enable = true;
      sabnzbd.enable = true;
      autobrr.enable = true;
      anchorr.enable = true;
      shelfmark.enable = true;
      sonarr.enable = true;
      radarr.enable = true;
      prowlarr.enable = true;

      plex.enable = false; # Explicitly disabled (conflicts with Jellyfin)
    };

    # Override upstream nixarr setting deprecated services.sabnzbd.configFile
    services.sabnzbd.configFile = mkForce null;

    # Komga native Authentik OIDC integration
    services.komga.settings = mkIf (config.layers.layer-20.services.auth.authentik.enable or false) (
      let
        authDomain = config.layers.layer-20.services.auth.authentik.domain;
      in
      {
        komga.oauth2-account-creation = true;
        komga.oidc-email-verification = false;
        spring.security.oauth2.client = {
          registration.authentik = {
            client-id = "komga";
            client-name = "LoveLain SSO";
            scope = [
              "openid"
              "profile"
              "email"
            ];
            authorization-grant-type = "authorization_code";
            redirect-uri = "{baseUrl}/login/oauth2/code/{registrationId}";
          };
          provider.authentik = {
            issuer-uri = "https://${authDomain}/application/o/komga/";
            user-name-attribute = "preferred_username";
          };
        };
      }
    );

    systemd.services.komga-oidc-env =
      mkIf (config.layers.layer-20.services.auth.authentik.enable or false)
        {
          description = "Provision Komga OIDC client secret from Authentik runtime env";
          wantedBy = [ "multi-user.target" ];
          before = [ "komga.service" ];
          after = [ "postgresql-authentik-setup.service" ];
          requires = [ "postgresql-authentik-setup.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            install -d -m 0750 /var/lib/komga
            if [ -r /var/lib/authentik/runtime.env ]; then
              . /var/lib/authentik/runtime.env
              if [ -n "''${OIDC_KOMGA_SECRET:-}" ]; then
                umask 077
                printf 'SPRING_SECURITY_OAUTH2_CLIENT_REGISTRATION_AUTHENTIK_CLIENT_SECRET=%s\n' "$OIDC_KOMGA_SECRET" > /var/lib/komga/oidc.env.tmp
                chown komga:media /var/lib/komga/oidc.env.tmp
                chmod 0600 /var/lib/komga/oidc.env.tmp
                mv /var/lib/komga/oidc.env.tmp /var/lib/komga/oidc.env
              fi
            fi
          '';
        };

    systemd.services.komga = mkIf (config.layers.layer-20.services.auth.authentik.enable or false) {
      after = [ "komga-oidc-env.service" ];
      requires = [ "komga-oidc-env.service" ];
      serviceConfig.EnvironmentFile = [ "/var/lib/komga/oidc.env" ];
    };

    systemd.services.jellyfin-sso-config =
      mkIf (config.layers.layer-20.services.auth.authentik.enable or false)
        (
          let
            authDomain = config.layers.layer-20.services.auth.authentik.domain;
          in
          {
            description = "Sync Jellyfin SSO-Auth OIDC client secret from Authentik runtime env";
            wantedBy = [ "multi-user.target" ];
            before = [ "jellyfin.service" ];
            after = [ "postgresql-authentik-setup.service" ];
            requires = [ "postgresql-authentik-setup.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              CFG_DIR="${cfg.stateDir}/jellyfin/data/plugins/configurations"
              CFG_FILE="$CFG_DIR/SSO-Auth.xml"
              if [ -r /var/lib/authentik/runtime.env ]; then
                . /var/lib/authentik/runtime.env
                if [ -n "''${OIDC_JELLYFIN_SECRET:-}" ]; then
                  install -d -m 0750 -o jellyfin -g media "$CFG_DIR"
                  umask 077
                  cat > "$CFG_FILE.tmp" <<EOF
              <?xml version="1.0" encoding="utf-8"?>
              <PluginConfiguration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
                <SamlConfigs />
                <OidConfigs>
                  <item>
                    <key>
                      <string>authentik</string>
                    </key>
                    <value>
                      <PluginConfiguration>
                        <OidEndpoint>https://${authDomain}/application/o/jellyfin/</OidEndpoint>
                        <OidClientId>jellyfin</OidClientId>
                        <OidSecret>$OIDC_JELLYFIN_SECRET</OidSecret>
                        <Enabled>true</Enabled>
                        <EnableAuthorization>true</EnableAuthorization>
                        <EnableAllFolders>true</EnableAllFolders>
                        <EnabledFolders />
                        <AdminRoles>
                          <string>NFP Admins</string>
                        </AdminRoles>
                        <Roles>
                          <string>NFP Admins</string>
                          <string>Family</string>
                          <string>Friends</string>
                        </Roles>
                        <EnableFolderRoles>false</EnableFolderRoles>
                        <EnableLiveTvRoles>false</EnableLiveTvRoles>
                        <EnableLiveTv>false</EnableLiveTv>
                        <EnableLiveTvManagement>false</EnableLiveTvManagement>
                        <FolderRoleMappings />
                        <RoleClaim>groups</RoleClaim>
                        <OidScopes>
                          <string>profile</string>
                          <string>email</string>
                        </OidScopes>
                        <SchemeOverride>https</SchemeOverride>
                        <PortOverride xsi:nil="true" />
                        <NewPath>true</NewPath>
                        <CanonicalLinks />
                        <DefaultUsernameClaim>preferred_username</DefaultUsernameClaim>
                        <DisableHttps>false</DisableHttps>
                        <DisablePushedAuthorization>false</DisablePushedAuthorization>
                        <DoNotValidateEndpoints>false</DoNotValidateEndpoints>
                        <DoNotValidateIssuerName>false</DoNotValidateIssuerName>
                        <DoNotLoadProfile>false</DoNotLoadProfile>
                      </PluginConfiguration>
                    </value>
                  </item>
                </OidConfigs>
              </PluginConfiguration>
              EOF
                  chown jellyfin:media "$CFG_FILE.tmp"
                  chmod 0600 "$CFG_FILE.tmp"
                  mv "$CFG_FILE.tmp" "$CFG_FILE"
                fi
              fi
            '';
          }
        );

    systemd.services.jellyfin = mkIf (config.layers.layer-20.services.auth.authentik.enable or false) {
      after = [ "jellyfin-sso-config.service" ];
      requires = [ "jellyfin-sso-config.service" ];
    };

    services.audiobookshelf = {
      host = lib.mkForce "0.0.0.0";
      openFirewall = true;
    };

    services.readarr = {
      enable = true;
      dataDir = "${cfg.stateDir}/readarr";
      openFirewall = false;
    };

    # Declarative nfp.services contracts for nixarr media services
    nfp.services = {
      jellyfin = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 8096;
        tailnetName = "jellyfin";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/jellyfin" ];
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            302
          ];
        };
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 10;
          title = "Jellyfin";
          subtitle = "Stella — Genius Center";
          icon = "jellyfin";
          satellite = "stella";
          metric = {
            mode = "native-api";
            adapter = "jellyfin";
            fields = [
              "activeStreams"
              "movies"
              "series"
              "musicAlbums"
            ];
          };
        };
      };

      komga = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 25600;
        tailnetName = "komga";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/komga" ];
        homepage = {
          enable = true;
          category = "robin";
          order = 10;
          title = "Komga";
          subtitle = "Manga Scrolls Archive";
          icon = "komga";
          metric = {
            mode = "native-api";
            adapter = "komga";
            fields = [
              "books"
              "series"
            ];
          };
        };
      };

      audiobookshelf = {
        enable = true;
        host = config.networking.hostName;
        bind = "0.0.0.0";
        port = 9292;
        tailnetName = "audiobookshelf";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/audiobookshelf" ];
        homepage = {
          enable = true;
          category = "robin";
          order = 20;
          title = "Audiobookshelf";
          subtitle = "Ancient Audio Archives";
          icon = "audiobookshelf";
          metric = {
            mode = "native-api";
            adapter = "audiobookshelf";
            fields = [
              "items"
              "authors"
            ];
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            302
          ];
        };
      };

      sonarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 8989;
        tailnetName = "sonarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/sonarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 20;
          title = "Sonarr";
          subtitle = "Shaka — Good";
          icon = "sonarr";
          satellite = "shaka";
          metric = {
            mode = "native-api";
            adapter = "sonarr";
            fields = [
              "series"
              "episodes"
            ];
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            401
          ];
        };
      };

      radarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 7878;
        tailnetName = "radarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/radarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 30;
          title = "Radarr";
          subtitle = "Lilith — Evil";
          icon = "radarr";
          satellite = "lilith";
          metric = {
            mode = "native-api";
            adapter = "radarr";
            fields = [ "movies" ];
          };
        };
      };

      prowlarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 9696;
        tailnetName = "prowlarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/prowlarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 40;
          title = "Prowlarr";
          subtitle = "Edison — Thinking";
          icon = "prowlarr";
          satellite = "edison";
          metric = {
            mode = "native-api";
            adapter = "prowlarr";
            fields = [ "indexers" ];
          };
        };
      };

      seerr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 5055;
        tailnetName = "seerr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/seerr" ];
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            307
          ];
        };
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 50;
          title = "Overseerr";
          subtitle = "York — Greed";
          icon = "overseerr";
          satellite = "york";
          metric = {
            mode = "native-api";
            adapter = "seerr";
            fields = [ "requests" ];
          };
        };
      };

      qbittorrent = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 8085;
        tailnetName = "qbittorrent";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/qbittorrent" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 60;
          title = "qBittorrent";
          subtitle = "Torrent Seedbox";
          icon = "qbittorrent";
          satellite = null;
          metric = {
            mode = "native-api";
            adapter = "qbittorrent";
            fields = [
              "torrentCount"
              "dlSpeed"
              "ulSpeed"
            ];
          };
        };
      };

      lidarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 8686;
        tailnetName = "lidarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/lidarr" ];
        homepage = {
          enable = true;
          category = "brook";
          order = 35;
          title = "Lidarr";
          subtitle = "Soul King Discography 💀🎵";
          icon = "lidarr";
          satellite = null;
          metric = {
            mode = "native-api";
            adapter = "lidarr";
            fields = [
              "artists"
              "albums"
            ];
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            401
          ];
        };
      };

      bazarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 6767;
        tailnetName = "bazarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/bazarr" ];
        homepage = {
          enable = true;
          category = "vegapunk";
          order = 45;
          title = "Bazarr";
          subtitle = "Pythagoras — Wisdom";
          icon = "bazarr";
          satellite = "pythagoras";
          metric = {
            mode = "native-api";
            adapter = "bazarr";
            fields = [
              "subtitles"
            ];
          };
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            401
          ];
        };
      };

      readarr = {
        enable = true;
        host = config.networking.hostName;
        bind = "127.0.0.1";
        port = 8787;
        tailnetName = "readarr";
        tls = "headscale";
        backup.paths = [ "${cfg.stateDir}/readarr" ];
        homepage = {
          enable = true;
          category = "robin";
          order = 25;
          title = "Readarr";
          subtitle = "Poneglyph Book Finder";
          icon = "readarr";
          satellite = null;
        };
        healthcheck = {
          enable = true;
          path = "/";
          expectedStatus = [
            200
            401
          ];
        };
      };
    };

    # Impermanence state persistence for nixarr state directory
    environment.persistence."/persist" =
      mkIf (config.layers.layer-10.system.config.impermanence.enable or false)
        {
          directories = [
            cfg.stateDir
          ];
        };
  };
}
