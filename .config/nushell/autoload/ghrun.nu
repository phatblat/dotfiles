# ghrun - Watch a GitHub Actions run; `ghrun retry` reruns a job until success or N times
# Dependencies:
#   - gh (GitHub CLI): run watch/rerun, repo and actions API access

# Shared helpers for ghrun. Not exported: internal.
def ghrun-usage [] {
    "Usage:
  ghrun [run-id] [--repo OWNER/REPO] [--logs] [--interval SECONDS]
  ghrun retry [run-id] --job NAME [--repo OWNER/REPO] [--max N] [--interval SECONDS] [--until-success]"
}

# Resolve the latest run id in the target repo.
def ghrun-resolve-run-id [repo?: string] {
    let id = (^gh run list --limit 1 --json databaseId ...(if ($repo | is-empty) { [] } else { ["-R" $repo] }) --jq '.[0].databaseId' | str trim)
    if ($id | is-empty) {
        error make {msg: "ghrun: no runs found"}
    }
    $id
}

# OWNER/REPO for the gh api path.
def ghrun-owner-repo [repo?: string] {
    if ($repo | is-empty) {
        ^gh repo view --json nameWithOwner --jq '.nameWithOwner' | str trim
    } else {
        $repo
    }
}

# Watch a GitHub Actions run: poll, print one line per change, exit with conclusion-based code.
export def ghrun [
    run_id?: string  # run id to watch (default: latest run in the target repo)
    --repo: string  # OWNER/REPO (default: repo resolved from the cwd git remote)
    --logs  # print failed-job logs on non-success completion
    --interval: int = 20  # seconds between polls
] {
    let repo_args = if ($repo | is-empty) { [] } else { ["-R" $repo] }
    let id = if ($run_id | is-empty) { ghrun-resolve-run-id $repo } else { $run_id }
    mut last_summary = ""
    loop {
        let line = do -i { ^gh run view $id ...$repo_args --json attempt,status,conclusion --jq '[.attempt, .status, (.conclusion // "-")] | @tsv' } | default "" | str trim
        if not ($line | is-empty) {
            let parts = ($line | split row "\t")
            let summary = $"attempt=($parts | get 0) status=($parts | get 1) conclusion=($parts | get 2)"
            if $summary != $last_summary {
                print $summary
                $last_summary = $summary
            }
            if ($parts | get 1) == "completed" {
                let conclusion = $parts | get 2
                print $"run ($id) completed: ($conclusion)"
                if $conclusion == "success" {
                    return
                }
                if $logs {
                    do -i { ^gh run view $id ...$repo_args --log-failed }
                }
                error make {msg: $"ghrun: run ($id) concluded ($conclusion)"}
            }
        }
        sleep ($interval * 1sec)
    }
}

# Retry a single job in a run: rerun until success (--until-success) or N times.
export def "ghrun retry" [
    run_id?: string  # run id (default: latest run in the target repo)
    --repo: string  # OWNER/REPO (default: repo resolved from the cwd git remote)
    --job: string  # job name to rerun (required)
    --max: int = 10  # number of attempts
    --interval: int = 20  # seconds between polls (the new-attempt check polls at most every 5s)
    --until-success  # stop as soon as the job conclusion is success
] {
    if ($job | is-empty) {
        error make {msg: $"ghrun retry: --job is required\n(ghrun-usage)"}
    }
    let repo_args = if ($repo | is-empty) { [] } else { ["-R" $repo] }
    let id = if ($run_id | is-empty) { ghrun-resolve-run-id $repo } else { $run_id }
    let owner_repo = ghrun-owner-repo $repo

    def latest-attempt [] {
        ^gh run view $id ...$repo_args --json attempt --jq '.attempt' | str trim | into int
    }
    def job-for-attempt [attempt: int] {
        let jobs = do -i { with-env {GHRUN_JOB: $job} { ^gh api $"repos/($owner_repo)/actions/runs/($id)/attempts/($attempt)/jobs?per_page=100" --jq '.jobs[] | select(.name == env.GHRUN_JOB) | [.id, .status, (.conclusion // "")] | @tsv' } }
        if (($jobs | default "" | str trim) | is-empty) { "" } else {
            $jobs | lines | last
        }
    }
    def wait-for-attempt-job-completion [attempt: int] {
        mut last_line = ""
        loop {
            let line = job-for-attempt $attempt
            if not ($line | is-empty) {
            let parts = ($line | split row "\t")
            let conclusion = if (($parts | get 2) | is-empty) { "null" } else { $parts | get 2 }
            let summary = $"attempt=($attempt) job=($parts | get 0) status=($parts | get 1) conclusion=($conclusion)"
                if $summary != $last_line {
                    print $summary
                    $last_line = $summary
                }
                if ($parts | get 1) == "completed" {
                    return
                }
            }
            sleep ($interval * 1sec)
        }
    }

    mut successes = 0
    mut failures = 0
    for k in (seq 1 $max) {
        let before_attempt = latest-attempt
        mut before_line = job-for-attempt $before_attempt

        # If the latest attempt's job is still running, wait for it first.
        if (($before_line | is-empty) or (($before_line | split row "\t" | get 1) != "completed")) {
            print $"[($k)/($max)] latest attempt=($before_attempt) is still running; waiting before next rerun"
            wait-for-attempt-job-completion $before_attempt
            $before_line = job-for-attempt (latest-attempt)
        }
        let before_parts = $before_line | split row "\t"
        let before_job_id = $before_parts | get 0

        print $"[($k)/($max)] rerun run=($id) attempt=($before_attempt) job=($before_job_id)"
        ^gh run rerun $id ...$repo_args --job $before_job_id

        # Wait for the new attempt to appear.
        mut after_attempt = $before_attempt
        loop {
            $after_attempt = latest-attempt
            if $after_attempt > $before_attempt {
                break
            }
            sleep (([$interval 5] | math min) * 1sec)
        }

        # Wait for the new attempt's job to complete.
        wait-for-attempt-job-completion $after_attempt

        let after_line = job-for-attempt $after_attempt
        let rerun_conclusion = if ($after_line | is-empty) { "" } else { $after_line | split row "\t" | get 2 }
        if $rerun_conclusion == "success" {
            $successes = $successes + 1
            if $until_success {
                print $"($job) succeeded after ($k) attempts"
                return
            }
        } else {
            $failures = $failures + 1
        }
    }

    if $until_success {
        error make {msg: $"ghrun retry: ($job) failed after ($max) attempts"}
    }
    print $"Completed ($max) attempts: ($successes) success / ($failures) failure"
}
