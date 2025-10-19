#!/usr/bin/env fish
# 
function gem-userdir
    ruby -rubygems -e "puts Gem.user_dir" $argv
end
