# Prints the path to the system gem dir
function gemdir
    ruby -rubygems -e 'puts Gem.dir'
end

