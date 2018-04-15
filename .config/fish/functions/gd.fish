function gd --description='Launch gradle in debug mode.'
    gw -Dorg.gradle.debug=true --no-daemon $argv
end
