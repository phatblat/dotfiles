function gwd --description='Debug gradle'
    gw -Dorg.gradle.debug=true --no-daemon --console=plain $argv
end
