# Target 2: Proxmox / KVM QCOW2 VM Profile with Cloud-Init
{ modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
    ../configuration.nix
  ];
  jarvis.deploymentTarget = "proxmox-qcow2";
  services.cloud-init = {
    enable = true;
    network.enable = true;
  };
  services.qemuGuest.enable = true;
}
