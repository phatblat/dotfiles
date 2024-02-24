# https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions
# https://code.visualstudio.com/docs/editor/extension-gallery#_command-line-extension-management
#
# Sequencing
# - After: cask or apt
function 🆚_vscode \
    --description 'Manages VS Code extensions'

    echo "🆚 VS Code"
    echo

    # Extensions to upstall
    set -l extensions \
        2gua.rainbow-brackets \
        adelphes.android-dev-ext \
        ahmadawais.shades-of-purple \
        Alan.stylus \
        allan-carlos.night-rainbow \
        amodio.amethyst-theme \
        antfu.icons-carbon \
        Apptorium.teacode-vsc-helper \
        atommaterial.a-file-icon-vscode \
        bagetx.inf \
        bbenoist.Nix \
        bencoleman.armview \
        bierner.markdown-preview-github-styles \
        bungcip.better-toml \
        christian-kohler.npm-intellisense \
        cmstead.js-codeformer \
        cmstead.jsrefactor \
        codezombiech.gitignore \
        cschlosser.doxdocgen \
        Dart-Code.dart-code \
        Dart-Code.flutter \
        DavidAnson.vscode-markdownlint \
        dawhite.mustache \
        daylerees.rainglow \
        dbaeumer.jshint \
        dbaeumer.vscode-eslint \
        deerawan.vscode-dash \
        dhoeric.ansible-vault \
        dkundel.vscode-npm-source \
        dnicolson.binary-plist \
        donjayamanne.githistory \
        DSnake.java-debug \
        dsznajder.es7-react-js-snippets \
        eamodio.gitlens \
        ecmel.vscode-html-css \
        EditorConfig.EditorConfig \
        eg2.tslint \
        eg2.vscode-npm-script \
        Endormi.2077-theme \
        Equinusocio.vsc-community-material-theme \
        Equinusocio.vsc-material-theme \
        equinusocio.vsc-material-theme-icons \
        esafirm.kotlin-formatter \
        esbenp.prettier-vscode \
        fallenwood.vimL \
        felipecaputo.git-project-manager \
        felixrieseberg.vsc-travis-ci-status \
        fisheva.eva-theme \
        fivepointseven.node-version \
        flesler.url-encode \
        flimberger.android-system-tools \
        fmoronzirfas.open-in-marked \
        formulahendry.auto-close-tag \
        formulahendry.auto-rename-tag \
        formulahendry.code-runner \
        formulahendry.terminal \
        fwcd.kotlin \
        georgewfraser.vscode-javac \
        GitHub.copilot \
        GitHub.github-vscode-theme \
        github.vscode-github-actions \
        GitHub.vscode-pull-request-github \
        gitpod.gitpod-desktop \
        golang.go \
        hashicorp.terraform \
        HookyQR.beautify \
        HTMLHint.vscode-htmlhint \
        humao.rest-client \
        jakearl.search-editor-apply-changes \
        jamesmaj.easy-icons \
        jeff-hykin.better-cpp-syntax \
        jetmartin.bats \
        jlwoolf.makefile-tools-nameable \
        josetr.cmake-language-support-vscode \
        joshuapoehls.json-escaper \
        jtavin.ldif \
        JuanBlanco.solidity \
        jvitorfrancisco.theme-acid-purple \
        kaleidoscope-app.vscode-ksdiff \
        Kasik96.swift \
        kevinkyang.auto-comment-blocks \
        kevinmcgowan.TypeScriptImport \
        kisstkondoros.vscode-codemetrics \
        kozet.purple-night \
        kumar-harsh.graphql-for-vscode \
        leizongmin.node-module-intellisense \
        lfm.vscode-makefile-term \
        lunaryorn.fish-ide \
        mariomatheu.syntax-project-pbxproj \
        mark-wiemer.vscode-autohotkey-plus-plus \
        mathiasfrohlich.Kotlin \
        mechatroner.rainbow-csv \
        mhcpnl.xcodestrings \
        miguelsolorio.fluent-icons \
        mikestead.dotenv \
        miramac.vscode-exec-node \
        mitaki28.vscode-clang \
        mkaufman.HTMLHint \
        mohsen1.prettify-json \
        mongodb.mongodb-vscode \
        monokai.theme-monokai-pro-vscode \
        mpotthoff.vscode-android-webview-debug \
        ms-dotnettools.csdevkit \
        ms-dotnettools.csharp \
        ms-dotnettools.dotnet-maui \
        ms-dotnettools.vscode-dotnet-runtime \
        ms-dotnettools.vscodeintellicode-csharp \
        ms-python.isort \
        ms-python.python \
        ms-python.vscode-pylance \
        ms-toolsai.jupyter \
        ms-toolsai.jupyter-keymap \
        ms-toolsai.jupyter-renderers \
        ms-toolsai.vscode-jupyter-cell-tags \
        ms-toolsai.vscode-jupyter-slideshow \
        ms-vscode-remote.remote-containers \
        ms-vscode-remote.remote-ssh \
        ms-vscode-remote.remote-wsl \
        ms-vscode-remote.vscode-remote-extensionpack \
        ms-vscode.cmake-tools \
        ms-vscode.cpptools \
        ms-vscode.cpptools-extension-pack \
        ms-vscode.cpptools-themes \
        ms-vscode.js-atom-grammar \
        ms-vscode.makefile-tools \
        ms-vscode.powershell \
        ms-vscode.remote-explorer \
        ms-vscode.remote-server \
        ms-vsliveshare.vsliveshare \
        ms-vsliveshare.vsliveshare-audio \
        naco-siren.gradle-language \
        nataliefruitema.modern-purple-theme \
        naumovs.node-modules-resolve \
        nepaul.editorconfiggenerator \
        nodesource.vscode-for-node-js-development-pack \
        oderwat.indent-rainbow \
        Perkovec.emoji \
        phplasma.csv-to-table \
        PKief.material-icon-theme \
        PKief.material-product-icons \
        pkosta2005.heroku-command \
        prashaantt.node-tdd \
        rbbit.typescript-hero \
        redhat.ansible \
        redhat.fabric8-analytics \
        redhat.java \
        redhat.vscode-xml \
        redhat.vscode-yaml \
        ritwickdey.LiveServer \
        RobbOwen.synthwave-vscode \
        rust-lang.rust-analyzer \
        secanis.jenkinsfile-support \
        Shan.code-settings-sync \
        shanoor.vscode-nginx \
        sidneys1.gitconfig \
        silvenon.mdx \
        skyapps.fish-vscode \
        sohibe.java-generate-setters-getters \
        stevencl.addDocComments \
        stkb.rewrap \
        surajbarkale.ninja \
        sysoev.language-stylus \
        sysoev.vscode-open-in-github \
        tamasfe.even-better-toml \
        techer.open-in-browser \
        timonwong.shellcheck \
        tombonnike.vscode-status-bar-format-toggle \
        tonybaloney.vscode-pets \
        tushortz.java-imports-snippets \
        twxs.cmake \
        unifiedjs.vscode-mdx \
        vadimcn.vscode-lldb \
        VisualStudioExptTeam.intellicode-api-usage-examples \
        VisualStudioExptTeam.vscodeintellicode \
        vscjava.vscode-gradle \
        vscjava.vscode-java-debug \
        vscjava.vscode-java-dependency \
        vscjava.vscode-java-pack \
        vscjava.vscode-java-test \
        vscjava.vscode-maven \
        vscode-icons-team.vscode-icons \
        wholroyd.jinja \
        wingrunr21.vscode-ruby \
        wix.vscode-import-cost \
        xaver.clang-format \
        zeithaste.cursorCharCode \
        zhouronghui.propertylist \
        zhuangtongfa.material-theme \
        ziyasal.vscode-open-in-github

    # Extensions to uninstall
    set -l uninstall \
        castwide.solargraph \
        ms-kubernetes-tools.vscode-kubernetes-tools \
        msjsdiag.debugger-for-chrome \
        rebornix.ruby \
        trunk.io \
        wingrunr21.vscode-ruby

    set -l installed (code --list-extensions)

    # --------------------------------------------------------------------------
    #
    # Uninstall
    #
    # --------------------------------------------------------------------------

    # Uninstall unwanted extensions
    set -l to_uninstall
    for extension in $uninstall
        if contains $extension $installed
            set to_uninstall $to_uninstall $extension
        end
    end
    if test -n "$to_uninstall"
        for extension in $to_uninstall
            echo 🔥 Uninstalling $extension
            code --uninstall-extension $extension
        end
    end

    # --------------------------------------------------------------------------
    #
    # Upstall
    #
    # --------------------------------------------------------------------------

    # No way to update from CLI yet
    # https://github.com/Microsoft/vscode/issues/16459

    # Install new extensions
    set -l not_installed
    for extension in $extensions
        if not contains $extension $installed
            set not_installed $not_installed $extension
        end
    end
    if test -n "$not_installed"
        for extension in $not_installed
            echo 🆕 Installing $extension
            code --install-extension $extension
        end
    else
        echo 👌🏻 All extensions installed
    end
end
