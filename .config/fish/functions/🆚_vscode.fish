# https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions
# https://code.visualstudio.com/docs/editor/extension-gallery#_command-line-extension-management
#
# Sequencing
# - After: cask or apt
function 🆚_vscode \
    --description='Manages VS Code extensions'

    echo "🆚 VS Code"
    echo

    # Extensions to upstall
    set -l extensions \
        adelphes.android-dev-ext \
        ahmadawais.shades-of-purple \
        alan.stylus \
        allan-carlos.night-rainbow \
        amodio.amethyst-theme \
        antfu.icons-carbon \
        apptorium.teacode-vsc-helper \
        atommaterial.a-file-icon-vscode \
        bagetx.inf \
        bbenoist.nix \
        bencoleman.armview \
        bierner.markdown-preview-github-styles \
        christian-kohler.npm-intellisense \
        cmstead.js-codeformer \
        cmstead.jsrefactor \
        codezombiech.gitignore \
        cschlosser.doxdocgen \
        dart-code.dart-code \
        dart-code.flutter \
        davidanson.vscode-markdownlint \
        dawhite.mustache \
        daylerees.rainglow \
        dbaeumer.vscode-eslint \
        deerawan.vscode-dash \
        dhoeric.ansible-vault \
        dkundel.vscode-npm-source \
        dnicolson.binary-plist \
        donjayamanne.githistory \
        dsznajder.es7-react-js-snippets \
        ecmel.vscode-html-css \
        editorconfig.editorconfig \
        endormi.2077-theme \
        equinusocio.vsc-material-theme \
        equinusocio.vsc-material-theme-icons \
        esafirm.kotlin-formatter \
        esbenp.prettier-vscode \
        fallenwood.viml \
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
        fwcd.kotlin \
        georgewfraser.vscode-javac \
        github.copilot \
        github.github-vscode-theme \
        github.vscode-github-actions \
        github.vscode-pull-request-github \
        gitpod.gitpod-desktop \
        golang.go \
        hashicorp.terraform \
        htmlhint.vscode-htmlhint \
        humao.rest-client \
        jakearl.search-editor-apply-changes \
        jamesmaj.easy-icons \
        jeff-hykin.better-cpp-syntax \
        jetmartin.bats \
        jlwoolf.makefile-tools-nameable \
        josetr.cmake-language-support-vscode \
        joshuapoehls.json-escaper \
        jtavin.ldif \
        juanblanco.solidity \
        jvitorfrancisco.theme-acid-purple \
        kaleidoscope-app.vscode-ksdiff \
        kevinkyang.auto-comment-blocks \
        kevinmcgowan.typescriptimport \
        kisstkondoros.vscode-codemetrics \
        kozet.purple-night \
        kumar-harsh.graphql-for-vscode \
        leizongmin.node-module-intellisense \
        lfm.vscode-makefile-term \
        lunaryorn.fish-ide \
        mariomatheu.syntax-project-pbxproj \
        mark-wiemer.vscode-autohotkey-plus-plus \
        mathiasfrohlich.kotlin \
        mechatroner.rainbow-csv \
        mhcpnl.xcodestrings \
        miguelsolorio.fluent-icons \
        mikestead.dotenv \
        miramac.vscode-exec-node \
        mitaki28.vscode-clang \
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
        naco-siren.gradle-language \
        nataliefruitema.modern-purple-theme \
        naumovs.node-modules-resolve \
        nepaul.editorconfiggenerator \
        nodesource.vscode-for-node-js-development-pack \
        oderwat.indent-rainbow \
        perkovec.emoji \
        phplasma.csv-to-table \
        pkief.material-icon-theme \
        pkief.material-product-icons \
        pkosta2005.heroku-command \
        prashaantt.node-tdd \
        redhat.ansible \
        redhat.fabric8-analytics \
        redhat.java \
        redhat.vscode-xml \
        redhat.vscode-yaml \
        ritwickdey.liveserver \
        robbowen.synthwave-vscode \
        rust-lang.rust-analyzer \
        secanis.jenkinsfile-support \
        shanoor.vscode-nginx \
        sidneys1.gitconfig \
        skyapps.fish-vscode \
        sohibe.java-generate-setters-getters \
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
        visualstudioexptteam.intellicode-api-usage-examples \
        visualstudioexptteam.vscodeintellicode \
        vscjava.vscode-gradle \
        vscjava.vscode-java-debug \
        vscjava.vscode-java-dependency \
        vscjava.vscode-java-pack \
        vscjava.vscode-java-test \
        vscjava.vscode-maven \
        vscode-icons-team.vscode-icons \
        wholroyd.jinja \
        wix.vscode-import-cost \
        xaver.clang-format \
        zeithaste.cursorcharcode \
        zhouronghui.propertylist \
        zhuangtongfa.material-theme \
        ziyasal.vscode-open-in-github

    # Extensions to uninstall
    set -l uninstall \
        2gua.rainbow-brackets \
        bungcip.better-toml \
        castwide.solargraph \
        dbaeumer.jshint \
        eamodio.gitlens \
        eg2.tslint \
        eg2.vscode-npm-script \
        equinusocio.vsc-community-material-theme \
        formulahendry.terminal \
        hookyqr.beautify \
        kasik96.swift \
        mkaufman.htmlhint \
        ms-kubernetes-tools.vscode-kubernetes-tools \
        ms-vsliveshare.vsliveshare \
        ms-vsliveshare.vsliveshare-audio \
        msjsdiag.debugger-for-chrome \
        rebornix.ruby \
        shan.code-settings-sync \
        stevencl.adddoccomments \
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
            echo 🔥  Uninstalling $extension
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
            echo 🆕  Installing $extension
            code --install-extension $extension
        end
    else
        echo 👌🏻  All extensions installed
    end
end
