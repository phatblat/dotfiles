# Manages VS Code extensions.
# https://code.visualstudio.com/docs/editor/command-line#_working-with-extensions
# https://code.visualstudio.com/docs/editor/extension-gallery#_command-line-extension-management
#
# Sequencing
# - After: cask
function 🆚__vscode
    echo "🆚  VS Code"
    echo

    # Extensions to upstall
    set -l extensions \
        TeddyDD.fish \
        Apptorium.teacode-vsc-helper \
        castwide.solargraph \
        codezombiech.gitignore \
        eg2.tslint \
        fisheva.eva-theme \
        jamesmaj.easy-icons \
        lunaryorn.fish-ide \
        mathiasfrohlich.Kotlin \
        mohsen1.prettify-json \
        monokai.theme-monokai-pro-vscode \
        ms-python.python \
        ms-vscode.cpptools \
        PeterJausovec.vscode-docker \
        pkosta2005.heroku-command \
        rebornix.ruby \
        redhat.java \
        vscjava.vscode-java-debug \
        vscjava.vscode-java-pack \
        vscjava.vscode-java-test \
        vscjava.vscode-maven \
        vscodevim.vim \
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
