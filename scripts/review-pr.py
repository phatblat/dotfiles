#!/usr/bin/env python3
"""Review a GetDitto pull request with Codex and filter existing threads."""

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


@dataclass(frozen=True)
class Finding:
    block: str
    path: str | None
    start_line: int | None
    end_line: int | None


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(
            "Usage: review-pr <github-pr-url|repo#number|getditto/repo#number>",
            file=sys.stderr,
        )
        return 2

    try:
        pr = parse_pr(argv[1])
        if pr.owner != GETDITTO_OWNER:
            print("Only getditto PRs are supported for now.", file=sys.stderr)
            return 2

        repo_dir = ensure_repo(pr)
        ref = f"refs/remotes/origin/pr/{pr.number}"
        run(
            [
                "git",
                "-C",
                str(repo_dir),
                "fetch",
                "origin",
                f"pull/{pr.number}/head:{ref}",
            ]
        )

        worktree_dir = create_worktree(repo_dir, pr, ref)
        try:
            threads = fetch_open_review_threads(pr)
            review_output = run_codex_review(worktree_dir, pr)
            print(filter_findings(review_output, threads, thread_window()))
        finally:
            remove_worktree(repo_dir, worktree_dir)
    except ReviewPrError as error:
        print(str(error), file=sys.stderr)
        return error.exit_code
    except subprocess.CalledProcessError as error:
        print(
            f"Command failed ({error.returncode}): {' '.join(error.cmd)}",
            file=sys.stderr,
        )
        return error.returncode

    return 0


class ReviewPrError(Exception):
    def __init__(self, message: str, exit_code: int = 1) -> None:
        super().__init__(message)
        self.exit_code = exit_code


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


def remove_worktree(repo_dir: Path, worktree_dir: Path) -> None:
    try:
        run(
            [
                "git",
                "-C",
                str(repo_dir),
                "worktree",
                "remove",
                "--force",
                str(worktree_dir),
            ]
        )
    except subprocess.CalledProcessError:
        shutil.rmtree(worktree_dir, ignore_errors=True)


def fetch_open_review_threads(pr: PullRequest) -> list[ReviewThread]:
    query = """
query($owner: String!, $name: String!, $number: Int!, $after: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
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
        review_threads = payload["data"]["repository"]["pullRequest"]["reviewThreads"]

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
            return threads
        cursor = page_info["endCursor"]


def run_codex_review(worktree_dir: Path, pr: PullRequest) -> str:
    with tempfile.NamedTemporaryFile("r", delete=False) as output_file:
        output_path = Path(output_file.name)

    prompt = (
        f"$pr-review Review {pr.url}. "
        "Return only the final PR Review markdown in the documented toolkit format."
    )
    command = [
        "codex",
        "exec",
        "--profile",
        "main",
        "--cd",
        str(worktree_dir),
        "--output-last-message",
        str(output_path),
        prompt,
    ]
    result = run(command, capture=True, check=False)
    if result.returncode != 0:
        if result.stdout:
            print(result.stdout, file=sys.stderr)
        if result.stderr:
            print(result.stderr, file=sys.stderr)
        raise ReviewPrError(
            f"Codex review failed with exit code {result.returncode}", result.returncode
        )

    if output_path.exists():
        output = output_path.read_text()
        output_path.unlink()
        if output.strip():
            return output

    return result.stdout


def filter_findings(output: str, threads: list[ReviewThread], window: int) -> str:
    finding_matches = list(re.finditer(r"(?m)^### P[0-3]: .*$", output))
    if not finding_matches or not threads:
        return output.rstrip()

    prefix = output[: finding_matches[0].start()].rstrip()
    kept_blocks: list[str] = []
    suppressed = 0

    for index, match in enumerate(finding_matches):
        end = (
            finding_matches[index + 1].start()
            if index + 1 < len(finding_matches)
            else len(output)
        )
        block = output[match.start() : end].strip()
        finding = parse_finding(block)
        if overlaps_thread(finding, threads, window):
            suppressed += 1
        else:
            kept_blocks.append(block)

    if kept_blocks:
        rendered = "\n\n".join([prefix, *kept_blocks]).strip()
    else:
        rendered = "\n\n".join(
            [
                prefix,
                "No new actionable findings after filtering existing open review threads.",
            ]
        ).strip()

    if suppressed:
        plural = "s" if suppressed != 1 else ""
        rendered = "\n\n".join(
            [
                rendered,
                "## Existing Threads",
                f"Suppressed {suppressed} finding{plural} near existing unresolved review thread(s).",
            ]
        )

    return rendered


def parse_finding(block: str) -> Finding:
    file_match = re.search(r"(?im)^-\s*File:\s*`?([^`\n]+)`?\s*$", block)
    line_match = re.search(
        r"(?im)^-\s*Lines?:\s*([0-9]+)(?:\s*[-,]\s*([0-9]+))?", block
    )
    start_line = int(line_match.group(1)) if line_match else None
    end_line = (
        int(line_match.group(2)) if line_match and line_match.group(2) else start_line
    )
    return Finding(
        block=block,
        path=file_match.group(1).strip() if file_match else None,
        start_line=start_line,
        end_line=end_line,
    )


def overlaps_thread(finding: Finding, threads: list[ReviewThread], window: int) -> bool:
    if finding.path is None or finding.start_line is None or finding.end_line is None:
        return False

    for thread in threads:
        if thread.path != finding.path:
            continue
        for line in thread.lines:
            if finding.start_line - window <= line <= finding.end_line + window:
                return True

    return False


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
