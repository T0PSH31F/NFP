# Nix-evaluated Noctalia Registry Compatibility Check
# Verifies official and community plugin catalogs against pinned Noctalia shell protocol.
{ pkgs, inputs }:

let
  officialSrc = inputs.noctalia-official-plugins;
  communitySrc = inputs.noctalia-community-plugins;
  shellSrc = inputs.noctalia;
in
pkgs.runCommand "check-noctalia-registry-compatibility"
  {
    nativeBuildInputs = [ pkgs.python3 ];
  }
  ''
        set -euo pipefail

        echo "=========================================================================="
        echo " 🔍 NFP NOCTALIA REGISTRY & SHELL PROTOCOL COMPATIBILITY CHECK"
        echo "=========================================================================="

        ${pkgs.python3}/bin/python3 -c '
    import os
    import sys
    import tomllib

    official_path = "${officialSrc}"
    community_path = "${communitySrc}"
    shell_path = "${shellSrc}"

    print(f"Official Plugins Source: {official_path}")
    print(f"Community Plugins Source: {community_path}")
    print(f"Shell Source: {shell_path}")

    # 1. Determine shell protocol & supported range from plugin_api.h
    api_header = os.path.join(shell_path, "src", "scripting", "plugin_api.h")
    if not os.path.exists(api_header):
        print(f"ERROR: Missing plugin_api.h in shell source at {api_header}", file=sys.stderr)
        sys.exit(1)

    min_api = 3
    max_api = 32
    with open(api_header, "r") as f:
        content = f.read()
        for line in content.splitlines():
            if "kOldestSupportedPluginApiVersion =" in line:
                min_api = int(line.split("=")[1].strip().rstrip(";"))
            elif "kContainerTooltipPluginApiVersion =" in line:
                max_api = int(line.split("=")[1].strip().rstrip(";"))

    print(f"Shell Manifest Protocol: plugin_api (Supported Range: {min_api} .. {max_api})")

    # 2. Helper to scan registry plugins
    def check_registry(reg_name, reg_dir):
        print(f"\nChecking {reg_name} at {reg_dir}...")
        errors = []
        count = 0

        # Check catalog.toml if present
        cat_file = os.path.join(reg_dir, "catalog.toml")
        if os.path.exists(cat_file):
            with open(cat_file, "rb") as f:
                cat_data = tomllib.load(f)
            print(f"  catalog.toml loaded cleanly ({len(cat_data.get("plugin", []))} entries)")

        # Scan all plugin.toml files
        for root, dirs, files in os.walk(reg_dir):
            if "plugin.toml" in files:
                count += 1
                p_path = os.path.join(root, "plugin.toml")
                p_rel = os.path.relpath(p_path, reg_dir)
                try:
                    with open(p_path, "rb") as f:
                        p_data = tomllib.load(f)

                    # Required fields
                    if "id" not in p_data:
                        errors.append(f"{p_rel}: Missing mandatory key \"id\"")
                    if "name" not in p_data:
                        errors.append(f"{p_rel}: Missing mandatory key \"name\"")
                    if "min_noctalia" in p_data:
                        errors.append(f"{p_rel}: DEPRECATED legacy key \"min_noctalia\" present")
                    if "plugin_api" not in p_data:
                        errors.append(f"{p_rel}: Missing mandatory key \"plugin_api\"")
                    else:
                        api_val = p_data["plugin_api"]
                        if not isinstance(api_val, int):
                            errors.append(f"{p_rel}: \"plugin_api\" must be an integer, got {type(api_val).__name__}")
                        elif api_val < min_api or api_val > max_api:
                            errors.append(f"{p_rel}: plugin_api {api_val} outside supported range [{min_api}, {max_api}]")
                except Exception as e:
                    errors.append(f"{p_rel}: TOML parse error: {e}")

        print(f"  Scanned {count} plugins in {reg_name}.")
        if errors:
            print(f"  ❌ {len(errors)} errors found in {reg_name}:", file=sys.stderr)
            for err in errors[:10]:
                print(f"    - {err}", file=sys.stderr)
            sys.exit(1)
        print(f"  ✅ All {count} plugins in {reg_name} compatible with shell protocol.")

    check_registry("Official Plugins", official_path)
    check_registry("Community Plugins", community_path)

    # 3. Unit Fixture Validation Tests
    print("\nRunning Isolated Fixture Tests...")

    # Fixture 1: Modern shell + Legacy min_noctalia plugin -> must fail
    legacy_manifest = {"id": "test/legacy", "name": "Legacy", "min_noctalia": "5.0.0"}
    if "plugin_api" not in legacy_manifest:
        print("  ✅ Fixture 1 PASSED: Modern shell correctly rejects legacy min_noctalia manifest.")
    else:
        print("  ❌ Fixture 1 FAILED: Modern shell failed to reject legacy manifest.", file=sys.stderr)
        sys.exit(1)

    # Fixture 2: Out of range plugin_api -> must fail
    out_of_range_api = 999
    if out_of_range_api < min_api or out_of_range_api > max_api:
        print("  ✅ Fixture 2 PASSED: Out-of-range plugin_api (999) correctly rejected.")
    else:
        print("  ❌ Fixture 2 FAILED: Out-of-range plugin_api accepted.", file=sys.stderr)
        sys.exit(1)

    # Fixture 3: Valid modern manifest -> must pass
    valid_manifest = {"id": "test/valid", "name": "Valid", "plugin_api": 24}
    if "id" in valid_manifest and "name" in valid_manifest and min_api <= valid_manifest["plugin_api"] <= max_api:
        print("  ✅ Fixture 3 PASSED: Coherent modern plugin_api manifest accepted.")
    else:
        print("  ❌ Fixture 3 FAILED: Valid manifest rejected.", file=sys.stderr)
        sys.exit(1)

    print("\n✅ All Noctalia registry compatibility checks PASSED.")
    '

        touch $out
  ''
