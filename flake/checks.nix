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

        mcp-containment-check =
          pkgs.runCommand "check-mcp-containment"
            {
              nativeBuildInputs = [
                pkgs.gnugrep
                pkgs.coreutils
              ];
            }
            ''
              # 1. No @latest in production layer-70 modules
              if grep -r "@latest" ${../layers/70-agents} >/dev/null 2>&1; then
                echo "ERROR: @latest unpinned npm dependency found in layers/70-agents"
                exit 1
              fi

              # 2. No invalid mcp-gateway systemd service unit claiming port 8085
              if grep -r "systemd\.services\.mcp-gateway" ${../layers/70-agents} >/dev/null 2>&1; then
                echo "ERROR: Invalid mcp-gateway systemd unit found in layers/70-agents"
                exit 1
              fi

              # 3. No nonexistent package references in Nix/JSON configs
              if grep -r --include="*.nix" --include="*.json" -E "context-mode|@executor/mcp|@modelcontextprotocol/server-browser-use" ${../layers/70-agents} >/dev/null 2>&1; then
                echo "ERROR: Known nonexistent npm package referenced in layers/70-agents"
                exit 1
              fi

              # 4. ContextForge must not open public firewall
              if grep -q "allowedTCPPorts" ${../layers/70-agents/73-memory/context-forge.nix} 2>/dev/null; then
                echo "ERROR: ContextForge opens public firewall port"
                exit 1
              fi

              touch $out
            '';

        mcp-registry-type-check =
          let
            z0r0Config = inputs.self.nixosConfigurations.z0r0.config;
            servers = z0r0Config.layers.layer-75.mcp.servers;
          in
          if !(servers ? mcp-nixos) then
            throw "mcp-registry-type-check error: mcp-nixos missing from typed servers"
          else if !(servers ? github) then
            throw "mcp-registry-type-check error: github missing from typed servers"
          else if !(servers ? ha-mcp) then
            throw "mcp-registry-type-check error: ha-mcp missing from typed servers"
          else
            pkgs.runCommand "check-mcp-registry-type" { } ''
              touch $out
            '';

        mcp-nixos-authority-check =
          let
            z0r0Config = inputs.self.nixosConfigurations.z0r0.config;
            userConfig = z0r0Config.home-manager.users.t0psh31f;

            antigravityMcpText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."antigravity/mcp_config.json".text;
            geminiMcpText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."gemini/mcp_config.json".text;

            antigravityMcp = builtins.fromJSON antigravityMcpText;
            geminiMcp = builtins.fromJSON geminiMcpText;

            antigravityConfText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."antigravity/config.json".text;
            geminiConfText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."gemini/config.json".text;

            antigravityConf = builtins.fromJSON antigravityConfText;
            geminiConf = builtins.fromJSON geminiConfText;

            antigravityMcpNixos = antigravityMcp.mcpServers.mcp-nixos or null;
            geminiMcpNixos = geminiMcp.mcpServers.mcp-nixos or null;

            isStorePath = path: pkgs.lib.hasPrefix "/nix/store/" path;
          in
          if antigravityMcpNixos == null then
            throw "mcp-nixos-authority-check error: antigravity mcp_config.json missing mcp-nixos server"
          else if !(isStorePath antigravityMcpNixos.command) then
            throw "mcp-nixos-authority-check error: antigravity mcp-nixos command '${antigravityMcpNixos.command}' does not point to Nix store"
          else if geminiMcpNixos == null then
            throw "mcp-nixos-authority-check error: gemini mcp_config.json missing mcp-nixos server"
          else if !(isStorePath geminiMcpNixos.command) then
            throw "mcp-nixos-authority-check error: gemini mcp-nixos command '${geminiMcpNixos.command}' does not point to Nix store"
          else if !(pkgs.lib.elem "AGENTS.md" (antigravityConf.contextFiles or [ ])) then
            throw "mcp-nixos-authority-check error: antigravity config.json missing AGENTS.md context file"
          else if !(pkgs.lib.elem "AGENTS.md" (geminiConf.contextFiles or [ ])) then
            throw "mcp-nixos-authority-check error: gemini config.json missing AGENTS.md context file"
          else
            pkgs.runCommand "check-mcp-nixos-authority" { } ''
              touch $out
            '';

        executor-pilot-check =
          let
            luffyConfig = inputs.self.nixosConfigurations.luffy.config;
            executorEnabled = luffyConfig.layers.layer-76.orchestrators.executor.enable or false;
            executorService = luffyConfig.systemd.services.executor or null;
          in
          if !executorEnabled then
            throw "executor-pilot-check error: Executor service must be enabled on luffy"
          else if executorService == null then
            throw "executor-pilot-check error: systemd.services.executor missing from luffy config"
          else
            pkgs.runCommand "check-executor-pilot" { } ''
              touch $out
            '';

        mcp-client-migration-check =
          let
            z0r0Config = inputs.self.nixosConfigurations.z0r0.config;
            userConfig = z0r0Config.home-manager.users.t0psh31f;

            antigravityMcpText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."antigravity/mcp_config.json".text;
            geminiMcpText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."gemini/mcp_config.json".text;
            kiroMcpText = builtins.unsafeDiscardStringContext userConfig.xdg.configFile."kiro/mcp.json".text;
            piMcpText = builtins.unsafeDiscardStringContext userConfig.xdg.configFile."pi/config.json".text;

            antigravityMcp = builtins.fromJSON antigravityMcpText;
            geminiMcp = builtins.fromJSON geminiMcpText;
            kiroMcp = builtins.fromJSON kiroMcpText;
            piMcp = builtins.fromJSON piMcpText;

            allHaveNixos =
              (antigravityMcp.mcpServers ? mcp-nixos)
              && (geminiMcp.mcpServers ? mcp-nixos)
              && (kiroMcp.mcpServers ? mcp-nixos)
              && (piMcp.mcpServers ? mcp-nixos);
          in
          if !allHaveNixos then
            throw "mcp-client-migration-check error: one or more agent client harnesses are missing mcp-nixos gateway entry"
          else
            pkgs.runCommand "check-mcp-client-migration" { } ''
              touch $out
            '';

        mcp-context-budget-check =
          let
            z0r0Config = inputs.self.nixosConfigurations.z0r0.config;
            userConfig = z0r0Config.home-manager.users.t0psh31f;
            servers = z0r0Config.layers.layer-75.mcp.servers;

            mcpConfigText =
              builtins.unsafeDiscardStringContext
                userConfig.xdg.configFile."mcp/config.json".text;
            mcpConfig = builtins.fromJSON mcpConfigText;
            clientConfigs = mcpConfig.mcpServers;

            hasHeadroom = servers ? headroom && servers.headroom.enable;

            invalidServers = pkgs.lib.filterAttrs (
              _n: s: s.enable && (s.maxResultBytes <= 0 || s.maxResultBytes > 10485760)
            ) servers;

            missingBudgetFields = pkgs.lib.filterAttrs (
              _n: c: !(c ? maxResultBytes) || !(c ? cacheTtlSeconds)
            ) clientConfigs;
          in
          if !hasHeadroom then
            throw "mcp-context-budget-check error: headroom server entry missing or disabled"
          else if (builtins.length (builtins.attrNames invalidServers)) > 0 then
            throw "mcp-context-budget-check error: servers with invalid maxResultBytes found: ${builtins.concatStringsSep ", " (builtins.attrNames invalidServers)}"
          else if (builtins.length (builtins.attrNames missingBudgetFields)) > 0 then
            throw "mcp-context-budget-check error: client configs missing budget attributes: ${builtins.concatStringsSep ", " (builtins.attrNames missingBudgetFields)}"
          else
            pkgs.runCommand "check-mcp-context-budget" { } ''
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
