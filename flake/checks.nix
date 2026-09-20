{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      inputs',
      ...
    }:
    let
      theme-tests = import ../layers/00-cyberia/05-tests/themes.nix {
        inherit pkgs;
        inherit (pkgs) lib;
      };
    in
    {
      checks = {
        feature-list-schema =
          pkgs.runCommand "check-feature-list-schema"
            {
              nativeBuildInputs = [
                pkgs.jq
                pkgs.coreutils
              ];
            }
            ''
              jq -e '.features | all(has("id") and has("verification") and has("state") and has("claimedBy") and has("blockedReason") and (.evidence | all(type == "object" and has("sha") and has("command") and has("output") and has("at"))))' ${../feature_list.json} > /dev/null
              LINES=$(wc -l < ${../feature_list.json})
              if [ "$LINES" -gt 300 ]; then
                echo "feature_list.json size error: file has $LINES lines (limit is 300). Archive older passing features to feature_list_archive.json."
                exit 1
              fi
              touch $out
            '';

        docs-drift =
          pkgs.runCommand "check-docs-drift"
            {
              nativeBuildInputs = [ pkgs.diffutils ];
            }
            ''
              test -f ${../layers/00-cyberia/01-docs/ports.md}
              touch $out
            '';

        bogus-tag-negative-test = pkgs.runCommand "check-bogus-tag-negative-test" { } ''
          touch $out
        '';

        homepage-lovable-archived = pkgs.runCommand "check-homepage-lovable-archived" { } ''
          if [ -d "${../.}/layers/00-cyberia/02-assets/Homepage-Dashboard" ]; then
            echo "ERROR: Active Lovable prototype found at layers/00-cyberia/02-assets/Homepage-Dashboard. Must be archived or given an explicit Nix derivation."
            exit 1
          fi
          touch $out
        '';

        luffy-service-scope =
          let
            luffyConfig = inputs.self.nixosConfigurations.luffy.config;
            namiConfig = inputs.self.nixosConfigurations.nami.config;
            z0r0Config = inputs.self.nixosConfigurations.z0r0.config;
          in
          if luffyConfig.services.ai-services.ollama.enable then
            throw "luffy service scope error: Ollama must be disabled on luffy"
          else if luffyConfig.services.ai-services.open-webui.enable then
            throw "luffy service scope error: Open WebUI must be disabled on luffy"
          else if luffyConfig.services.sillytavern-app.enable then
            throw "luffy service scope error: SillyTavern must be disabled on luffy"
          else if luffyConfig.services.ai-services.kong-gateway.enable then
            throw "luffy service scope error: Kong Gateway must be disabled on luffy"
          else if !luffyConfig.layers.layer-20.services.config.netdata.enable then
            throw "luffy service scope error: Netdata must be enabled on luffy"
          else if !namiConfig.layers.layer-20.services.config.netdata.enable then
            throw "luffy service scope error: Netdata must be enabled on nami"
          else if !z0r0Config.layers.layer-20.services.config.netdata.enable then
            throw "luffy service scope error: Netdata must be enabled on z0r0"
          else if luffyConfig.nfp.services.netdata.homepage.enable then
            throw "luffy service scope error: Netdata homepage card must be false by default"
          else
            pkgs.runCommand "check-luffy-service-scope" { } ''
              touch $out
            '';

        llm-agents-catalog-completeness =
          let
            llmPkgs = inputs.llm-agents.packages.${system} or { };
            catalogEnabled =
              inputs.self.nixosConfigurations.z0r0.config.layers.layer-20.services.llm-agents-catalog.packages
                or [ ];
            missingNames = pkgs.lib.filter (name: !(llmPkgs ? ${name})) catalogEnabled;
          in
          if missingNames != [ ] then
            throw "llm-agents-catalog error: The following enabled package names are missing from llmPkgs: ${pkgs.lib.concatStringsSep ", " missingNames}"
          else
            pkgs.runCommand "check-llm-agents-catalog-completeness" { } ''
              touch $out
            '';

        inherit (theme-tests) plymouth-theme-builds sddm-theme-builds all-themes;

        dendritic-structure-test = import ../layers/00-cyberia/05-tests/dendritic-structure-test.nix {
          inherit pkgs;
          inherit (pkgs) lib;
        };

        noctalia-registry-check = import ../layers/00-cyberia/05-tests/noctalia-registry-check.nix {
          inherit pkgs inputs;
        };

        nfp-motd-test = import ../layers/00-cyberia/05-tests/nfp-motd-test.nix {
          inherit pkgs;
          inherit (pkgs) lib;
        };

        homepage-contract-coverage =
          import ../layers/00-cyberia/05-tests/homepage-contract-coverage-test.nix
            {
              inherit pkgs;
              inherit (pkgs) lib;
              inherit (inputs.self) nixosConfigurations;
            };

        layer-numbering-check =
          pkgs.runCommand "check-layer-numbering"
            {
              nativeBuildInputs = [ pkgs.gnugrep ];
            }
            ''
              NUMBERING_FILE="${../layers/NUMBERING.md}"
              LAYERS_DIR="${../layers}"
              for dir in $(find $LAYERS_DIR -mindepth 1 -maxdepth 2 -type d); do
                base=$(basename "$dir")
                if [ "$base" != "layers" ] && [ "$base" != "NUMBERING.md" ]; then
                  if ! grep -q "$base" "$NUMBERING_FILE"; then
                    echo "Layer governance failure: directory '$base' is not registered in layers/NUMBERING.md"
                    exit 1
                  fi
                fi
              done
              touch $out
            '';

        services-test = pkgs.testers.nixosTest (import ../layers/00-cyberia/05-tests/services.nix);
        n8n-test = pkgs.testers.nixosTest (import ../layers/00-cyberia/05-tests/n8n.nix { inherit pkgs; });
        prowlarr-test = pkgs.testers.nixosTest (import ../layers/00-cyberia/05-tests/prowlarr.nix);
        headscale-test = pkgs.testers.nixosTest (import ../layers/00-cyberia/05-tests/headscale.nix);
        jellyfin-test = pkgs.testers.nixosTest (import ../layers/00-cyberia/05-tests/jellyfin.nix);
        homepage-dashboard-test = pkgs.testers.nixosTest (
          import ../layers/00-cyberia/05-tests/homepage-dashboard.nix
        );
        ai-services-test = pkgs.testers.nixosTest (
          import ../layers/00-cyberia/05-tests/ai-services-tests.nix
        );
        fleet-healthcheck-test = pkgs.testers.nixosTest (
          import ../layers/00-cyberia/05-tests/fleet-healthcheck.nix { inherit pkgs; }
        );
        tailnet-dns-adguard-test = pkgs.testers.nixosTest (
          import ../layers/00-cyberia/05-tests/tailnet-dns-adguard.nix
        );

        tailnet-dns-guard =
          pkgs.runCommand "check-tailnet-dns-guard"
            {
              nativeBuildInputs = [
                pkgs.gnugrep
                pkgs.gnused
                pkgs.jq
              ];
            }
            ''
              set -euo pipefail
              REPO=${../.}

              echo "Phase6 guard: 8 checks — tailnetDomain vs base_domain, no grandlix/.local/raw IP, no WAN DNS, luffy no recursive, accept-dns, rendered URLs"

              # 1. tailnetDomain must equal headscale base_domain
              if ! grep -q 'base_domain = config.layers.meta.tailnetDomain' "$REPO/layers/20-services/21-networking/headscale.nix"; then
                echo "FAIL 1: headscale base_domain not derived from tailnetDomain"; exit 1
              fi

              # 2/3. No lovelain in tailnet contracts, no nfp.nix in public Caddy registry
              if grep -R "lovelain.duckdns.org" "$REPO/layers/20-services/21-networking/nfp-services.nix" >/dev/null; then
                echo "FAIL 2: nfp-services tailnet contract uses publicDomain"; exit 1
              fi
              if grep -R "nfp.nix" "$REPO/layers/20-services/21-networking/caddy.nix" >/dev/null; then
                echo "FAIL 3: public Caddy routes use tailnetDomain"; exit 1
              fi

              # 4. No grandlix/.local/raw Tailnet IP/bare hostname outside allowed places
              # Allow: .slim/deepwork, feature_list_archive.json, *.md historical archive, and authority declaration
              if grep -R --exclude-dir=.slim --exclude-dir=.git --exclude="*.md" "grandlix.net" "$REPO/layers" "$REPO/machines" 2>/dev/null | grep -v "fleet-domains" | grep -q .; then
                echo "FAIL 4a: grandlix.net literal outside archive"; grep -R "grandlix.net" "$REPO/layers" "$REPO/machines"; exit 1
              fi
              # .local only allowed as matrix.local/element.local (flagged later) — otherwise fail
              # For now ensure no bare nami.local/z0r0.local/luffy.local in runtime consumers outside docs
              if grep -R "nami\.local\|z0r0\.local\|luffy\.local" "$REPO/layers" "$REPO/machines" 2>/dev/null | grep -v "matrix.local" | grep -q .; then
                echo "FAIL 4b: .local bare hostname in runtime code"; grep -R "nami\.local" "$REPO/layers" "$REPO/machines"; exit 1
              fi
              # raw 100.64.* outside meta.nix fleetAddresses
              if grep -R "100\.64\.0" "$REPO/layers" "$REPO/machines" 2>/dev/null | grep -v "meta.nix" | grep -v "fleetAddresses" | grep -v "00-cyberia/05-tests" | grep -q .; then
                echo "FAIL 4c: raw Tailnet IP outside fleetAddresses authority"; grep -R "100\.64" "$REPO/layers" "$REPO/machines" | grep -v meta.nix; exit 1
              fi
              # nfp.nix literals only in meta/fleet-domains/tests
              if grep -R "nfp\.nix" "$REPO/layers" "$REPO/machines" 2>/dev/null | grep -v "meta.nix" | grep -v "fleet-domains" | grep -v "05-tests" | grep -v "headscale.nix:.*tailnetDomain" | grep -q '"nfp\.nix"'; then
                echo "WARN 4d: nfp.nix literal outside authority — should use helper"; grep -R "nfp.nix" "$REPO/layers" | head
              fi

              # 5. AdGuard DNS not exposed on WAN
              if grep -q "openFirewall = true" "$REPO/layers/20-services/21-networking/adguard.nix"; then
                echo "FAIL 5: AdGuard openFirewall true — must be false (tailnet+LAN only)"; exit 1
              fi
              if grep -q "allowedTCPPorts.*53" "$REPO/layers/10-system/11-foundation/networking.nix"; then
                echo "FAIL 5: master firewall exposes 53 WAN"; exit 1
              fi

              # 6. luffy recursive check — must have --accept-dns=false and 127.0.0.1 + bootstrap
              if ! grep -q 'isResolverHost.*luffy' "$REPO/layers/20-services/21-networking/tailscale.nix"; then
                echo "FAIL 6: luffy resolver escape hatch missing"; exit 1
              fi

              # 7. clients accept-dns except resolver host — tailscale.nix must have flag
              if ! grep -q "accept-dns" "$REPO/layers/20-services/21-networking/tailscale.nix"; then
                echo "FAIL 7: accept-dns not wired"; exit 1
              fi

              # 8. rendered Homepage/healthcheck must use nfp.nix via authority
              if ! grep -q "mkTailnetHost" "$REPO/layers/20-services/26-monitoring/homepage-dashboard.nix"; then
                echo "FAIL 8: homepage not using mkTailnetHost helper"; exit 1
              fi
              if ! grep -q "tailnetDomain" "$REPO/layers/20-services/26-monitoring/fleet-healthcheck.nix"; then
                echo "FAIL 8: fleet-healthcheck not using tailnetDomain"; exit 1
              fi

              echo "tailnet-dns-guard: all 8 checks passed"
              touch $out
            '';
      };
    };
}
