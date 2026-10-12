# appcast_url - Calculate appcast checkpoint
export def appcast_url [url: string] {
    if ($url | is-empty) {
        error make { msg: "Usage: appcast_url url" }
    }
    ^brew cask _appcast_checkpoint --calculate $url
}
