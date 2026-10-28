{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  speed = config.layers.layer-30.theming.themes.plymouth-onepiece.speed or "fast";

  onepiece-theme = pkgs.stdenv.mkDerivation {
    pname = "plymouth-theme-onepiece";
    version = "2026-unstable";

    src = pkgs.fetchFromGitHub {
      owner = "Anxhul10";
      repo = "onePiece-plymouth";
      rev = "ec9358d88e82367ba252781491654717605c719e";
      hash = "sha256-eZVLorbgnEz7Aff30j+PV2NNi8BuT6KgXJ0vmjncQfs=";
    };

    installPhase = ''
            mkdir -p $out/share/plymouth/themes/onePiece-plymouth
            cp -r * $out/share/plymouth/themes/onePiece-plymouth/

            cat << 'EOF' > $out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script
      for(i = 0; i <= 371; i++)
        one_piece_image_arr[i] = Image("/media/740af368-d542-4bb1-bd29-e22ceb8c8b72-"+i+".png");

      pos_x = Window.GetWidth()/2 - one_piece_image_arr[0].GetWidth()/2;
      pos_y = Window.GetHeight()/2 - one_piece_image_arr[0].GetHeight()/2;

      sprite = Sprite(one_piece_image_arr[0]);
      sprite.SetX(pos_x);
      sprite.SetY(pos_y);

      count = 0;
      step = ${if speed == "slow" then "1" else "2"};

      fun refresh_callback () {
        if (count > 370)
          count = 0;
        sprite.SetImage(one_piece_image_arr[count]);
        sprite.SetOpacity(1);
        sprite.SetZ(15);
        count += step;
      }

      Plymouth.SetRefreshFunction (refresh_callback);

      # Interactive Password & Dialogue Support (LUKS Passphrase prompt)
      prompt_sprite = Sprite();
      prompt_sprite.SetZ(100);

      bullets_sprite = Sprite();
      bullets_sprite.SetZ(100);

      message_sprite = Sprite();
      message_sprite.SetZ(100);

      fun display_password_callback (prompt, bullets) {
        prompt_image = Image.Text(prompt, 1.0, 0.9, 0.4, 1.0, "Sans 14", "center");
        prompt_sprite.SetImage(prompt_image);
        prompt_sprite.SetX(Window.GetWidth() / 2 - prompt_image.GetWidth() / 2);
        prompt_sprite.SetY(pos_y + one_piece_image_arr[0].GetHeight() + 20);
        prompt_sprite.SetOpacity(1);

        bullet_str = "";
        for (i = 0; i < bullets; i++) {
          bullet_str += "* ";
        }
        if (bullets > 0) {
          bullets_image = Image.Text(bullet_str, 0.3, 0.85, 1.0, 1.0, "Sans 16", "center");
          bullets_sprite.SetImage(bullets_image);
          bullets_sprite.SetX(Window.GetWidth() / 2 - bullets_image.GetWidth() / 2);
          bullets_sprite.SetY(prompt_sprite.GetY() + prompt_image.GetHeight() + 10);
          bullets_sprite.SetOpacity(1);
        } else {
          bullets_sprite.SetOpacity(0);
        }
      }

      fun display_question_callback (prompt, text) {
        prompt_image = Image.Text(prompt, 1.0, 0.9, 0.4, 1.0, "Sans 14", "center");
        prompt_sprite.SetImage(prompt_image);
        prompt_sprite.SetX(Window.GetWidth() / 2 - prompt_image.GetWidth() / 2);
        prompt_sprite.SetY(pos_y + one_piece_image_arr[0].GetHeight() + 20);
        prompt_sprite.SetOpacity(1);

        if (text) {
          text_image = Image.Text(text, 1.0, 1.0, 1.0, 1.0, "Sans 14", "center");
          bullets_sprite.SetImage(text_image);
          bullets_sprite.SetX(Window.GetWidth() / 2 - text_image.GetWidth() / 2);
          bullets_sprite.SetY(prompt_sprite.GetY() + prompt_image.GetHeight() + 10);
          bullets_sprite.SetOpacity(1);
        } else {
          bullets_sprite.SetOpacity(0);
        }
      }

      fun display_normal_callback () {
        prompt_sprite.SetOpacity(0);
        bullets_sprite.SetOpacity(0);
      }

      fun display_message_callback (text) {
        msg_image = Image.Text(text, 1.0, 0.3, 0.3, 1.0, "Sans 12", "center");
        message_sprite.SetImage(msg_image);
        message_sprite.SetX(Window.GetWidth() / 2 - msg_image.GetWidth() / 2);
        message_sprite.SetY(Window.GetHeight() - 60);
        message_sprite.SetOpacity(1);
      }

      fun hide_message_callback (text) {
        message_sprite.SetOpacity(0);
      }

      Plymouth.SetDisplayPasswordFunction (display_password_callback);
      Plymouth.SetDisplayQuestionFunction (display_question_callback);
      Plymouth.SetDisplayNormalFunction (display_normal_callback);
      Plymouth.SetDisplayMessageFunction (display_message_callback);
      Plymouth.SetHideMessageFunction (hide_message_callback);
      EOF

            substituteInPlace $out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.plymouth \
              --replace-fail "ImageDir=/usr/share/plymouth/themes/onePiece-plymouth" "ImageDir=$out/share/plymouth/themes/onePiece-plymouth" \
              --replace-fail "ScriptFile=/usr/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script" "ScriptFile=$out/share/plymouth/themes/onePiece-plymouth/onePiece-plymouth.script"
    '';
  };
in
{
  options.layers.layer-30.theming.themes.plymouth-onepiece = {
    enable = mkEnableOption "One Piece animated Plymouth boot splash";
    speed = mkOption {
      type = types.enum [
        "fast"
        "slow"
      ];
      default = "fast";
      description = "Animation speed for One Piece Plymouth theme (fast or slow)";
    };
  };

  config = mkIf config.layers.layer-30.theming.themes.plymouth-onepiece.enable {
    environment.systemPackages = [ onepiece-theme ];

    boot = {
      initrd = {
        systemd.enable = lib.mkDefault true;
        verbose = false;
      };

      plymouth = {
        enable = true;
        theme = "onePiece-plymouth";
        themePackages = [ onepiece-theme ];
        extraConfig = ''
          DeviceScale=1
        '';
      };

      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "splash"
        "loglevel=3"
        "rd.udev.log_level=3"
        "vt.global_cursor_default=0"
        "systemd.show_status=auto"
      ];
    };
  };
}
