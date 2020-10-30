{ pkgs, localConfigFile ? ./local.nix, ... }:

let
  nixpkgsConfig = import ./nixpkgs-config.nix;

  aliases = ''
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'

    alias xclip='xclip -selection c'
    alias rs="exec -l $SHELL"

    sys() {
      PATH="/run/wrappers/bin:/run/current-system/sw/bin:/run/current-system/sw/sbin" $@
    }

    ops() {
      eval $(op signin "$1")
    }

    hmu() {
      nix run --impure github:mammothbane/dotfiles/master
    }

    neuron() {
      command neuron -d "$HOME/.local/neuron" "$@"
    }
  '';

  homepkgs      = pkgs.callPackage ./pkgs {};

  # localConfig = with ownlib; let
    # tryLocal  = tryCallPackage localConfigFile {};
    # local     = orDefault tryLocal {};
  # in {
    # graphical = false;
  # } // local;

  localConfig = {
    graphical = false;
  };

  pinentry = if localConfig.graphical
    then pkgs.pinentry_qt5
    else pkgs.pinentry;

  graphicalPackages = with pkgs; [
    discord
    slack

    minecraft

    alacritty

    spotify

    shutter

    yubikey-personalization
    yubioath-desktop
  ];

  graphicalPrograms = {
    obs-studio = { enable = true; };
  };

in {
  nixpkgs = {
    config = nixpkgsConfig;
  };

  xdg.configFile = {
    "nixpkgs/config.nix".source = ./nixpkgs-config.nix;

    "alacritty/alacritty.yml".text = builtins.toJSON {
      env.TERM = "xterm-256color";
      window.dimensions = {
      };

      key_bindings = [
      ];

      draw_bold_text_with_bright_colors = true;

      colors = builtins.fromJSON (builtins.readFile ./alacritty/base16-tomorrow-night.json);
    };
  } // (
    let
      overrides = builtins.attrNames (builtins.readDir ./override/xdg-config);
    in pkgs.lib.foldl' (acc: x: acc // { "${x}" = { recursive = true; source = ./override/xdg-config + "/${x}"; }; }) {} overrides
  );

  home = {
    stateVersion = "20.09";

    file."home" = {
      source = ./override/home;
      recursive = true;
      target = ".";
    };

    packages = with pkgs; [
      jq
      ripgrep
      fd
      xclip
      iotop
      curl
      socat
      wget
      youtube-dl
      nmap
      gnupg
      yaml2json
      coreutils
      unzip
      bashInteractive
      less
      file
      binutils
      which
      gnugrep
      gnutar
      openssh
      patchelf
      findutils
      gawk
      utillinux
      bzip2
      e2fsprogs
      diffutils
      flock
      acl
      gzip
      inetutils
      iproute
      iputils
      kmod
      dosfstools
      ntfs3g
      netcat-gnu
      gnupatch
      procps
      rr
      gdb
      gnused
      strace
      linuxPackages.perf
      lzma
      gzip
      systemd
      cmake
      dos2unix

      openssl

      _1password
      # neuron

      nixUnstable
      nix-index
      arion
      cachix

      cordless
      ncspot

      glibcLocales

      python3
      rustup
      elixir_1_10
      ghc

      gocode

      pinentry

      homepkgs.tulip.dump
      homepkgs.tulip.restore
    ]
    ++ homepkgs.wrapSetuids [
      "sudo"
      "sudoedit"
      "su"
      "passwd"
      "newgrp"
      "newuidmap"
      "newgidmap"
      "sg"
      "start_kdeinit"
      "unix_chkpwd"
      "kcheckpass"
      "fusermount"
      "fusermount3"
      "dbus-daemon-launch-helper"
      "ping"
    ]
    # ++ (with import <nixpkgs/nixos> { configuration = {}; }; with config.system.build; [
      # nixos-generate-config
      # nixos-install
      # nixos-enter
      # nixos-rebuild
      # manual.manpages
    # ])
    ++ pkgs.lib.optionals localConfig.graphical graphicalPackages;

    sessionVariables = {
      GCC_COLORS = "error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01";
      EDITOR = "nvim";
      VISUAL = "nvim";
      KEYTIMEOUT = 1;
      LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      PATH = "$HOME/.nix-profile/bin:$HOME/.nix-profile/sbin";
      PAGER = "${pkgs.less}/bin/less";
    };
  };

  news.display = "silent";

  programs = {
    home-manager.enable = true;

    neovim = import ./vim.nix { inherit pkgs; };
    git = import ./git.nix { inherit pkgs; };

    direnv = {
      enable = true;

      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    command-not-found.enable = true;

    broot = {
      enable = true;

      enableZshIntegration = true;
      enableBashIntegration = true;
    };

    bash = {
      enable = true;

      sessionVariables = {
      };

      initExtra = aliases;
    };

    go = {
      enable = true;
      goPath = "src/go";
    };

    htop = {
      enable = true;
      delay = 6;
      hideThreads = true;
      hideUserlandThreads = true;
      highlightBaseName = true;
    };

    lesspipe.enable = true;

    readline = {
      enable = true;
      variables = {
        editing-mode = "vi";
        show-mode-in-prompt = true;
      };
    };

    ssh = {
      enable = true;
      controlMaster = "no";
      controlPersist = "10m";
      forwardAgent = true;

      matchBlocks = let
        viaProxy = { host, user, name ? null }: let
          config = {
            inherit user;
            hostname = host;
            proxyJump = "vpn.tulip.co";
          };
        in

        { "${host}" = config; }
          // (if name != null then { "${name}" = config; } else {});

        nonProxied = {
          "somali-derp.com" = {
            user = "mammothbane";
          };

          "vpn.tulip.co" = {
            user = "developer";
          };
        };

        proxied = [
          { user = "ubuntu"; host = "deploy.bulb.cloud"; name = "tulip-staging"; }
          { user = "ubuntu"; host = "deploy.tulip.co"; name = "tulip-prod"; }
          { user = "ubuntu"; host = "deploy-eu-central-1.tulipintra.net"; name = "tulip-eu"; }
          { user = "ubuntu"; host = "deploy-eu-central-1.dmgmori-tulipintra.net"; name = "tulip-dmgm"; }
        ];
      in
      builtins.foldl' (acc: x: acc // (viaProxy x))
        nonProxied
        proxied;

      extraConfig = ''
      '';
    };

    tmux = {
      enable = true;
      keyMode = "vi";

      extraConfig = ''
        bind '"' split-window -c "#{pane_current_path}"
        bind % split-window -h -c "#{pane_current_path}"
        bind c new-window -c "#{pane_current_path}"

        bind-key -n C-S-Left swap-window -t -1
        bind-key -n C-S-Right swap-window -t +1
      '';

      tmuxp.enable = true;
    };

    zsh = {
      enable = true;
      dotDir = ".config/zsh";

      sessionVariables = {
        MODE_INDICATOR = "%{$fg_bold[yellow]%}[% NORMAL]% %{$reset_color%}";
      };

      initExtra = aliases + ''
      '';

      profileExtra = ''
      '';

      loginExtra = ''
      '';

      logoutExtra = ''
      '';

      oh-my-zsh = {
        enable = true;

        plugins = [
          "gitfast"
          "vi-mode"
          "sudo"
        ];

        theme = "robbyrussell";
      };
    };

    keychain = {
      enable = false;
      agents = [
        "gpg"
        "ssh"
      ];
      inheritType = "any";
      extraFlags = [
        "--gpg2"
        "--systemd"
      ];
    };

    # TODO
    irssi = {};
    notmuch = {};
    starship = {};
  } // pkgs.lib.optionalAttrs localConfig.graphical graphicalPrograms;

  services = {
    gpg-agent = {
      enable = true;
      enableExtraSocket = true;
      enableSshSupport = true;
      enableScDaemon = true;
      defaultCacheTtl = 60;
      maxCacheTtl = 120;

      extraConfig = ''
        pinentry-program ${pinentry}/bin/pinentry
      '';
    };

    keybase.enable = true;
    lorri.enable = true;

    spotifyd.enable = true;

    # TODO(unstable)
    # lieer = {};
    muchsync = {};
    polybar = {};
    random-background = {};
  };

  systemd.user = {
    paths = {
    };

    services = {
    };

    sessionVariables = {
      GSM_SKIP_SSH_AGENT_WORKAROUND = "1";
    };

    startServices = true;
  };
}
