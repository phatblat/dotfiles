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
        ahmadawais.shades-of-purple \
        Alan.stylus \
        Apptorium.teacode-vsc-helper \
        bencoleman.armview \
        bierner.markdown-preview-github-styles \
        bungcip.better-toml \
        castwide.solargraph \
        christian-kohler.npm-intellisense \
        cmstead.js-codeformer \
        cmstead.jsrefactor \
        codezombiech.gitignore \
        DavidAnson.vscode-markdownlint \
        dbaeumer.jshint \
        dbaeumer.vscode-eslint \
        deerawan.vscode-dash \
        dkundel.vscode-npm-source \
        dnicolson.binary-plist \
        donjayamanne.githistory \
        DSnake.java-debug \
        eamodio.gitlens \
        EditorConfig.EditorConfig \
        eg2.tslint \
        eg2.vscode-npm-script \
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
        fmoronzirfas.open-in-marked \
        formulahendry.auto-close-tag \
        formulahendry.auto-rename-tag \
        formulahendry.code-runner \
        formulahendry.terminal \
        georgewfraser.vscode-javac \
        fwcd.kotlin \
        golang.go \
        HookyQR.beautify \
        humao.rest-client \
        jakearl.search-editor-apply-changes \
        jamesmaj.easy-icons \
        joelday.docthis \
        joshuapoehls.json-escaper \
        jtavin.ldif \
        JuanBlanco.solidity \
        jvitorfrancisco.theme-acid-purple \
        Kasik96.swift \
        kevinkyang.auto-comment-blocks \
        kevinmcgowan.TypeScriptImport \
        kisstkondoros.vscode-codemetrics \
        kumar-harsh.graphql-for-vscode \
        kozet.purple-night \
        leizongmin.node-module-intellisense \
        lunaryorn.fish-ide \
        mathiasfrohlich.Kotlin \
        miramac.vscode-exec-node \
        matklad.rust-analyzer \
        mechatroner.rainbow-csv \
        mhcpnl.xcodestrings \
        mikestead.dotenv \
        mitaki28.vscode-clang \
        mkaufman.HTMLHint \
        mohsen1.prettify-json \
        mongodb.mongodb-vscode \
        monokai.theme-monokai-pro-vscode \
        ms-azure-devops.azure-pipelines \
        ms-azuretools.vscode-apimanagement \
        ms-azuretools.vscode-azureappservice \
        ms-azuretools.vscode-azurefunctions \
        ms-azuretools.vscode-azureresourcegroups \
        ms-azuretools.vscode-azurestorage \
        ms-azuretools.vscode-azurevirtualmachines \
        ms-azuretools.vscode-bicep \
        ms-azuretools.vscode-cosmosdb \
        ms-azuretools.vscode-docker \
        ms-dotnettools.csharp \
        ms-dotnettools.vscode-dotnet-runtime \
        ms-kubernetes-tools.vscode-aks-tools \
        ms-kubernetes-tools.vscode-kubernetes-tools \
        ms-python.python \
        ms-python.vscode-pylance \
        ms-toolsai.jupyter \
        ms-toolsai.jupyter-keymap \
        ms-toolsai.jupyter-renderers \
        ms-toolsai.vscode-ai \
        ms-toolsai.vscode-ai-remote \
        ms-vscode-remote.remote-containers \
        ms-vscode.azure-account \
        ms-vscode.azurecli \
        ms-vscode.cpptools \
        ms-vscode.js-atom-grammar \
        ms-vscode.typescript-javascript-grammar \
        ms-vscode.vscode-node-azure-pack \
        ms-vsliveshare.vsliveshare \
        ms-vsliveshare.vsliveshare-audio \
        msazurermtools.azurerm-vscode-tools \
        msjsdiag.debugger-for-chrome \
        naumovs.node-modules-resolve \
        nepaul.editorconfiggenerator \
        nhcarrigan.vscode-purple \
        nodesource.vscode-for-node-js-development-pack \
        Perkovec.emoji \
        phplasma.csv-to-table \
        PKief.material-icon-theme \
        pkosta2005.heroku-command \
        prashaantt.node-tdd \
        rbbit.typescript-hero \
        redhat.fabric8-analytics \
        redhat.java \
        redhat.vscode-xml \
        redhat.vscode-yaml \
        ritwickdey.LiveServer \
        rust-lang.rust \
        secanis.jenkinsfile-support \
        Shan.code-settings-sync \
        shanoor.vscode-nginx \
        sidneys1.gitconfig \
        skyapps.fish-vscode \
        sohibe.java-generate-setters-getters \
        stevencl.addDocComments \
        stkb.rewrap \
        sysoev.language-stylus \
        sysoev.vscode-open-in-github \
        TabNine.tabnine-vscode \
        techer.open-in-browser \
        timonwong.shellcheck \
        Trunk.io \
        tushortz.java-imports-snippets \
        twxs.cmake \
        vadimcn.vscode-lldb \
        VisualStudioExptTeam.vscodeintellicode \
        vscjava.vscode-java-debug \
        vscjava.vscode-java-dependency \
        vscjava.vscode-java-pack \
        vscjava.vscode-java-test \
        vscjava.vscode-maven \
        vscode-icons-team.vscode-icons \
        wingrunr21.vscode-ruby \
        wix.vscode-import-cost \
        zeithaste.cursorCharCode \
        zhouronghui.propertylist \
        zhuangtongfa.material-theme \
        ziyasal.vscode-open-in-github

    # Extensions to uninstall
    set -l uninstall

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
