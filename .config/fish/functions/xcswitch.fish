# Switch the active version of Xcode.
function xcswitch --argument-names xcode_version
    if not user_is_admin
        echo "You must be an admin to run this command."
        return 1
    end

    if test -z $xcode_version
        echo "Usage: xcswitch <xcode_version>"
        echo "Version format: 8.3.2"
        return 1
    end

    set -l xcode_path /Applications/Xcode-$xcode_version.app
    if not test -e $xcode_path
        echo $xcode_path does not exist.
        return 2
    end

    echo "Activating Xcode Version: $xcode_version"

    # Switch the version of Xcode on the system.
    xcss $xcode_path

    # Create an Xcode.app symlink so tools, like SwiftLint, that assume Xcode was
    # Installed via the MAS use the correct version.
    pushd /Applications

    # macOS /bin/ln has -h flag
    # https://ss64.com/osx/ln.html

    # -h    If the link_name or link_dirname is a symbolic link, do not follow it.  This is
    #       most useful with the -f option, to replace a symlink which may point to a
    #       directory.

    # -f    If the proposed link (link_name) already exists, then unlink it so that the
    #       link may occur.  (The -f option overrides any previous -i options.)

    # -s    Create a symbolic link.

    # -v    Cause ln to be verbose, showing files as they are processed.

    ln -hfsv (basename $xcode_path) Xcode.app

    # coreutils
    # https://www.gnu.org/software/coreutils/manual/html_node/ln-invocation.html#ln-invocation
    # -f,--force
    #       Remove existing destination files.

    # -s,--symbolic
    #       Make symbolic links instead of hard links. This option merely
    #       produces an error message on systems that do not support symbolic links.

    # -T,--no-target-directory
    #       Do not treat the last operand specially when it is a directory or a
    #       symbolic link to a directory. See Target directory.

    # -v,--verbose
    #       Print the name of each file after linking it successfully.

    # ln -fsTv (basename $xcode_path) Xcode.app

    popd

    xclist
    echo "Activated "(string sub --length (string length $xcode_path) (xcsp))
end
