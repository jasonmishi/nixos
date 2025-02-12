{ config, pkgs, ... }:

{
  home.username = "jasonmishi";
  home.homeDirectory = "/home/jasonmishi";

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
      themeFile = "GruvboxMaterialDarkMedium";
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
      package = pkgs.gnome-themes-extra;
    };
  };

  # Wayland, X, etc. support for session vars
  systemd.user.sessionVariables = config.home.sessionVariables;

  # not set by default keep it as the initially installed version 
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
