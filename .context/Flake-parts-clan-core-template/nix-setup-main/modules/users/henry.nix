{inputs, ...}: {
  users.users = {
    henry = {
      isNormalUser = true;
      initialPassword = "changeme";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjU7xEhfQl6Y2jwuH1po4xK8x6PdXejq60Du4YYJhi5"
      ];

      extraGroups = [
        "audio"
        "input"
        "networkmanager"
        "sound"
        "tty"
        "wheel"
        "docker"
      ];
    };
  };
}
