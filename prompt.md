Generate a NixOS configuration flake based on Clan-core (refer to docs at docs.clan.lol) with integration of flake-parts (docs in flake.parts). Configure two machines:

    Primary laptop "luffy", local IP 192.168.1.182

    Secondary laptop "z0r0", local IP 192.168.159

Configure for admin/home-manager user "t0psh31f" with system.stateVersion and home-manager versions set to "25.05".

Include configurable toggles at the top level to quickly switch desktop environments per machine.

Support these three configurable desktop flakes via Clan inventory:

    Omarchy-Nix (https://github.com/henrysipp/omarchy-nix?tab=readme-ov-file)

    Caelestia-Shell (https://github.com/caelestia-dots/shell?tab=readme-ov-file)

    Illogical-impulse-flake (https://github.com/soymou/illogical-flake)

Enable Tailscale connectivity between machines.

Use dendritic pattern for file and directory organization to complement clan-core auto-import directories. Reference documentation: https://github.com/mightyiam/dendritic.
Example use of pattern in the wild: https://github.com/perstarkse/infra.

Handle variables, SOPS encryption, and SSH key generation automatically or provide detailed instructions for required user input before rebuilding and switching to this setup.

Consider best practices and common pitfalls for building with Omarchy-Nix; see discussion: https://github.com/basecamp/omarchy/discussions/987.

Ensure the flake builds and works with zero manual post-configuration steps, fully automating setup and applying all configurations cleanly.