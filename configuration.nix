# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-24.05.tar.gz";
  nixos-hardware =
    builtins.fetchGit { url = "https://github.com/NixOS/nixos-hardware.git"; };
in {
  imports = [ # Include the results of the hardware scan.
    (import "${nixos-hardware}/lenovo/thinkpad/t480")
    ./hardware-configuration.nix
    (import "${home-manager}/nixos")
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;

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
    windowManager.qtile = {
      enable = true;
      configFile = ./qtile/config.py;
    };
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

  # for power management (tlp)
  services.tlp.enable = true;

  programs = {
    git.enable = true;
    neovim.enable = true;
    firefox.enable = true;
    light.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jasonmishi = {
    isNormalUser = true;
    description = "Jason Mishike";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [
      cmus
      nicotine-plus

      poetry

      liferea

      zotero
      obsidian
      calibre
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.shellAliases = {
    sgit = ''
      sudo git -c "include.path=''${XDG_CONFIG_DIR:-$HOME/.config}/git/config" -c "include.path=$HOME/.gitconfig"'';
    vim = "nvim";
    svim = "sudo -E -s nvim";
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
    nixfmt-classic

    neofetch

    pavucontrol

    google-chrome

    vscode-fhs

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

    programs = {
      kitty = {
        enable = true;
        font.name = "Fira Code";
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

  programs.zsh.enable = true;
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
