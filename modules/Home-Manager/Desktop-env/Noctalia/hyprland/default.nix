{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.desktop.noctalia;
in
{
  # Noctalia Hyprland backend configuration
  # This module is imported when desktop.noctalia.backend = "hyprland"

  config = lib.mkIf (cfg.enable && cfg.backend == "hyprland") {
    # Enable Hyprland
    desktop.hyprland.enable = true;

    # Import IPC module only (keybinds are handled separately)
    home-manager.users.t0psh31f = {
      imports = [
        ./ipc.nix
      ];

      # Add Noctalia shell startup to Hyprland
      wayland.windowManager.hyprland.settings = {
        #    layerrule = lib.mkAfter [
        #     # Noctalia background layers (frosty glass effect)
        #     "noctalia, namespace: noctalia-background-.*, ignore_alpha: 0.5, blur: true, blur_passes: 3, blur_size: 8, blur_popups: true"
        #
        #     # Additional Noctalia layers (notifications, OSD, etc.)
        #     "noctalia, namespace: noctalia-.*, ignore_alpha: 0.8, blur: true, dim: 0.1"
        #   ];

        exec-once = [
          "noctalia-shell & disown" # Start Noctalia shell
        ];
      };

      programs.noctalia-shell = {
        enable = true;
        settings = lib.mkMerge [
          {
            settingsVersion = 46;
            bar = {
              barType = "framed";
              position = "top";
              monitors = [ ];
              density = "comfortable";
              showOutline = true;
              showCapsule = true;
              capsuleOpacity = 1;
              backgroundOpacity = 0.88;
              useSeparateOpacity = true;
              floating = false;
              marginVertical = 4;
              marginHorizontal = 4;
              frameThickness = 9;
              frameRadius = 16;
              outerCorners = true;
              exclusive = true;
              hideOnOverview = false;
              widgets = {
                left = [
                  {
                    icon = "rocket";
                    id = "Launcher";
                    usePrimaryColor = false;
                  }
                  {
                    customFont = "Nabla";
                    formatHorizontal = "h:mm AP ddd, MMM dd";
                    formatVertical = "HH mm - dd MM";
                    id = "Clock";
                    tooltipFormat = "h:mm AP ddd, MMM dd";
                    useCustomFont = true;
                    usePrimaryColor = false;
                  }
                  {
                    compactMode = true;
                    diskPath = "/";
                    id = "SystemMonitor";
                    showCpuTemp = true;
                    showCpuUsage = true;
                    showDiskUsage = false;
                    showGpuTemp = false;
                    showLoadAverage = false;
                    showMemoryAsPercent = false;
                    showMemoryUsage = true;
                    showNetworkStats = false;
                    showSwapUsage = false;
                    useMonospaceFont = true;
                    usePrimaryColor = false;
                  }
                  {
                    colorizeIcons = false;
                    hideMode = "hidden";
                    id = "ActiveWindow";
                    maxWidth = 145;
                    scrollingMode = "hover";
                    showIcon = true;
                    useFixedWidth = false;
                  }
                ];
                center = [
                  {
                    compactMode = false;
                    compactShowAlbumArt = true;
                    compactShowVisualizer = false;
                    hideMode = "transparent";
                    hideWhenIdle = false;
                    id = "MediaMini";
                    maxWidth = 200;
                    panelShowAlbumArt = true;
                    panelShowVisualizer = true;
                    scrollingMode = "always";
                    showAlbumArt = true;
                    showArtistFirst = true;
                    showProgressRing = true;
                    showVisualizer = true;
                    useFixedWidth = false;
                    visualizerType = "mirrored";
                  }
                  {
                    characterCount = 2;
                    colorizeIcons = false;
                    emptyColor = "secondary";
                    enableScrollWheel = true;
                    focusedColor = "primary";
                    followFocusedScreen = false;
                    groupedBorderOpacity = 1;
                    hideUnoccupied = false;
                    iconScale = 0.8;
                    id = "Workspace";
                    labelMode = "index";
                    occupiedColor = "secondary";
                    reverseScroll = false;
                    showApplications = false;
                    showBadge = true;
                    showLabelsOnlyWhenOccupied = true;
                    unfocusedIconsOpacity = 1;
                  }
                  {
                    colorName = "tertiary";
                    hideWhenIdle = true;
                    id = "AudioVisualizer";
                    width = 200;
                  }
                ];
                right = [
                  { id = "plugin:todo"; }
                  {
                    blacklist = [ ];
                    colorizeIcons = false;
                    drawerEnabled = true;
                    hidePassive = false;
                    id = "Tray";
                    pinned = [ ];
                  }
                  { id = "plugin:clipper"; }
                  { id = "plugin:screenshot"; }
                  { id = "plugin:mini-docker"; }
                  { id = "plugin:openhue"; }
                  {
                    deviceNativePath = "";
                    displayMode = "onhover";
                    hideIfIdle = false;
                    hideIfNotDetected = true;
                    id = "Battery";
                    showNoctaliaPerformance = false;
                    showPowerProfiles = false;
                    warningThreshold = 30;
                  }
                  {
                    displayMode = "onhover";
                    id = "Volume";
                    middleClickCommand = "pwvucontrol || pavucontrol";
                  }
                  {
                    colorizeDistroLogo = false;
                    colorizeSystemIcon = "none";
                    customIconPath = "";
                    enableColorization = false;
                    icon = "noctalia";
                    id = "ControlCenter";
                    useDistroLogo = false;
                  }
                ];
              };
              screenOverrides = [ ];
            };
            general = {
              avatarImage = "/home/t0psh31f/Background/terminal.gif";
              dimmerOpacity = 0.26;
              showScreenCorners = true;
              forceBlackScreenCorners = false;
              scaleRatio = 1.05;
              radiusRatio = 1.17;
              iRadiusRatio = 0.78;
              boxRadiusRatio = 1;
              screenRadiusRatio = 1.21;
              animationSpeed = 0.5;
              animationDisabled = false;
              compactLockScreen = false;
              lockOnSuspend = true;
              showSessionButtonsOnLockScreen = true;
              showHibernateOnLockScreen = false;
              enableShadows = true;
              shadowDirection = "top";
              shadowOffsetX = 0;
              shadowOffsetY = -3;
              language = "";
              allowPanelsOnScreenWithoutBar = true;
              showChangelogOnStartup = true;
              telemetryEnabled = false;
              enableLockScreenCountdown = true;
              lockScreenCountdownDuration = 5000;
              autoStartAuth = false;
              allowPasswordWithFprintd = false;
            };
            ui = {
              fontDefault = "JetBrainsMono Nerd Font";
              fontFixed = "GohuFont 14 Nerd Font Mono";
              fontDefaultScale = 1.05;
              fontFixedScale = 1.1;
              tooltipsEnabled = true;
              panelBackgroundOpacity = 0.95;
              panelsAttachedToBar = true;
              settingsPanelMode = "attached";
              wifiDetailsViewMode = "grid";
              bluetoothDetailsViewMode = "grid";
              networkPanelView = "wifi";
              bluetoothHideUnnamedDevices = false;
              boxBorderEnabled = true;
            };
            location = {
              name = "Los_Angeles";
              weatherEnabled = true;
              weatherShowEffects = true;
              useFahrenheit = true;
              use12hourFormat = true;
              showWeekNumberInCalendar = true;
              showCalendarEvents = true;
              showCalendarWeather = true;
              analogClockInCalendar = true;
              firstDayOfWeek = -1;
              hideWeatherTimezone = false;
              hideWeatherCityName = false;
            };
            calendar = {
              cards = [
                {
                  enabled = true;
                  id = "calendar-header-card";
                }
                {
                  enabled = true;
                  id = "calendar-month-card";
                }
                {
                  enabled = true;
                  id = "weather-card";
                }
              ];
            };
            wallpaper = {
              enabled = true;
              overviewEnabled = true;
              directory = "/home/t0psh31f/Background/wallpapernumber";
              monitorDirectories = [ ];
              enableMultiMonitorDirectories = false;
              showHiddenFiles = true;
              viewMode = "single";
              setWallpaperOnAllMonitors = true;
              fillMode = "crop";
              fillColor = "#000000";
              useSolidColor = false;
              solidColor = "#1a1a2e";
              automationEnabled = false;
              wallpaperChangeMode = "random";
              randomIntervalSec = 900;
              transitionDuration = 1500;
              transitionType = "random";
              transitionEdgeSmoothness = 0.05;
              panelPosition = "follow_bar";
              hideWallpaperFilenames = false;
              useWallhaven = false;
              wallhavenQuery = "";
              wallhavenSorting = "relevance";
              wallhavenOrder = "desc";
              wallhavenCategories = "111";
              wallhavenPurity = "100";
              wallhavenRatios = "";
              wallhavenApiKey = "";
              wallhavenResolutionMode = "atleast";
              wallhavenResolutionWidth = "";
              wallhavenResolutionHeight = "";
            };
            appLauncher = {
              enableClipboardHistory = true;
              autoPasteClipboard = true;
              enableClipPreview = true;
              clipboardWrapText = true;
              clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
              clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
              position = "top_center";
              pinnedApps = [ ];
              useApp2Unit = false;
              sortByMostUsed = true;
              terminalCommand = "ghostty -e";
              customLaunchPrefixEnabled = true;
              customLaunchPrefix = "uwsm app -- ";
              viewMode = "grid";
              showCategories = true;
              iconMode = "tabler";
              showIconBackground = false;
              enableSettingsSearch = true;
              ignoreMouseInput = false;
              screenshotAnnotationTool = "";
            };
            controlCenter = {
              position = "close_to_bar_button";
              diskPath = "/";
              shortcuts = {
                left = [
                  { id = "Network"; }
                  { id = "Bluetooth"; }
                  { id = "WallpaperSelector"; }
                  { id = "NoctaliaPerformance"; }
                ];
                right = [
                  { id = "Notifications"; }
                  { id = "PowerProfile"; }
                  { id = "KeepAwake"; }
                  { id = "NightLight"; }
                  { id = "WiFi"; }
                ];
              };
              cards = [
                {
                  enabled = true;
                  id = "profile-card";
                }
                {
                  enabled = true;
                  id = "shortcuts-card";
                }
                {
                  enabled = true;
                  id = "audio-card";
                }
                {
                  enabled = false;
                  id = "brightness-card";
                }
                {
                  enabled = true;
                  id = "weather-card";
                }
                {
                  enabled = true;
                  id = "media-sysmon-card";
                }
              ];
            };
            systemMonitor = {
              cpuWarningThreshold = 80;
              cpuCriticalThreshold = 90;
              tempWarningThreshold = 80;
              tempCriticalThreshold = 90;
              gpuWarningThreshold = 80;
              gpuCriticalThreshold = 90;
              memWarningThreshold = 80;
              memCriticalThreshold = 90;
              swapWarningThreshold = 80;
              swapCriticalThreshold = 90;
              diskWarningThreshold = 80;
              diskCriticalThreshold = 90;
              cpuPollingInterval = 3000;
              tempPollingInterval = 3000;
              gpuPollingInterval = 3000;
              enableDgpuMonitoring = false;
              memPollingInterval = 3000;
              diskPollingInterval = 30000;
              networkPollingInterval = 3000;
              loadAvgPollingInterval = 3000;
              useCustomColors = false;
              warningColor = "";
              criticalColor = "";
              externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
            };
            dock = {
              enabled = true;
              position = "bottom";
              displayMode = "auto_hide";
              backgroundOpacity = 1;
              floatingRatio = 1;
              size = 0.79;
              onlySameOutput = true;
              monitors = [ ];
              pinnedApps = [ ];
              colorizeIcons = true;
              pinnedStatic = true;
              inactiveIndicators = true;
              deadOpacity = 0.6;
              animationSpeed = 1;
            };
            network = {
              wifiEnabled = true;
              bluetoothRssiPollingEnabled = false;
              bluetoothRssiPollIntervalMs = 10000;
              wifiDetailsViewMode = "grid";
              bluetoothDetailsViewMode = "grid";
              bluetoothHideUnnamedDevices = false;
            };
            sessionMenu = {
              enableCountdown = true;
              countdownDuration = 5000;
              position = "center";
              showHeader = true;
              largeButtonsStyle = true;
              largeButtonsLayout = "single-row";
              showNumberLabels = true;
              powerOptions = [
                {
                  action = "lock";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
                {
                  action = "suspend";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
                {
                  action = "hibernate";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
                {
                  action = "reboot";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
                {
                  action = "logout";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
                {
                  action = "shutdown";
                  command = "";
                  countdownEnabled = true;
                  enabled = true;
                }
              ];
            };
            notifications = {
              enabled = true;
              monitors = [ ];
              location = "top";
              overlayLayer = true;
              backgroundOpacity = 1;
              respectExpireTimeout = false;
              lowUrgencyDuration = 3;
              normalUrgencyDuration = 8;
              criticalUrgencyDuration = 15;
              enableKeyboardLayoutToast = true;
              saveToHistory = {
                low = true;
                normal = true;
                critical = true;
              };
              sounds = {
                enabled = true;
                volume = 0.5;
                separateSounds = true;
                criticalSoundFile = "";
                normalSoundFile = "";
                lowSoundFile = "";
                excludedApps = "discord,firefox,chrome,chromium,edge";
              };
              enableMediaToast = false;
            };
            osd = {
              enabled = true;
              location = "top_right";
              autoHideMs = 2000;
              overlayLayer = true;
              backgroundOpacity = 1;
              enabledTypes = [
                0
                1
                2
                3
              ];
              monitors = [ ];
            };
            audio = {
              volumeStep = 5;
              volumeOverdrive = true;
              cavaFrameRate = 30;
              visualizerType = "mirrored";
              mprisBlacklist = [ ];
              preferredPlayer = "";
              volumeFeedback = true;
            };
            brightness = {
              brightnessStep = 5;
              enforceMinimum = true;
              enableDdcSupport = true;
            };
            colorSchemes = {
              useWallpaperColors = true;
              predefinedScheme = "Catppuccin";
              darkMode = true;
              schedulingMode = "off";
              manualSunrise = "06:30";
              manualSunset = "18:30";
              generationMethod = "fruit-salad";
              monitorForColors = "";
            };
            templates = {
              activeTemplates = [
                {
                  enabled = true;
                  id = "alacritty";
                }
                {
                  enabled = true;
                  id = "gtk";
                }
                {
                  enabled = true;
                  id = "kcolorscheme";
                }
                {
                  enabled = true;
                  id = "pywalfox";
                }
                {
                  enabled = true;
                  id = "vicinae";
                }
                {
                  enabled = true;
                  id = "yazi";
                }
                {
                  enabled = true;
                  id = "btop";
                }
                {
                  enabled = true;
                  id = "foot";
                }
                {
                  enabled = true;
                  id = "helix";
                }
                {
                  enabled = true;
                  id = "kitty";
                }
                {
                  enabled = true;
                  id = "qt";
                }
                {
                  enabled = true;
                  id = "code";
                }
                {
                  enabled = true;
                  id = "zathura";
                }
                {
                  enabled = true;
                  id = "cava";
                }
                {
                  enabled = true;
                  id = "hyprland";
                }
                {
                  enabled = true;
                  id = "fuzzel";
                }
                {
                  enabled = true;
                  id = "spicetify";
                }
                {
                  enabled = true;
                  id = "zed";
                }
                {
                  enabled = true;
                  id = "discord";
                }
                {
                  enabled = true;
                  id = "ghostty";
                }
                {
                  enabled = true;
                  id = "hyprtoolkit";
                }
                {
                  enabled = true;
                  id = "telegram";
                }
                {
                  enabled = true;
                  id = "wezterm";
                }
              ];
              enableUserTheming = true;
            };
            nightLight = {
              enabled = true;
              forced = true;
              autoSchedule = true;
              nightTemp = "4000";
              dayTemp = "6500";
              manualSunrise = "06:30";
              manualSunset = "18:30";
            };
            hooks = {
              enabled = false;
              wallpaperChange = "";
              darkModeChange = "";
              screenLock = "";
              screenUnlock = "";
              performanceModeEnabled = "";
              performanceModeDisabled = "";
              startup = "";
              session = "";
            };
            desktopWidgets = {
              enabled = false;
              gridSnap = false;
              monitorWidgets = [ ];
            };
          }
          cfg.settings
        ];
      };
    };
  };
}
