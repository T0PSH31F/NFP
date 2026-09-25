# System Audit & Diagnostic Tool Module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.layers.layer-10.system.audit;
  sysauditPkg = pkgs.writeShellApplication {
    name = "sysaudit";
    runtimeInputs = with pkgs; [
      sysbench
      fio
      lm_sensors
      systemd
      coreutils
      gawk
      gnugrep
    ];
    text = builtins.readFile ../../00-cyberia/06-scripts/system-audit.sh;
  };
in
{
  options.layers.layer-10.system.audit = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable system health audit tooling (sysaudit)";
    };
    referenceCpuScore = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "Expected reference CPU benchmark score";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      sysauditPkg
      # Forensics toolkit for incident response (e.g. auditctl kill-trap
      # for unexplained SIGKILLs, bpftrace/sysdig for syscall tracing).
      pkgs.audit
      pkgs.bpftrace
      pkgs.sysdig
    ];
  };
}
