# layers/20-services/26-monitoring/fleet-healthcheck.nix
# Consumer engine generating fleet healthcheck oneshot service, timer, and targets JSON from nfp.services contracts.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.layers.layer-20.services.config.fleet-healthcheck;
  enabledServices = filterAttrs (_name: svc: svc.enable) (config.nfp.services or { });
  healthcheckServices = filterAttrs (_name: svc: svc.healthcheck.enable) enabledServices;

  # Tailnet authority: derive from layers.meta.tailnetDomain (nfp.nix). Fallback only for early eval before meta wired.
  baseDomain =
    config.layers.meta.tailnetDomain or config.services.headscale-server.baseDomain or "nfp.nix";

  # Build JSON list of targets from enabled contract healthchecks
  # For tls != "none" (Tailnet via Caddy), probe via tailnetName (audiobookshelf.nfp.nix)
  # rather than host:port direct — keeps upstream (127.0.0.1:8000) and Caddy tailnet separate
  targetsList = mapAttrsToList (
    name: svc:
    let
      targetHost = if svc.tls != "none" then svc.tailnetName else svc.host;
      targetUrl =
        if svc.tls != "none" then
          "http://${targetHost}.${baseDomain}${svc.healthcheck.path}"
        else
          "http://${svc.host}.${baseDomain}:${toString svc.port}${svc.healthcheck.path}";
    in
    {
      inherit name;
      inherit (svc) host;
      inherit (svc) port;
      inherit (svc) tailnetName;
      url = targetUrl;
      path = svc.healthcheck.path;
      expectedStatus =
        if builtins.isList svc.healthcheck.expectedStatus then
          svc.healthcheck.expectedStatus
        else
          [ svc.healthcheck.expectedStatus ];
      method = svc.healthcheck.method;
      timeoutSec = svc.healthcheck.timeoutSec;
      skipReason = svc.healthcheck.skipReason;
      systemdUnit = svc.healthcheck.systemdUnit;
    }
  ) healthcheckServices;

  targetsJson = pkgs.writeText "healthcheck-targets.json" (builtins.toJSON targetsList);

  runnerScript = pkgs.writeScriptBin "fleet-healthcheck-runner" ''
    #!${pkgs.python3}/bin/python3
    import json
    import os
    import sys
    import urllib.request
    import urllib.error
    import subprocess
    import time

    targets_file = os.environ.get("HEALTHCHECK_TARGETS_FILE", "/run/nfp/healthcheck-targets.json")
    if not os.path.exists(targets_file):
        targets_file = "${targetsJson}"

    os.makedirs("/run/nfp", exist_ok=True)
    try:
        with open("${targetsJson}", "r") as src, open("/run/nfp/healthcheck-targets.json", "w") as dst:
            dst.write(src.read())
    except Exception:
        pass

    try:
        with open(targets_file, "r") as f:
            targets = json.load(f)
    except Exception as e:
        print(f"ERROR: Failed to read healthcheck targets JSON from {targets_file}: {e}", file=sys.stderr)
        sys.exit(1)

    print("======================================================================================")
    print("🌐 NFP FLEET HEALTHCHECK REPORT")
    print("======================================================================================")
    print(f"{'SERVICE':<16} | {'HOST':<7} | {'TARGET':<38} | {'STATUS':<7} | {'RESULT'}")
    print("--------------------------------------------------------------------------------------")

    total = len(targets)
    passed = 0
    failed = 0
    skipped = 0
    failures = []

    for t in targets:
        name = t.get("name", "unknown")
        host = t.get("host", "unknown")
        url = t.get("url", "")
        expected = t.get("expectedStatus", [200])
        method = t.get("method", "GET")
        timeout = t.get("timeoutSec", 10)
        skip_reason = t.get("skipReason")
        unit = t.get("systemdUnit")

        if skip_reason:
            if unit:
                res = subprocess.run(["systemctl", "is-active", "--quiet", unit])
                if res.returncode == 0:
                    print(f"{name:<16} | {host:<7} | {'unit:' + unit:<38} | {'ACTIVE':<7} | PASS")
                    passed += 1
                else:
                    print(f"{name:<16} | {host:<7} | {'unit:' + unit:<38} | {'INACTIVE':<7} | FAIL ({skip_reason})")
                    failed += 1
                    failures.append(f"{name} ({unit} inactive: {skip_reason})")
            else:
                print(f"{name:<16} | {host:<7} | {'SKIP (' + skip_reason + ')':<38} | {'N/A':<7} | SKIPPED")
                skipped += 1
            continue

        req = urllib.request.Request(url, method=method)
        req.add_header("User-Agent", "NFP-Fleet-Healthcheck/1.0")
        code = None
        status_str = "ERR"
        result_str = "FAIL"

        try:
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                code = resp.status
        except urllib.error.HTTPError as e:
            code = e.code
        except Exception:
            code = None

        if code is not None:
            status_str = str(code)
            if code in expected:
                result_str = "PASS"
                passed += 1
            else:
                result_str = f"FAIL (got {code}, expected {expected})"
                failed += 1
                failures.append(f"{name}@{host}:{url} returned {code}, expected {expected}")
        else:
            status_str = "OFFLINE"
            result_str = "FAIL (Unreachable / Timeout)"
            failed += 1
            failures.append(f"{name}@{host}:{url} unreachable")

        print(f"{name:<16} | {host:<7} | {url:<38} | {status_str:<7} | {result_str}")

    print("--------------------------------------------------------------------------------------")
    print(f"SUMMARY: {total} total, {passed} passed, {failed} failed, {skipped} skipped.")
    print("======================================================================================")

    status_data = {
        "timestamp": time.time(),
        "total": total,
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "failures": failures,
        "success": failed == 0
    }
    try:
        with open("/run/nfp/healthcheck-status.json", "w") as sf:
            json.dump(status_data, sf, indent=2)
    except Exception:
        pass

    if failed > 0:
        print(f"FLEET HEALTHCHECK FAILED: {failed} service(s) failing!", file=sys.stderr)
        sys.exit(1)
    else:
        print("FLEET HEALTHCHECK SUCCESS: All probed services healthy!")
        sys.exit(0)
  '';
in
{
  options.layers.layer-20.services.config.fleet-healthcheck = {
    enable = mkEnableOption "Contract-driven fleet healthcheck runner and systemd timer";

    interval = mkOption {
      type = types.str;
      default = "15m";
      description = "Frequency for systemd timer to run fleet healthcheck.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ runnerScript ];

    # Ensure /run/nfp directory exists and populated with targets
    systemd.tmpfiles.rules = [
      "d /run/nfp 0755 root root -"
      "L+ /run/nfp/healthcheck-targets.json - - - - ${targetsJson}"
    ];

    systemd.services.fleet-healthcheck = {
      description = "Contract-Driven Fleet Healthcheck Runner";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${runnerScript}/bin/fleet-healthcheck-runner";
        StandardOutput = "journal+console";
        StandardError = "journal+console";
        SyslogIdentifier = "fleet-healthcheck";
      };
    };

    systemd.timers.fleet-healthcheck = {
      description = "Timer for Fleet Healthcheck Service";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
      };
    };
  };
}
