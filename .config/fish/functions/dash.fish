#!/usr/bin/env fish
# Dash shell integration.
# You can initiate a Dash search from within Terminal by executing "open dash://{query}".
#
# This also works with docset keywords (defined in Preferences > Docsets) or search profile keyword triggers (defined by clicking on the loupe icon of the main search field).
#
# Keyword example: "open dash://php:{query}".
function dash --argument-names query
    if test -z "$query"
        echo "Usage: dash query   (prefix query with 'docset_name:' to limit)"
        return 1
    end

    open dash://$query
end
