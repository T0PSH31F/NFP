# Safe Nix Verification Workflow

Use this workflow to perform guarded, resource-safe Nix evaluations, flake checks, and builds.

## Steps

1. **Check System Load & Active Jobs**:
   ```bash
   ps -eo pid,ppid,etime,%cpu,%mem,cmd | grep -E '[n]ix (build|eval|flake check)' || true
   free -h
   ```

2. **Run Guarded Verification**:
   - **Static Check**:
     ```bash
     ./layers/00-cyberia/06-scripts/nfp-check.sh static
     ```
   - **Machine Evaluation**:
     ```bash
     ./layers/00-cyberia/06-scripts/nfp-check.sh eval all
     ```
   - **Flake Check**:
     ```bash
     ./layers/00-cyberia/06-scripts/nfp-check.sh flake
     ```

3. **Verify Baseline Session (`init.sh`)**:
   ```bash
   ALLOW_DIRTY=1 ./init.sh
   ```
