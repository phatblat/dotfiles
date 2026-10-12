# gemdir - Prints the path to the system gem dir
export def gemdir [] {
    ^ruby -r rubygems -e 'puts Gem.dir'
}
