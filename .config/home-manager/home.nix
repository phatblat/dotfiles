{ pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "phatblat";
  home.homeDirectory = "/Users/phatblat";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = [
    # Previously installed
    pkgs.claude-code

    # CLI Tools (migrated from Homebrew)
    pkgs.act
    pkgs.apktool
    pkgs.aria2
    pkgs.awscli2
    pkgs.bat
    pkgs.bazelisk
    pkgs.btop
    pkgs.caddy
    pkgs.cmake
    pkgs.cocoapods
    pkgs.direnv
    pkgs.fish
    pkgs.fswatch
    pkgs.fzf
    pkgs.gh
    pkgs.git
    pkgs.delta
    pkgs.git-lfs
    pkgs.git-subrepo
    pkgs.gnupg
    pkgs.imagemagick
    pkgs.jdt-language-server
    pkgs.jujutsu
    pkgs.just
    pkgs.kotlin-language-server
    pkgs.lazygit
    pkgs.llvmPackages.llvm
    pkgs.gnumake
    pkgs.mas
    pkgs.mise
    pkgs.mkcert
    pkgs.neovim
    pkgs.nextdns
    pkgs.nushell
    pkgs.omnisharp-roslyn
    pkgs.pnpm
    pkgs.protobuf
    pkgs.ripgrep
    pkgs.solargraph
    pkgs.speedtest-cli
    pkgs.starship
    pkgs.todoist
    pkgs.tree
    pkgs.xcbeautify
    pkgs.xcodes
    pkgs.zig
    pkgs.zoxide
    pkgs.zsh
    pkgs.tart

    # Libraries and runtimes (migrated from Homebrew)
    pkgs.bash
    pkgs.glib
    pkgs.icu
    pkgs.ncurses
    pkgs.openssl
    pkgs.openjdk21
    pkgs.pcre2
    pkgs.pkgconf
    pkgs.python312
    pkgs.readline
    pkgs.softnet
    pkgs.sqlite

    # GUI Apps (migrated from Homebrew casks)
    # pkgs.calibre  # marked as broken in nixpkgs
    pkgs.thunderbird
    pkgs.wezterm
    pkgs.zed-editor
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/phatblat/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
