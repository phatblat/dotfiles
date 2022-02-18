function as \
    --description='Open project in Android Studio' \
    --argument-names path

    set -l arctic_fox   ch-0/203.7935034 # patch 4 (only on tredecim)
    # ch-1 on tredecim
    set -l bumblebee    ch-1/211.7628.21.2111.8139111 # patch 1
    # ga - 211.7628.21.2111.8092744
    set -l chipmunk     ch-1/212.5712.43.2112.8125332 # beta 2
    # beta 1 - 212.5457.46.2112.8094850
    set -l dolphin      ch-3/213.5744.223.2113.8103819 # canary 1

    set -l app ~/Library/Application\ Support/JetBrains/Toolbox/apps/AndroidStudio/$bumblebee/Android\ Studio.app/Contents/MacOS/studio

    if test -z $path
        set path .
    end

    open -a $app $path
end
