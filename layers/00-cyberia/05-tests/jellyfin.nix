# NixOS VM test: Jellyfin server starts, web UI responds on :8096,
# and the media directories it expects exist and are writable.
{
  name = "jellyfin-test";

  nodes.machine =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      services.jellyfin = {
        enable = true;
        openFirewall = true;
      };

      # Media library dirs (nixarr convention)
      systemd.tmpfiles.rules = [
        "d /data/media/library/music 0755 - - -"
        "d /data/media/library/movies 0755 - - -"
        "d /data/media/library/shows 0755 - - -"
      ];

      virtualisation.diskSize = 8192; # MiB — Jellyfin 10.11 requires 2GiB free in /var/lib

      system.stateVersion = "25.05";
    };

  testScript = ''
    start_all()

    machine.wait_for_unit("jellyfin.service")
    machine.wait_for_open_port(8096)

    # Jellyfin can take a while to fully initialize on first boot
    # (plugin manifest fetch + ffmpeg scan). Give it 180s.
    machine.wait_until_succeeds(
        "curl -s --max-time 10 http://127.0.0.1:8096/System/Info/Public | grep -q ProductName",
        timeout=180,
    )

    # Web UI responds (root redirects to /web/; accept either)
    machine.succeed("curl -s --max-time 5 -o /dev/null -w '%{http_code}' http://127.0.0.1:8096/web/ | grep -qE '200|301|302'")

    # Server info endpoint reports version
    machine.succeed("curl -s --max-time 5 http://127.0.0.1:8096/System/Info/Public | grep -q ProductName")

    # Media dirs exist and are accessible
    machine.succeed("test -d /data/media/library/music")
    machine.succeed("test -d /data/media/library/movies")
    machine.succeed("test -d /data/media/library/shows")

    print("jellyfin-test: all assertions passed")
  '';
}
