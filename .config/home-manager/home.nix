{ pkgs, config, vscode-extensions, ... }:

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
    # Custom packages
    (pkgs.callPackage ./packages/opcode.nix { })

    # CLI Tools (migrated from Homebrew)
    # Note: act, awscli2, bat, bazelisk, caddy, delta, fzf, gh, git-lfs, jujutsu,
    #       mas, neovim, pnpm, starship, xcodes, zig, zoxide → managed by mise
    pkgs.apktool
    pkgs.aria2
    pkgs.fish
    pkgs.fswatch # no mise backend available
    pkgs.git
    pkgs.git-subrepo
    pkgs.gnupg
    pkgs.jdt-language-server
    pkgs.kotlin-language-server
    pkgs.llvmPackages.llvm
    pkgs.gnumake
    # pkgs.mise  # migrated to direct install via https://mise.run
    pkgs.nextdns
    pkgs.nushell
    pkgs.omnisharp-roslyn
    pkgs.shellharden
    pkgs.solargraph
    pkgs.speedtest-cli
    pkgs.todoist
    pkgs.tree # no mise backend available
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

  # VS Code extensions (migrated from Brewfile)
  programs.vscode = {
    enable = true;
    package = pkgs.emptyDirectory; # VS Code installed via Homebrew cask
    extensions = with vscode-extensions.vscode-marketplace; [
      _4ops.packer
      aaronyoung.dark-synthwave-vscode
      adelphes.android-dev-ext
      ahmadawais.shades-of-purple
      alan.stylus
      allan-carlos.night-rainbow
      altbdoor.change-tab-size
      amodio.amethyst-theme
      antfu.icons-carbon
      apptorium.teacode-vsc-helper
      atommaterial.a-file-icon-vscode
      bagetx.inf
      bazelbuild.vscode-bazel
      bbenoist.nix
      bencoleman.armview
      bierner.markdown-preview-github-styles
      bmalehorn.vscode-fish
      christian-kohler.npm-intellisense
      christian-kohler.path-intellisense
      cmstead.js-codeformer
      cmstead.jsrefactor
      codezombiech.gitignore
      continue.continue
      cschlosser.doxdocgen
      dart-code.dart-code
      dart-code.flutter
      davidanson.vscode-markdownlint
      dawhite.mustache
      daylerees.rainglow
      dbaeumer.vscode-eslint
      deerawan.vscode-dash
      dhoeric.ansible-vault
      didericis.starlark
      dkundel.vscode-npm-source
      dnicolson.binary-plist
      donjayamanne.githistory
      dsznajder.es7-react-js-snippets
      ecmel.vscode-html-css
      editorconfig.editorconfig
      endormi._2077-theme
      eriklynd.json-tools
      esafirm.kotlin-formatter
      esbenp.prettier-vscode
      fabiospampinato.vscode-open-in-github
      fallenwood.viml
      felipecaputo.git-project-manager
      felixrieseberg.vsc-travis-ci-status
      file-icons.file-icons
      fisheva.eva-theme
      fivepointseven.node-version
      flesler.url-encode
      flimberger.android-system-tools
      fmoronzirfas.open-in-marked
      formulahendry.auto-close-tag
      formulahendry.auto-rename-tag
      formulahendry.code-runner
      fwcd.kotlin
      georgewfraser.vscode-javac
      github.copilot-chat
      github.github-vscode-theme
      github.vscode-github-actions
      gitpod.gitpod-desktop
      golang.go
      hashicorp.hcl
      hashicorp.terraform
      helligechris.synthwave-vscode-renew
      htmlhint.vscode-htmlhint
      humao.rest-client
      jakearl.search-editor-apply-changes
      jamesmaj.easy-icons
      jasonnutter.search-node-modules
      jeff-hykin.better-cpp-syntax
      jetmartin.bats
      jlwoolf.makefile-tools-nameable
      josetr.cmake-language-support-vscode
      joshuapoehls.json-escaper
      jtavin.ldif
      juanblanco.solidity
      jvitorfrancisco.theme-acid-purple
      kaleidoscope-app.vscode-ksdiff
      kevinkyang.auto-comment-blocks
      kevinmcgowan.typescriptimport
      kisstkondoros.vscode-codemetrics
      kozet.purple-night
      kumar-harsh.graphql-for-vscode
      leizongmin.node-module-intellisense
      lfm.vscode-makefile-term
      lunaryorn.fish-ide
      makashi.dark-purple
      mariomatheu.syntax-project-pbxproj
      mark-wiemer.vscode-autohotkey-plus-plus
      mathiasfrohlich.kotlin
      me-dutour-mathieu.vscode-github-actions
      mechatroner.rainbow-csv
      meshintelligenttechnologiesinc.pieces-vscode
      mhcpnl.xcodestrings
      miguelsolorio.fluent-icons
      mikestead.dotenv
      miramac.vscode-exec-node
      mitaki28.vscode-clang
      mohsen1.prettify-json
      mongodb.mongodb-vscode
      monokai.theme-monokai-pro-vscode
      mpotthoff.vscode-android-webview-debug
      ms-dotnettools.vscode-dotnet-runtime
      ms-python.debugpy
      ms-python.isort
      ms-python.python
      ms-python.vscode-pylance
      ms-python.vscode-python-envs
      ms-toolsai.jupyter
      ms-toolsai.jupyter-keymap
      ms-toolsai.jupyter-renderers
      ms-toolsai.vscode-jupyter-cell-tags
      ms-toolsai.vscode-jupyter-slideshow
      ms-vscode-remote.remote-containers
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      ms-vscode-remote.remote-wsl
      ms-vscode-remote.vscode-remote-extensionpack
      ms-vscode.cmake-tools
      ms-vscode.cpp-devtools
      ms-vscode.cpptools
      ms-vscode.cpptools-extension-pack
      ms-vscode.cpptools-themes
      ms-vscode.extension-test-runner
      ms-vscode.js-atom-grammar
      ms-vscode.makefile-tools
      ms-vscode.powershell
      ms-vscode.remote-explorer
      ms-vscode.remote-server
      msnilshartmann.blue-light
      naco-siren.gradle-language
      nataliefruitema.modern-purple-theme
      naumovs.node-modules-resolve
      nefrob.vscode-just-syntax
      nepaul.editorconfiggenerator
      nodesource.vscode-for-node-js-development-pack
      nur.just-black
      nyxb.materialiconic-product-icons
      obrejla.netbeans-light-theme
      oderwat.indent-rainbow
      pbkit.vscode-pbkit
      perkovec.emoji
      phplasma.csv-to-table
      pkief.material-icon-theme
      pkief.material-product-icons
      pkosta2005.heroku-command
      pokey.parse-tree
      prashaantt.node-tdd
      redhat.ansible
      redhat.java
      redhat.vscode-xml
      redhat.vscode-yaml
      ritwickdey.liveserver
      robbowen.synthwave-vscode
      rust-lang.rust-analyzer
      rvest.vs-code-prettier-eslint
      samuelcolvin.jinjahtml
      sclu1034.justfile
      secanis.jenkinsfile-support
      shanoor.vscode-nginx
      shd101wyy.markdown-preview-enhanced
      shopify.ruby-lsp
      sidneys1.gitconfig
      skellock.just
      skyapps.fish-vscode
      sohibe.java-generate-setters-getters
      surajbarkale.ninja
      sysoev.language-stylus
      sysoev.vscode-open-in-github
      tamasfe.even-better-toml
      techer.open-in-browser
      timonwong.shellcheck
      tombonnike.vscode-status-bar-format-toggle
      tonybaloney.vscode-pets
      tushortz.java-imports-snippets
      twxs.cmake
      unifiedjs.vscode-mdx
      vadimcn.vscode-lldb
      vscjava.vscode-gradle
      vscjava.vscode-java-debug
      vscjava.vscode-java-dependency
      vscjava.vscode-java-pack
      vscjava.vscode-java-test
      vscjava.vscode-maven
      vscode-icons-team.vscode-icons
      wholroyd.jinja
      wix.vscode-import-cost
      xabikos.javascriptsnippets
      xaver.clang-format
      zeithaste.cursorcharcode
      zhouronghui.propertylist
      zhuangtongfa.material-theme
      ziyasal.vscode-open-in-github
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
