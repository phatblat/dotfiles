# Dependencies:
#   functions: none
#   builtins:  none
#   externals: claude, is-dotfiles-checkout.sh

# cc — Claude Code with the dotfiles-scoped settings layer.
#
# Inside the dotfiles checkout the launcher supplies `--setting-sources user`
# so project and local settings never duplicate the deployed shared config;
# other directories keep Claude's default source discovery. The
# dangerously-skip-permissions default is unchanged.
export def --wrapped cc [...args] {
    let explicit_sources = ($args | any {|argument|
        $argument == "--setting-sources" or ($argument | str starts-with "--setting-sources=")
    })
    let dotfiles = (do { ^($env.HOME | path join "scripts/is-dotfiles-checkout.sh") } | complete).exit_code == 0
    if $dotfiles and not $explicit_sources {
        ^claude --dangerously-skip-permissions --setting-sources user ...$args
    } else {
        ^claude --dangerously-skip-permissions ...$args
    }
}
