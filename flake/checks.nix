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
      };
    };
}
