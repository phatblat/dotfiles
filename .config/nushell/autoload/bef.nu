# bef - Short alias for executing Fastlane through Bundler
export def --wrapped bef [...args] {
    ^bundle exec fastlane ...$args
}
