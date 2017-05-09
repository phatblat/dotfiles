# Launch IntelliJ IDEA.
function idea --argument-names path
    # check for where the latest version of IDEA is installed
    set -l IDEA (ls -1d /Applications/IntelliJ\ * | tail -n1)

    # were we given a directory?
    if test -d $path
        # echo "checking for things in the working dir given"
        set dir (ls -1d $path | head -n1)
    end

    # were we given a file?
    if test -f $path
        # echo "opening '$path'"
        open -a $IDEA $path
    else
        if test -n $dir
            # let's check for stuff in our working directory.
            pushd $dir > /dev/null
        end

        # does our working dir have an .idea directory?
        if test -d .idea
            # echo "opening via the .idea dir"
            open -a $IDEA .

        # is there an IDEA project file?
        else if test -f *.ipr
            # echo "opening via the project file"
            open -a $IDEA (ls -1d *.ipr | head -n1)

        # Is there a pom.xml?
        else if test -f pom.xml
            # echo "importing from pom"
            open -a "$IDEA" "pom.xml"

        # can't do anything smart; just open IDEA
        else
            open $IDEA
        end

      if test -n $dir
        popd > /dev/null
        end
    end
end
