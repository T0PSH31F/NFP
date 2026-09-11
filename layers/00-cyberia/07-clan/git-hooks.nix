# Git Pre-commit & Pre-push Hooks
#
# treefmt runs in --fail-on-change (lint) mode — it CHECKS formatting but
# never auto-rewrites files during a commit. This prevents the hook from
# mass-reformatting unrelated files mid-commit and forcing --no-verify bypasses.
#
# For deliberate formatting: run `nix fmt` manually.
# init.sh also runs `nix fmt -- --fail-on-change` as step [2/5].
#
# Fast nix eval of both machine toplevels guards pre-push.
{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      system,
      config,
      ...
    }:
    {
      checks.pre-commit-check = inputs.git-hooks-nix.lib.${system}.run {
        src = ../../../.;
        hooks = {
          treefmt = {
            enable = true;
            package = config.treefmt.build.wrapper;
            # --fail-on-change: lint mode — exits non-zero if any file would be
            # reformatted, without modifying files. Prevents silent mass-reformat
            # of the entire project tree on every commit.
            settings.fail-on-change = true;
          };
          nix-eval-toplevels = {
            enable = true;
            name = "Fast nix eval of machine toplevels";
            entry = toString (
              pkgs.writeShellScript "nix-eval-toplevels" ''
                set -euo pipefail
                exec >/dev/null 2>&1
                nix eval --raw .#nixosConfigurations.luffy.config.system.build.toplevel.drvPath
                nix eval --raw .#nixosConfigurations.z0r0.config.system.build.toplevel.drvPath
                nix eval --raw .#nixosConfigurations.nami.config.system.build.toplevel.drvPath
              ''
            );
            stages = [ "pre-push" ];
            pass_filenames = false;
          };
        };
      };
    };
}
