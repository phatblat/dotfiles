# bef - Short alias for executing Fastlane through Bundler
export def bef [...args] {
    ^bundle exec fastlane ...$args
}
