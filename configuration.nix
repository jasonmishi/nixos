# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
  nixos-hardware =
    builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; };

  # actual budget .AppImage
  version = "24.8.0";
  pname = "actual-budget";
  name = "${pname}-${version}";

  src = builtins.fetchurl {
    url =
      "https://github.com/actualbudget/actual/releases/download/v${version}/Actual-linux.AppImage";
    sha256 = "037aa78k818vv0fx3gr398lf1kmg6mkcpp98wv0vj7h6yjj8d6vd";
  };

  appimageContents = pkgs.appimageTools.extractType1 { inherit name src; };
  actual-budget = pkgs.appimageTools.wrapType1 {
    inherit name src;

    extraInstallCommands = ''
      mv $out/bin/${name} $out/bin/${pname}
      install -m 444 -D ${appimageContents}/desktop-electron.desktop -t $out/share/applications
      mv $out/share/applications/desktop-electron.desktop $out/share/applications/${pname}.desktop
      substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${appimageContents}/usr/share/icons $out/share
    '';

    meta = {
      description = "Envelop type budgeting software";
      homepage = "https://github.com/actualbudget/actual";
      downloadPage = "https://github.com/actualbudget/actual/releases";
      license = pkgs.lib.licenses.asl20;
      sourceProvenance = with pkgs.lib.sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
    };
  };

in {
  imports = [ # Include the results of the hardware scan.
    (import "${nixos-hardware}/lenovo/thinkpad/t480")
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.kernelParams = [ "psmouse.synaptics_intertouch=0" ]; # helps with touchpad issues

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set DNS resolvers
  networking.nameservers = [ "1.1.1.3" "1.0.0.3" ];
  networking.dhcpcd.extraConfig = "nohook resolv.conf";
  networking.networkmanager.dns = "none";

  # Set your time zone.
  time.timeZone = "Asia/Colombo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure X11 settings
  services.xserver = {
    xkb = {
      variant = "";
      layout = "us";
    };
    enable = true;

    # display manaer and window manager
    displayManager.lightdm.enable = true;
    windowManager.qtile = { enable = true; };
    desktopManager = {
      xterm.enable = false;
      xfce.enable = true;
    };
  };

  services.displayManager.defaultSession = "none+qtile";
  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      tappingButtonMap = "lrm";
    };
  };

  # for audio (pipewire)
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;
  };

  # for power management
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 75;
      STOP_CHARGE_THRESH_BAT0 = 80;

      START_CHARGE_THRESH_BAT1 = 75;
      STOP_CHARGE_THRESH_BAT1 = 80;

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

    };
  };

  programs = {
    git.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
    };
    java.enable = true; # jdk
    firefox.enable = true;
    light.enable = true;
    zsh.enable = true;
    starship.enable = true;
    appimage = {
      enable = true;
      binfmt = true; # add automatic use of `appimage-run` for .Appimage files
    };
  };
  environment.pathsToLink =
    [ "/share/zsh" ]; # add zsh autocompletions for system packages
  programs.ssh.startAgent = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jasonmishi = {
    isNormalUser = true;
    description = "Jason Mishike";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [
      feh # wallpaper for qtile
      flameshot # screenshots for X11

      cmus # music player
      nicotine-plus
      qbittorrent # BitTorrent client

      poetry # python package manager
      (jetbrains.plugins.addPlugins jetbrains.idea-community [ "github-copilot" ]) # intellij
      docker-compose

      libreoffice-fresh # libreoffice with latest features
      zotero # reference manager
      obsidian # next gen note taking
      calibre # ebook manager

      liferea # RSS reader subscription
      actual-budget # budgeting software
      keepassxc # password manager
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.shellAliases = {
    sgit = ''
      sudo SSH_AUTH_SOCK=$SSH_AUTH_SOCK git -c "include.path=''${XDG_CONFIG_DIR:-$HOME/.config}/git/config" -c "include.path=$HOME/.gitconfig"'';
    svim = "sudo -E -s nvim";
    upgrade = "nixos-rebuild switch --use-remote-sudo";
  };

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  nixpkgs.config.permittedInsecurePackages = [ "electron-25.9.0" ];
  environment.systemPackages = with pkgs; [
    xclip # clipboard support for neovim
    ntfs3g # ntfs(windows) filesystem support for mounting

    unzip

    nixfmt-classic

    neofetch

    pavucontrol # volume control
    jamesdsp # EQ and effects

    google-chrome

    vscode-fhs # vscode with fhs for extensions1
    neovim

    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
  ];

  fonts.packages = with pkgs;
    [ (nerdfonts.override { fonts = [ "FiraCode" ]; }) ];

  home-manager.users.jasonmishi = {
    home.packages = [
      (pkgs.buildEnv {
        name = "my-scripts";
        paths = [ ./scripts ];
      })
    ];

    home.file.qtile_config = {
      source = ./qtile;
      target = ".config/qtile";
      recursive = true;
    };

    programs = {
      kitty = {
        enable = true;
        font.name = "Fira Code";
        theme = "Gruvbox Material Dark Medium";
      };

      zsh = {
        enable = true;
        initExtra = ""; # create .zshrc file
      };

      neovim = {
        enable = true;
        plugins = [
          pkgs.vimPlugins.gruvbox-material-nvim
          {
            plugin = pkgs.vimPlugins.nvim-colorizer-lua;
            config = "lua require'colorizer'.setup()";
          }
        ];
        extraConfig = ''
          lua vim.api.nvim_set_keymap('i', 'jk', '<ESC>', { noremap = true })
          " Important!!
          if has('termguicolors')
              set termguicolors
          endif

          " For dark version.
          set background=dark
          " Set contrast.
          " This configuration option should be placed before `colorscheme gruvbox-material`.
          " Available values: 'hard', 'medium'(default), 'soft'
          let g:gruvbox_material_background = 'medium'

          " For better performance
          let g:gruvbox_material_better_performance = 1
          colorscheme gruvbox-material

          lua vim.cmd('syntax on')

          " tabs and spaces
          set smartindent
          set expandtab
          set tabstop=4
          set softtabstop=4
          set shiftwidth=4

          set number relativenumber
        '';
      };
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = { color-scheme = "prefer-dark"; };
    };

    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome.gnome-themes-extra;
      };
    };

    # Wayland, X, etc. support for session vars
    systemd.user.sessionVariables =
      config.home-manager.users.jasonmishi.home.sessionVariables;

    # not set by default keep it as the initially installed version 
    home.stateVersion = "23.11";
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  users.defaultUserShell = pkgs.zsh;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?

}
