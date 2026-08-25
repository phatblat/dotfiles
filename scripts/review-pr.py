#!/usr/bin/env python3
"""Review a GetDitto pull request with OMP and preserve interactive follow-up."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass
from pathlib import Path

GETDITTO_OWNER = "getditto"
DEFAULT_THREAD_WINDOW = 5
USAGE = "Usage: review-pr <github-pr-url|repo#number|getditto/repo#number>"
DAILY_NOTES_DIR = Path.home() / "2ndBrain" / "daily-notes"


@dataclass(frozen=True)
class PullRequest:
    owner: str
    repo: str
    number: int

    @property
    def url(self) -> str:
        return f"https://github.com/{self.owner}/{self.repo}/pull/{self.number}"


@dataclass(frozen=True)
class ReviewThread:
    path: str
    lines: tuple[int, ...]


def main(argv: list[str]) -> int:
    try:
        pr_value = parse_arguments(argv)
        pr = parse_pr(pr_value)
        if pr.owner != GETDITTO_OWNER:
            print("Only getditto PRs are supported for now.", file=sys.stderr)
            return 2

        repo_dir = ensure_repo(pr)
        ref = f"refs/remotes/origin/pr/{pr.number}"
        base_ref, threads = fetch_pr_context(pr)
        run(
            [
                "git",
                "-C",
                str(repo_dir),
                "fetch",
                "origin",
                f"pull/{pr.number}/head:{ref}",
                f"{base_ref}:refs/remotes/origin/{base_ref}",
            ]
        )

        worktree_dir = create_worktree(repo_dir, pr, ref)
        preserve_worktree = True
        try:
            initial_head = worktree_head(worktree_dir)
            run_omp_review(worktree_dir, pr, base_ref, threads)
            preserve_worktree = worktree_changed(worktree_dir, initial_head)
        finally:
            if not preserve_worktree:
                preserve_worktree = not remove_worktree(
                    repo_dir, worktree_dir, force=False
                )
            if preserve_worktree:
                print(f"Worktree retained: {worktree_dir}", file=sys.stderr)
    except ReviewPrError as error:
        print(str(error), file=sys.stderr)
        return error.exit_code
    except subprocess.CalledProcessError as error:
        print(
            f"Command failed ({error.returncode}): {' '.join(error.cmd)}",
            file=sys.stderr,
        )
        return error.returncode
    except KeyboardInterrupt:
        print("Review interrupted.", file=sys.stderr)
        return 130

    return 0


class ReviewPrError(Exception):
    def __init__(self, message: str, exit_code: int = 1) -> None:
        super().__init__(message)
        self.exit_code = exit_code


def parse_arguments(argv: list[str]) -> str:
    arguments = argv[1:]
    if len(arguments) != 1:
        raise ReviewPrError(USAGE, 2)
    return arguments[0]


def parse_pr(value: str) -> PullRequest:
    url_match = re.fullmatch(
        r"https://github\.com/([^/]+)/([^/]+)/pull/([0-9]+)(?:[/?#].*)?",
        value,
    )
    if url_match:
        owner, repo, number = url_match.groups()
        return PullRequest(owner.lower(), repo, int(number))

    short_match = re.fullmatch(r"(?:(getditto)/)?([A-Za-z0-9_.-]+)#([0-9]+)", value)
    if short_match:
        owner, repo, number = short_match.groups()
        return PullRequest((owner or GETDITTO_OWNER).lower(), repo, int(number))

    owner_match = re.fullmatch(r"([^/]+)/([^#]+)#([0-9]+)", value)
    if owner_match:
        owner, repo, number = owner_match.groups()
        return PullRequest(owner.lower(), repo, int(number))

    raise ReviewPrError(
        "Expected https://github.com/getditto/<repo>/pull/<number>, "
        "getditto/<repo>#<number>, or <repo>#<number>.",
        2,
    )


def ensure_repo(pr: PullRequest) -> Path:
    root = Path(
        os.environ.get("REVIEW_PR_GETDITTO_ROOT", "~/dev/_GETDITTO")
    ).expanduser()
    repo_dir = root / pr.repo
    if repo_dir.exists():
        return repo_dir

    root.mkdir(parents=True, exist_ok=True)
    run(["gh", "repo", "clone", f"{pr.owner}/{pr.repo}", str(repo_dir)])
    return repo_dir


def create_worktree(repo_dir: Path, pr: PullRequest, ref: str) -> Path:
    root_env = os.environ.get("REVIEW_PR_WORKTREE_ROOT")
    root = Path(root_env).expanduser() if root_env else Path(tempfile.gettempdir())
    root.mkdir(parents=True, exist_ok=True)
    worktree_dir = Path(
        tempfile.mkdtemp(prefix=f"review-pr-{pr.repo}-{pr.number}-", dir=root)
    )
    worktree_dir.rmdir()
    run(
        [
            "git",
            "-C",
            str(repo_dir),
            "worktree",
            "add",
            "--detach",
            str(worktree_dir),
            ref,
        ]
    )
    return worktree_dir


def remove_worktree(repo_dir: Path, worktree_dir: Path, *, force: bool = True) -> bool:
    command = [
        "git",
        "-C",
        str(repo_dir),
        "worktree",
        "remove",
    ]
    if force:
        command.append("--force")
    command.append(str(worktree_dir))

    try:
        run(command)
        return True
    except subprocess.CalledProcessError:
        if not force:
            return False
        shutil.rmtree(worktree_dir, ignore_errors=True)
        return True


def fetch_pr_context(
    pr: PullRequest,
) -> tuple[str, list[ReviewThread]]:
    query = """
query($owner: String!, $name: String!, $number: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      baseRefName
      reviewThreads(first: 100, after: $after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          isResolved
          path
          line
          originalLine
          startLine
          originalStartLine
        }
      }
    }
  }
}
"""
    threads: list[ReviewThread] = []
    cursor: str | None = None
    base_ref: str | None = None

    while True:
        command = [
            "gh",
            "api",
            "graphql",
            "-f",
            f"query={query}",
            "-F",
            f"owner={pr.owner}",
            "-F",
            f"name={pr.repo}",
            "-F",
            f"number={pr.number}",
        ]
        if cursor:
            command.extend(["-F", f"after={cursor}"])

        result = run(command, capture=True)
        payload = json.loads(result.stdout)
        pull_request = payload["data"]["repository"]["pullRequest"]
        base_ref = base_ref or pull_request["baseRefName"]
        review_threads = pull_request["reviewThreads"]

        for node in review_threads["nodes"]:
            if node["isResolved"]:
                continue
            lines = tuple(
                sorted(
                    {
                        int(value)
                        for key in (
                            "line",
                            "originalLine",
                            "startLine",
                            "originalStartLine",
                        )
                        if (value := node.get(key)) is not None
                    }
                )
            )
            if lines:
                threads.append(ReviewThread(node["path"], lines))

        page_info = review_threads["pageInfo"]
        if not page_info["hasNextPage"]:
            if not isinstance(base_ref, str) or not base_ref:
                raise ReviewPrError("GitHub PR did not provide a base branch.")
            return base_ref, threads
        cursor = page_info["endCursor"]


def run_omp_review(
    worktree_dir: Path,
    pr: PullRequest,
    base_ref: str,
    threads: list[ReviewThread],
) -> None:
    thread_payload = [
        {"path": thread.path, "lines": list(thread.lines)} for thread in threads
    ]
    prompt = (
        f"/skill:review Review {pr.url} against origin/{base_ref}. "
        "review-only: do not edit files, commit, push, or post GitHub comments. "
        "Suppress findings overlapping the supplied unresolved threads within "
        f"±{thread_window()} lines. Existing unresolved threads: "
        f"{json.dumps(thread_payload, separators=(',', ':'))}. "
        "Present the report, then remain interactive for follow-up."
    )
    run(
        [
            "omp",
            "--profile",
            "casper",
            "--model",
            "casper/kimi-k3:max",
            "--cwd",
            str(worktree_dir),
            "--add-dir",
            str(DAILY_NOTES_DIR),
            "--no-prewalk",
            prompt,
        ]
    )


def worktree_head(worktree_dir: Path) -> str:
    result = run(["git", "-C", str(worktree_dir), "rev-parse", "HEAD"], capture=True)
    return result.stdout.strip()


def worktree_changed(worktree_dir: Path, initial_head: str) -> bool:
    status = run(
        [
            "git",
            "-C",
            str(worktree_dir),
            "status",
            "--porcelain",
            "--ignored=matching",
        ],
        capture=True,
    )
    return bool(status.stdout.strip()) or worktree_head(worktree_dir) != initial_head


def thread_window() -> int:
    value = os.environ.get("REVIEW_PR_THREAD_WINDOW")
    if value is None:
        return DEFAULT_THREAD_WINDOW
    try:
        return int(value)
    except ValueError as error:
        raise ReviewPrError("REVIEW_PR_THREAD_WINDOW must be an integer.") from error


def run(
    command: list[str],
    *,
    capture: bool = False,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        command,
        check=check,
        text=True,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.PIPE if capture else None,
    )


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
