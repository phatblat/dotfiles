# user - Displays information about the current user
export def user [] {
    let name = (try { ^git config user.name | str trim } catch { "" })
    let email = (try { ^git config user.email | str trim } catch { "" })
    let signingkey = (try { ^git config user.signingkey | str trim } catch { "" })
    print $"($env.USER): ($name) <($email)> [signingKey: ($signingkey)]"
}
