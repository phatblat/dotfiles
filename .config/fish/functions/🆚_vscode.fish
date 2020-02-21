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
        DSnake.java-debug \
        ahmadawais.shades-of-purple \
        Apptorium.teacode-vsc-helper \
        bierner.markdown-preview-github-styles \
        castwide.solargraph \
        christian-kohler.npm-intellisense \
        cmstead.jsrefactor \
        codezombiech.gitignore \
        DavidAnson.vscode-markdownlint \
        dbaeumer.jshint \
        dbaeumer.vscode-eslint \
        dkundel.vscode-npm-source \
        donjayamanne.githistory \
        eamodio.gitlens \
        EditorConfig.EditorConfig \
        eg2.tslint \
        eg2.vscode-npm-script \
        Equinusocio.vsc-material-theme \
        fallenwood.vimL \
        felipecaputo.git-project-manager \
        felixrieseberg.vsc-travis-ci-status \
        fisheva.eva-theme \
        fivepointseven.node-version \
        fmoronzirfas.open-in-marked \
        formulahendry.auto-close-tag \
        formulahendry.auto-rename-tag \
        formulahendry.code-runner \
        formulahendry.terminal \
        georgewfraser.vscode-javac \
        HookyQR.beautify \
        humao.rest-client \
        jamesmaj.easy-icons \
        joelday.docthis \
        Kasik96.swift \
        kevinkyang.auto-comment-blocks \
        kevinmcgowan.TypeScriptImport \
        kisstkondoros.vscode-codemetrics \
        kumar-harsh.graphql-for-vscode \
        leizongmin.node-module-intellisense \
        lunaryorn.fish-ide \
        mathiasfrohlich.Kotlin \
        miramac.vscode-exec-node \
        mitaki28.vscode-clang \
        mkaufman.HTMLHint \
        mohsen1.prettify-json \
        monokai.theme-monokai-pro-vscode \
        ms-azuretools.vscode-azurefunctions \
        ms-azuretools.vscode-docker \
        ms-python.python \
        ms-vscode.azure-account \
        ms-vscode.cpptools \
        ms-vscode.js-atom-grammar \
        ms-vscode.typescript-javascript-grammar \
        ms-vsliveshare.vsliveshare \
        ms-vsliveshare.vsliveshare-audio \
        msjsdiag.debugger-for-chrome \
        naumovs.node-modules-resolve \
        nepaul.editorconfiggenerator \
        nodesource.vscode-for-node-js-development-pack \
        PKief.material-icon-theme \
        pkosta2005.heroku-command \
        prashaantt.node-tdd \
        rbbit.typescript-hero \
        redhat.java \
        secanis.jenkinsfile-support \
        Shan.code-settings-sync \
        shanoor.vscode-nginx \
        sidneys1.gitconfig \
        skyapps.fish-vscode \
        stevencl.addDocComments \
        sysoev.language-stylus \
        sysoev.vscode-open-in-github \
        timonwong.shellcheck \
        twxs.cmake \
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
