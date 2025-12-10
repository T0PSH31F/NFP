{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.omarchy-nix.nixosModules.default
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.luks.devices."luks-e66c6fd1-b2f2-469c-8af8-b0e4a46a3644".device = "/dev/disk/by-uuid/e66c6fd1-b2f2-469c-8af8-b0e4a46a3644";
  networking.hostName = "luffy"; 
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  
  # Clan-core networking for remote deployment
  clan.core.networking.targetHost = "root@192.168.8.212";
  
  # Omarchy configuration
  omarchy = {
    enable = true;
    full_name = "t0psh31f";
    email_address = "t0psh31f@example.com";
    theme = "catppuccin-mocha"; # Use Catppuccin Mocha theme
  };
  
  # Define a user account.
  users.users.t0psh31f = {
    isNormalUser = true;
   # initialPassword = "changeme";
    hashedPassword = "$6$rcE5fxWVkSf/5v/w$CTV8V85IPFB5cGW2B2rsxxeccNf.KUiHDaoDH1WMoNvW1j/NqzbEaOD27Jj2SpA3wUbAGsThn2VhsjoR6YdOE/";
    description = "t0psh31f";
    extraGroups = [ "wheel" "networkmanager" ];
    
    # Enable home-manager with omarchy integration
    home-manager = {
      useGlobalPkgs = true;
      users.t0psh31f = {
        imports = [
          inputs.omarchy-nix.homeManagerModules.default
        ];
        
        # Omarchy home-manager configuration
        omarchy = {
          enable = true;
          # Configure omarchy applications and settings for the user
        };
      };
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    lsd
    gedit
    git
  ];

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };  

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
  enable = true;
   settings = {
     PasswordAuthentication = false;
     	    PermitRootLogin = "prohibit-password";
  };
 };

  # Configure SSH authorized keys for root user using clan-core vars
  users.users.root.openssh.authorizedKeys.keys =
    let
      # Get SSH keys from clan-core vars framework
      vars = if config ? clan.core.vars then config.clan.core.vars else {};
      machineVars = if (vars ? per-machine) && (vars.per-machine ? luffy)
                    then vars.per-machine.luffy
                    else {};
      sshKeys = if (machineVars ? openssh) then machineVars.openssh else {};
      publicKey = if (sshKeys ? "ssh.id_ed25519.pub")
                  then sshKeys."ssh.id_ed25519.pub"
                  else "";
    in
      if publicKey != ""
      then [ publicKey ]
      else [];

  # Open ports in the firewall.
   networking.firewall.allowedTCPPorts = [ 22 2222 ];
   networking.firewall.allowedUDPPorts = [ 22 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable Hyprland Wayland compositor with SDDM
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  programs.hyprland.enable = true;
  
  # Enable automatic login for the user
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "t0psh31f";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
