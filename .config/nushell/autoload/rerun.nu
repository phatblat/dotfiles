# Rerun failed jobs of a GitHub Actions run.
# Usage: rerun <run-id|run-url>
export def rerun [input: string] {
    let url_match = ($input | parse --regex 'github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/actions/runs/(?<id>\d+)' | first)

    if ($url_match | is-not-empty) {
        ^gh run rerun $url_match.id --failed --repo $"($url_match.owner)/($url_match.repo)"
    } else if ($input =~ '^\d+$') {
        ^gh run rerun $input --failed
    } else {
        error make { msg: $"rerun: cannot parse run id from: ($input)" }
    }
}
