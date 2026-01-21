{
  config,
  lib,
  ...
}:
{
  # Declarative DankMaterialShell Settings
  # Converted from users settings.json
  programs.dank-material-shell.settings = {
    # Theme & Appearance
    currentThemeName = "dynamic";
    currentThemeCategory = "dynamic";
    customThemeFile = "";
    registryThemeVariants = { };
    matugenScheme = "scheme-fidelity";
    runUserMatugenTemplates = true;
    matugenTargetMonitor = "";

    # UI Customization
    popupTransparency = 1;
    dockTransparency = 1;
    widgetBackgroundColor = "sch";
    widgetColorMode = "colorful";
    cornerRadius = 12;

    # Layout Overrides
    niriLayoutGapsOverride = -1;
    niriLayoutRadiusOverride = -1;
    niriLayoutBorderSize = -1;
    hyprlandLayoutGapsOverride = -1;
    hyprlandLayoutRadiusOverride = -1;
    hyprlandLayoutBorderSize = -1;
    mangoLayoutGapsOverride = -1;
    mangoLayoutRadiusOverride = -1;
    mangoLayoutBorderSize = -1;

    # System Preferences
    use24HourClock = true;
    showSeconds = true;
    useFahrenheit = true;
    nightModeEnabled = false;

    # Animations
    animationSpeed = 3;
    customAnimationDuration = 500;

    # Wallpaper
    wallpaperFillMode = "Fill";
    blurredWallpaperLayer = false;
    blurWallpaperOnOverview = true;

    # Top Bar Toggles
    showLauncherButton = true;
    showWorkspaceSwitcher = true;
    showFocusedWindow = true;
    showWeather = true;
    showMusic = true;
    showClipboard = true;
    showCpuUsage = true;
    showMemUsage = true;
    showCpuTemp = true;
    showGpuTemp = true;
    selectedGpuIndex = 0;
    enabledGpuPciIds = [ ];
    showSystemTray = true;
    showClock = true;
    showNotificationButton = true;
    showBattery = true;
    showControlCenterButton = true;
    showCapsLockIndicator = true;

    # Control Center Toggles
    controlCenterShowNetworkIcon = true;
    controlCenterShowBluetoothIcon = true;
    controlCenterShowAudioIcon = true;
    controlCenterShowAudioPercent = false;
    controlCenterShowVpnIcon = true;
    controlCenterShowBrightnessIcon = false;
    controlCenterShowBrightnessPercent = false;
    controlCenterShowMicIcon = false;
    controlCenterShowMicPercent = false;
    controlCenterShowBatteryIcon = false;
    controlCenterShowPrinterIcon = false;

    showPrivacyButton = true;
    privacyShowMicIcon = false;
    privacyShowCameraIcon = false;
    privacyShowScreenShareIcon = false;

    # Control Center Widgets
    controlCenterWidgets = [
      {
        id = "volumeSlider";
        enabled = true;
        width = 50;
      }
      {
        id = "brightnessSlider";
        enabled = true;
        width = 50;
      }
      {
        id = "wifi";
        enabled = true;
        width = 50;
      }
      {
        id = "bluetooth";
        enabled = true;
        width = 50;
      }
      {
        id = "audioOutput";
        enabled = true;
        width = 50;
      }
      {
        id = "audioInput";
        enabled = true;
        width = 50;
      }
      {
        id = "nightMode";
        enabled = true;
        width = 50;
      }
      {
        id = "darkMode";
        enabled = true;
        width = 50;
      }
    ];

    # Workspace Settings
    showWorkspaceIndex = true;
    showWorkspaceName = false;
    showWorkspacePadding = true;
    workspaceScrolling = false;
    showWorkspaceApps = true;
    maxWorkspaceIcons = 3;
    groupWorkspaceApps = true;
    workspaceFollowFocus = false;
    showOccupiedWorkspacesOnly = false;
    reverseScrolling = false;
    dwlShowAllTags = false;

    workspaceColorMode = "default";
    workspaceUnfocusedColorMode = "default";
    workspaceUrgentColorMode = "default";
    workspaceFocusedBorderEnabled = true;
    workspaceFocusedBorderColor = "primary";
    workspaceFocusedBorderThickness = 2;
    workspaceNameIcons = { };

    # Special Features
    waveProgressEnabled = true;
    scrollTitleEnabled = true;
    audioVisualizerEnabled = true;
    audioScrollMode = "volume";

    # Compact Modes
    clockCompactMode = false;
    focusedWindowCompactMode = false;
    runningAppsCompactMode = true;
    keyboardLayoutNameCompactMode = false;

    # Running Apps
    runningAppsCurrentWorkspace = true;
    runningAppsGroupByApp = false;

    # App ID Substitutions
    appIdSubstitutions = [
      {
        pattern = "Spotify";
        replacement = "spotify";
        type = "exact";
      }
      {
        pattern = "beepertexts";
        replacement = "beeper";
        type = "exact";
      }
      {
        pattern = "home assistant desktop";
        replacement = "homeassistant-desktop";
        type = "exact";
      }
      {
        pattern = "com.transmissionbt.transmission";
        replacement = "transmission-gtk";
        type = "contains";
      }
      {
        pattern = "^steam_app_(\\d+)$";
        replacement = "steam_icon_$1";
        type = "regex";
      }
    ];

    centeringMode = "geometric";
    clockDateFormat = "";
    lockDateFormat = "";
    mediaSize = 1;

    # App Launcher (Vicinae/Rofi/Spotlight)
    appLauncherViewMode = "list";
    spotlightModalViewMode = "list";
    sortAppsAlphabetically = true;
    appLauncherGridColumns = 5;
    spotlightCloseNiriOverview = true;
    niriOverviewOverlayEnabled = true;

    # Weather & Location
    useAutoLocation = true;
    weatherEnabled = true;

    # Network
    networkPreference = "wifi";
    vpnLastConnected = "";

    # Theming Details
    iconTheme = "BeautyLine";
    cursorSettings = {
      theme = "Sonic-Hyprcursor";
      size = 36;
      niri = {
        hideWhenTyping = false;
        hideAfterInactiveMs = 0;
      };
      hyprland = {
        hideOnKeyPress = false;
        hideOnTouch = false;
        inactiveTimeout = 0;
      };
      dwl = {
        cursorHideTimeout = 0;
      };
    };

    # Launcher Logo
    launcherLogoMode = "os";
    launcherLogoCustomPath = "";
    launcherLogoColorOverride = "surface";
    launcherLogoColorInvertOnMode = false;
    launcherLogoBrightness = 0.5;
    launcherLogoContrast = 1;
    launcherLogoSizeOffset = 0;

    # Fonts
    fontFamily = "JetBrainsMono Nerd Font Mono";
    monoFontFamily = "FiraCode Nerd Font Propo";
    fontWeight = 400;
    fontScale = 1;

    # Notepad
    notepadUseMonospace = true;
    notepadFontFamily = "";
    notepadFontSize = 14;
    notepadShowLineNumbers = false;
    notepadTransparencyOverride = -1;
    notepadLastCustomTransparency = 0.7;

    # Audio
    soundsEnabled = true;
    useSystemSoundTheme = false;
    soundNewNotification = true;
    soundVolumeChanged = true;
    soundPluggedIn = true;

    # Power & Battery
    acMonitorTimeout = 7200;
    acLockTimeout = 0;
    acSuspendTimeout = 10800;
    acSuspendBehavior = 0;
    acProfileName = "";
    batteryMonitorTimeout = 0;
    batteryLockTimeout = 0;
    batterySuspendTimeout = 0;
    batterySuspendBehavior = 0;
    batteryProfileName = "";
    batteryChargeLimit = 100;
    lockBeforeSuspend = false;
    loginctlLockIntegration = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 5;
    fadeToDpmsEnabled = true;
    fadeToDpmsGracePeriod = 5;

    launchPrefix = "";

    # Pinned Devices (Empty Maps)
    brightnessDevicePins = { };
    wifiNetworkPins = { };
    bluetoothDevicePins = { };
    audioInputDevicePins = { };
    audioOutputDevicePins = { };

    # Theming Integration
    gtkThemingEnabled = true;
    qtThemingEnabled = true;
    syncModeWithPortal = true;
    terminalsAlwaysDark = true;
    runDmsMatugenTemplates = true;

    # Matugen Templates
    matugenTemplateGtk = true;
    matugenTemplateNiri = false;
    matugenTemplateHyprland = true;
    matugenTemplateMangowc = false;
    matugenTemplateQt5ct = true;
    matugenTemplateQt6ct = true;
    matugenTemplateFirefox = true;
    matugenTemplatePywalfox = true;
    matugenTemplateZenBrowser = false;
    matugenTemplateVesktop = true;
    matugenTemplateEquibop = true;
    matugenTemplateGhostty = true;
    matugenTemplateKitty = true;
    matugenTemplateFoot = true;
    matugenTemplateAlacritty = true;
    matugenTemplateNeovim = true;
    matugenTemplateWezterm = true;
    matugenTemplateDgop = true;
    matugenTemplateKcolorscheme = true;
    matugenTemplateVscode = true;

    # Dock
    showDock = false;
    dockAutoHide = false;
    dockGroupByApp = false;
    dockOpenOnOverview = false;
    dockPosition = 1;
    dockSpacing = 4;
    dockBottomGap = 0;
    dockMargin = 0;
    dockIconSize = 40;
    dockIndicatorStyle = "circle";
    dockBorderEnabled = false;
    dockBorderColor = "surfaceText";
    dockBorderOpacity = 1;
    dockBorderThickness = 1;
    dockIsolateDisplays = false;

    # Notifications
    notificationOverlayEnabled = true;
    modalDarkenBackground = true;

    # Lock Screen
    lockScreenShowPowerActions = true;
    lockScreenShowSystemIcons = true;
    lockScreenShowTime = true;
    lockScreenShowDate = true;
    lockScreenShowProfileImage = true;
    lockScreenShowPasswordField = true;
    enableFprint = false;
    maxFprintTries = 15;
    lockScreenActiveMonitor = "all";
    lockScreenInactiveColor = "#000000";
    lockScreenNotificationMode = 3;

    # OSD / Notifications
    hideBrightnessSlider = false;
    notificationTimeoutLow = 5000;
    notificationTimeoutNormal = 5000;
    notificationTimeoutCritical = 0;
    notificationCompactMode = true;
    notificationPopupPosition = 0;
    notificationHistoryEnabled = true;
    notificationHistoryMaxCount = 100;
    notificationHistoryMaxAgeDays = 7;
    notificationHistorySaveLow = true;
    notificationHistorySaveNormal = true;
    notificationHistorySaveCritical = true;

    osdAlwaysShowValue = true;
    osdPosition = 4;
    osdVolumeEnabled = true;
    osdMediaVolumeEnabled = true;
    osdBrightnessEnabled = true;
    osdIdleInhibitorEnabled = true;
    osdMicMuteEnabled = true;
    osdCapsLockEnabled = true;
    osdPowerProfileEnabled = false;
    osdAudioOutputEnabled = true;

    # Power Menu
    powerActionConfirm = true;
    powerActionHoldDuration = 0.5;
    powerMenuActions = [
      "reboot"
      "logout"
      "poweroff"
      "lock"
      "suspend"
      "restart"
      "hibernate"
    ];
    powerMenuDefaultAction = "logout";
    powerMenuGridLayout = true;
    customPowerActionLock = "";
    customPowerActionLogout = "";
    customPowerActionSuspend = "";
    customPowerActionHibernate = "";
    customPowerActionReboot = "";
    customPowerActionPowerOff = "";

    updaterHideWidget = false;
    updaterUseCustomCommand = false;
    updaterCustomCommand = "";
    updaterTerminalAdditionalParams = "";

    displayNameMode = "model";

    # Screen & Output Settings
    screenPreferences = { };
    showOnLastDisplay = { };
    niriOutputSettings = { };
    hyprlandOutputSettings = {
      "desc:LG Display 0x06EA" = {
        bitdepth = 10;
      };
      "desc:Acer Technologies XB271HK" = {
        bitdepth = 10;
      };
      "HDMI-A-1" = {
        bitdepth = 10;
      };
    };

    # Bar Configurations
    barConfigs = [
      {
        id = "default";
        name = "Main Bar";
        enabled = true;
        position = 0;
        screenPreferences = [ "all" ];
        showOnLastDisplay = true;
        leftWidgets = [
          "launcherButton"
          {
            id = "music";
            enabled = true;
            mediaSize = 3;
          }
        ];
        centerWidgets = [
          {
            id = "weather";
            enabled = true;
          }
          {
            id = "clock";
            enabled = true;
          }
          {
            id = "cpuUsage";
            enabled = true;
          }
          {
            id = "memUsage";
            enabled = true;
          }
          {
            id = "diskUsage";
            enabled = true;
          }
          {
            id = "network_speed_monitor";
            enabled = true;
          }
        ];
        rightWidgets = [
          {
            id = "clipboard";
            enabled = true;
          }
          {
            id = "notepadButton";
            enabled = true;
          }
          {
            id = "colorPicker";
            enabled = true;
          }
          {
            id = "hueManager";
            enabled = true;
          }
          {
            id = "dankPomodoroTimer";
            enabled = true;
          }
          {
            id = "notificationButton";
            enabled = true;
          }
          {
            id = "tailscale";
            enabled = true;
          }
          {
            id = "dockerManager";
            enabled = true;
          }
        ];
        spacing = 0;
        innerPadding = 5;
        bottomGap = -12;
        transparency = 0.56;
        widgetTransparency = 1;
        squareCorners = true;
        noBackground = false;
        gothCornersEnabled = true;
        gothCornerRadiusOverride = false;
        gothCornerRadiusValue = 12;
        borderEnabled = false;
        borderColor = "surfaceText";
        borderOpacity = 1;
        borderThickness = 1;
        fontScale = 1;
        autoHide = false;
        autoHideDelay = 250;
        openOnOverview = false;
        visible = true;
        popupGapsAuto = true;
        popupGapsManual = 4;
        shadowIntensity = 23;
        shadowColorMode = "primary";
        widgetOutlineEnabled = true;
        widgetOutlineThickness = 2;
        showOnWindowsOpen = false;
      }
      {
        id = "bar1768963962899";
        name = "Bar 2";
        enabled = true;
        position = 1;
        screenPreferences = [ "all" ];
        showOnLastDisplay = false;
        leftWidgets = [
          "launcherButton"
          "workspaceSwitcher"
          "focusedWindow"
        ];
        centerWidgets = [
          {
            id = "grimblast";
            enabled = true;
          }
        ];
        rightWidgets = [
          {
            id = "dankActions";
            enabled = true;
          }
          {
            id = "alarmClock";
            enabled = true;
          }
          {
            id = "systemTray";
            enabled = true;
          }
          {
            id = "easyEffects";
            enabled = true;
          }
          {
            id = "battery";
            enabled = true;
          }
          {
            id = "controlCenterButton";
            enabled = true;
          }
          {
            id = "privacyIndicator";
            enabled = true;
          }
        ];
        spacing = 0;
        innerPadding = 5;
        bottomGap = -12;
        transparency = 0.56;
        widgetTransparency = 1;
        squareCorners = true;
        noBackground = false;
        gothCornersEnabled = true;
        gothCornerRadiusOverride = false;
        gothCornerRadiusValue = 12;
        borderEnabled = false;
        borderColor = "surfaceText";
        borderOpacity = 1;
        borderThickness = 1;
        widgetOutlineEnabled = true;
        widgetOutlineColor = "primary";
        widgetOutlineOpacity = 1;
        widgetOutlineThickness = 2;
        fontScale = 1;
        autoHide = true;
        autoHideDelay = 33;
        showOnWindowsOpen = true;
        openOnOverview = false;
        visible = true;
        popupGapsAuto = true;
        popupGapsManual = 4;
        maximizeDetection = true;
        scrollEnabled = true;
        scrollXBehavior = "column";
        scrollYBehavior = "workspace";
        shadowIntensity = 23;
        shadowOpacity = 60;
        shadowColorMode = "primary";
        shadowCustomColor = "#000000";
      }
    ];

    # Desktop Widgets
    desktopClockEnabled = false;
    desktopClockStyle = "analog";
    desktopClockTransparency = 0.8;
    desktopClockColorMode = "primary";
    desktopClockCustomColor = {
      r = 1;
      g = 1;
      b = 1;
      a = 1;
      hsvHue = -1;
      hsvSaturation = 0;
      hsvValue = 1;
      hslHue = -1;
      hslSaturation = 0;
      hslLightness = 1;
      valid = true;
    };
    desktopClockShowDate = true;
    desktopClockShowAnalogNumbers = false;
    desktopClockShowAnalogSeconds = true;
    desktopClockX = -1;
    desktopClockY = -1;
    desktopClockWidth = 280;
    desktopClockHeight = 180;
    desktopClockDisplayPreferences = [ "all" ];

    systemMonitorEnabled = false;
    systemMonitorShowHeader = true;
    systemMonitorTransparency = 0.8;
    systemMonitorColorMode = "primary";
    systemMonitorCustomColor = {
      r = 1;
      g = 1;
      b = 1;
      a = 1;
      hsvHue = -1;
      hsvSaturation = 0;
      hsvValue = 1;
      hslHue = -1;
      hslSaturation = 0;
      hslLightness = 1;
      valid = true;
    };
    systemMonitorShowCpu = true;
    systemMonitorShowCpuGraph = true;
    systemMonitorShowCpuTemp = true;
    systemMonitorShowGpuTemp = false;
    systemMonitorGpuPciId = "";
    systemMonitorShowMemory = true;
    systemMonitorShowMemoryGraph = true;
    systemMonitorShowNetwork = true;
    systemMonitorShowNetworkGraph = true;
    systemMonitorShowDisk = true;
    systemMonitorShowTopProcesses = true;
    systemMonitorTopProcessCount = 3;
    systemMonitorTopProcessSortBy = "cpu";
    systemMonitorGraphInterval = 60;
    systemMonitorLayoutMode = "auto";
    systemMonitorX = -1;
    systemMonitorY = -1;
    systemMonitorWidth = 320;
    systemMonitorHeight = 480;
    systemMonitorDisplayPreferences = [ "all" ];

    systemMonitorVariants = [ ];
    desktopWidgetPositions = { };
    desktopWidgetGridSettings = { };
    desktopWidgetInstances = [ ];
    desktopWidgetGroups = [ ];

    # Built-in Plugin Settings
    builtInPluginSettings = {
      dms_settings_search = {
        trigger = "?";
      };
    };

    configVersion = 5;
  };
}
