function plformat --description 'Format plist files'
    if test -z "$argv"
        set argv *.plist
    end
    plutil -convert xml1 $argv
end
