{ inputs, ... }:
{
  perSystem =
    {
      system,
      ...
    }:
    {
      packages = {
        iso =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              inherit (import ../layers/80-lib/81-helpers/mkDendriticModule.nix { inherit (inputs.nixpkgs) lib; })
                mkDendriticModule
                ;
              inherit (import ../layers/80-lib/81-helpers/mkDendriticTree.nix { inherit (inputs.nixpkgs) lib; })
                mkDendriticTree
                ;
            };
            modules = [
              ../layers/00-cyberia/04-templates/iso/default.nix
            ];
          }).config.system.build.isoImage;

        installer-iso =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              modulesPath = "${inputs.nixpkgs}/nixos/modules";
            };
            modules = [
              ../layers/00-cyberia/08-iso/nfp-installer-iso.nix
            ];
          }).config.system.build.isoImage;

        noctalia-iso =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              modulesPath = "${inputs.nixpkgs}/nixos/modules";
            };
            modules = [
              ../layers/00-cyberia/08-iso/noctalia-installer.nix
            ];
          }).config.system.build.isoImage;

        noctalia-vm =
          (inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = {
              inherit inputs;
              modulesPath = "${inputs.nixpkgs}/nixos/modules";
              inherit (import ../layers/80-lib/81-helpers/mkDendriticModule.nix { inherit (inputs.nixpkgs) lib; })
                mkDendriticModule
                ;
              inherit (import ../layers/80-lib/81-helpers/mkDendriticTree.nix { inherit (inputs.nixpkgs) lib; })
                mkDendriticTree
                ;
            };
            modules = [
              ../layers/00-cyberia/04-templates/vm/noctalia-umbriel-vm.nix
            ];
          }).config.system.build.vm;
      };

      apps = {
        noctalia-vm = {
          type = "app";
          program = "${
            inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "run-noctalia-vm" ''
              exec nix run .#packages.${system}.noctalia-vm "$@"
            ''
          }/bin/run-noctalia-vm";
        };

        deploy = {
          type = "app";
          program = "${
            inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "deploy" ''
              exec ${../deploy.sh} "$@"
            ''
          }/bin/deploy";
        };

        healthcheck = {
          type = "app";
          program = "${
            inputs.nixpkgs.legacyPackages.${system}.writeShellScriptBin "healthcheck" ''
              if [ -f /run/nfp/healthcheck-targets.json ]; then
                exec ${inputs.nixpkgs.legacyPackages.${system}.python3}/bin/python3 -c '
              import json, sys, urllib.request, urllib.error, subprocess
              with open("/run/nfp/healthcheck-targets.json") as f: targets = json.load(f)
              failed = 0
              for t in targets:
                  name, host, url, expected, skip, unit = t["name"], t["host"], t["url"], t.get("expectedStatus", [200]), t.get("skipReason"), t.get("systemdUnit")
                  if skip:
                      if unit and subprocess.run(["systemctl", "is-active", "--quiet", unit]).returncode == 0:
                          print(f"{name:<16} | {host:<7} | unit:{unit:<33} | PASS")
                      else:
                          print(f"{name:<16} | {host:<7} | SKIP ({skip}) | SKIPPED")
                      continue
                  try:
                      req = urllib.request.Request(url, headers={"User-Agent": "NFP-Fleet-Healthcheck/1.0"})
                      with urllib.request.urlopen(req, timeout=10) as r: code = r.status
                  except urllib.error.HTTPError as e: code = e.code
                  except Exception: code = None
                  if code in expected: print(f"{name:<16} | {host:<7} | {url:<38} | {code} PASS")
                  else: print(f"{name:<16} | {host:<7} | {url:<38} | FAIL (got {code})"); failed += 1
              sys.exit(1 if failed else 0)
              '
              else:
                echo "ERROR: /run/nfp/healthcheck-targets.json not found."
                exit 1
              fi
            ''
          }/bin/healthcheck";
        };
      };
    };
}
