#!/usr/bin/env fish
# Review a given commit, default: HEAD.
#
# Custom pretty format
# - %h: abbreviated commit hash
# - %an: author name
# - %ae: author email
# - %ar: author date, relative
# - %cn: committer name
# - %ce: committer email
# - %s: subject
# - %b: body
# - %B: raw body (unwrapped subject and body)
# - %Cred: switch color to red
# - %Cgreen: switch color to green
# - %Cblue: switch color to blue
# - %Creset: reset color
# - %C(...): color specification, as described under Values in the "CONFIGURATION FILE" section of git-config(1); adding auto, at
#     the beginning will emit color only when colors are enabled for log output (by color.diff, color.ui, or --color, and respecting
#     the auto settings of the former if we are going to a terminal).  auto alone (i.e.  %C(auto)) will turn on auto coloring on the
#     next placeholders until the color is switched again.
#
function review --argument-names commit
    set -l format 'commit:    %Cgreen%H%Creset
date:      %Cgreen%ai%Creset
author:    %Cgreen%an%Creset <%Cgreen%ae%Creset>
committer: %Cgreen%cn%Creset <%Cgreen%ce%Creset>

    %s
'

    # --unified: Context lines
    # --no-prefix: Do not show any source or destination prefix. (e.g. "a/" "b/")
    # --no-indent-heuristic: Disable the default heuristic that shifts diff hunk boundaries to make patches easier to read.
    git \
        log \
        --max-count=1 \
        --pretty=format:$format \
        # --summary \
        --stat \
        #--dirstat=cumulative \
        --patch \
        # Mereg commits show full diff
        -m \
        # Context lines
        --unified=1 \
        --no-prefix \
        $commit
end

# review (original)
# commit c23f3eac92de10dc3477d94b0b4ef88117969f62
# Author: Ben Chatelain <ben@octop.ad>
# Date:   Tue May 9 21:53:22 2017 -0600
#
#     Rename new_project -> xcinit
#
# diff --git a/.config/fish/functions/new_project.fish b/.config/fish/functions/xcinit.fish
# similarity index 80%
# rename from .config/fish/functions/new_project.fish
# rename to .config/fish/functions/xcinit.fish
# index 6979a9c76..81680fc1e 100644
# --- a/.config/fish/functions/new_project.fish
# +++ b/.config/fish/functions/xcinit.fish
# @@ -1,4 +1,4 @@
#  # Runs Xcode new_project.rb ruby script
# -function new_project
# +function xcinit
