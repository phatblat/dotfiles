# github-pat-refresh - Extend fine-grained GitHub PAT expiration by N days (default: 30)
# Requires GITHUB_PAT_ID in environment (set in ~/.envrc, not tracked in source control)
export def github-pat-refresh [days: int = 30] {
    let pat_id = ($env.GITHUB_PAT_ID? | default "")
    if ($pat_id | is-empty) {
        error make { msg: "Error: GITHUB_PAT_ID not set — add it to ~/.envrc" }
    }

    let expires_at = (^date -v $"+($days)d" +%Y-%m-%d | str trim)

    print $"Extending PAT ($pat_id) expiry by ($days) days → ($expires_at)"

    (
        ^gh api
            --method PATCH
            $"/user/personal-access-tokens/($pat_id)"
            -f $"expires_at=($expires_at)"
            --jq '"  \(.name): expires \(.expires_at)"'
    )
}
