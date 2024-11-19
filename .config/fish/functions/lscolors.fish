# lscolors

#
# CLICOLOR
# Use ANSI color sequences to distinguish file types.  See LSCOLORS below.
# In addition to the file types mentioned in the -F option some
# extra attributes (setuid bit set, etc.) are also displayed.  The
# colorization is dependent on a terminal type with the proper termcap(5)
# capabilities.  The default ``cons25'' console has the proper
# capabilities, but to display the colors in an xterm(1), for example,
# the TERM variable must be set to ``xterm-color''.  Other terminal types
# may require similar adjustments.  Colorization is silently disabled if the
# output isn't directed to a terminal unless the CLICOLOR_FORCE variable
# is defined.
#
# CLICOLOR_FORCE
# Color sequences are normally disabled if the output isn't directed to a
# terminal.  This can be overridden by setting this flag.  The TERM
# variable still needs to reference a color capable terminal however
# otherwise it is not possible to determine which color sequences to use.
function lscolors --argument-names theme
    if test -z $theme
        set theme help
    end

    switch $theme
        # blue foreground with default background for directories, magenta
        # foreground with default background for symbolic links, etc.
        case default
            set --global --export CLICOLOR exfxcxdxbxegedabagacad

        # http://osxdaily.com/2012/02/21/add-color-to-the-terminal-in-mac-os-x/#more-27553
        case light
            set --global --export CLICOLOR ExFxBxDxCxegedabagacad
        case dark
            set --global --export CLICOLOR GxFxCxDxBxegedabagaced

        # http://www.norbauer.com/rails-consulting/notes/ls-colors-and-terminal-app.html#column
        case linux
            set --global --export CLICOLOR ExGxBxDxCxEgEdxbxgxcxd

        case '*'
            echo "Usage: lscolors light|dark|linux"
            return 1
    end

    ls
end
