#!/usr/bin/env python3
"""Shared safety policy for agent harness adapters.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

from dataclasses import dataclass
import os
import re
import subprocess
from pathlib import Path


@dataclass(frozen=True)
class GuardDecision:
    decision: str
    reason: str = ""

    @property
    def allowed(self) -> bool:
        return self.decision in {"allow", "warn"}


PRIVILEGE_ESCALATION = re.compile(
    r"(^|;|&&|\|\||\$\(|`)\s*(sudo|su|doas|pkexec)\b",
    re.IGNORECASE,
)

DANGEROUS_COMMANDS = (
    re.compile(
        r"\brm\s+-(?=[A-Za-z-]*r)(?=[A-Za-z-]*f)[A-Za-z-]*\s+(/|~|\*|\.\.)",
        re.IGNORECASE,
    ),
    re.compile(r">\s*/dev/sd[a-z]?", re.IGNORECASE),
    re.compile(r"\bmkfs(\.|\s)", re.IGNORECASE),
    re.compile(r"\bdd\s+if=.*\s+of=/dev/", re.IGNORECASE),
    re.compile(r"\bchmod\s+(-R\s+)?777\b", re.IGNORECASE),
    re.compile(r"\bchmod\s+\+s\b", re.IGNORECASE),
    re.compile(r":\(\)\{.*:\|:&\};", re.IGNORECASE),
    re.compile(r"\b(curl|wget)\b[^|]*\|\s*(ba)?sh\b", re.IGNORECASE),
    re.compile(r"\b(truncate|shred)\b", re.IGNORECASE),
)

OBFUSCATED_EXECUTION = (
    re.compile(r"\beval\s+.*\$", re.IGNORECASE),
    re.compile(r"\bbase64\s+-d.*\|\s*(ba)?sh\b", re.IGNORECASE),
    re.compile(r"\bawk\s+.*system\s*\(", re.IGNORECASE),
    re.compile(r"\bbash\s+<\(", re.IGNORECASE),
)

PROTECTED_PATHS = re.compile(
    r"("
    r"\.env($|\.)|"
    r"\.ssh/|"
    r"id_(rsa|ed25519|ecdsa)|"
    r"\.pem$|\.key$|\.p12$|\.pfx$|\.jks$|"
    r"\.aws/credentials|"
    r"\.docker/config\.json|"
    r"kubeconfig|"
    r"\.npmrc$|\.pypirc$|\.netrc$|\.pgpass$|\.htpasswd$|\.git-credentials|"
    r"\.claude/\.credentials\.json|"
    r"\.codex/auth\.json|"
    r"\.pi/agent/auth\.json"
    r")",
    re.IGNORECASE,
)

SECRET_CONTENT = re.compile(
    r"("
    r"AKIA[0-9A-Z]{16}|"
    r"sk-[A-Za-z0-9_-]{20,}|"
    r"ghp_[A-Za-z0-9]{36}|"
    r"gho_[A-Za-z0-9]{36}|"
    r"glpat-[A-Za-z0-9_-]{20,}|"
    r"xox[bpoas]-[A-Za-z0-9-]+|"
    r"-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----|"
    r"password\s*[:=]\s*[\"'][^\"']{8,}[\"']"
    r")",
    re.IGNORECASE,
)


def evaluate(
    tool: str,
    *,
    command: str = "",
    path: str = "",
    content: str = "",
    cwd: str | None = None,
) -> GuardDecision:
    """Evaluate a normalized tool call against the shared safety policy."""

    normalized_tool = tool.lower().strip()
    if normalized_tool in {"bash", "shell", "exec"}:
        return evaluate_command(command, cwd=cwd)
    if normalized_tool in {"write", "edit", "file_write", "file_edit"}:
        return evaluate_write(path=path, content=content)
    return GuardDecision("allow")


def evaluate_command(command: str, *, cwd: str | None = None) -> GuardDecision:
    if not command.strip():
        return GuardDecision("allow")

    if PRIVILEGE_ESCALATION.search(command):
        return GuardDecision("deny", "Privilege escalation blocked")

    if any(pattern.search(command) for pattern in DANGEROUS_COMMANDS):
        return GuardDecision("deny", "Dangerous command pattern detected")

    if any(pattern.search(command) for pattern in OBFUSCATED_EXECUTION):
        return GuardDecision("deny", "Obfuscated execution pattern detected")

    warning = main_branch_commit_warning(command, cwd=cwd)
    if warning:
        return GuardDecision("warn", warning)

    return GuardDecision("allow")


def evaluate_write(*, path: str = "", content: str = "") -> GuardDecision:
    if path:
        display_path = normalize_path_for_matching(path)
        if PROTECTED_PATHS.search(display_path):
            return GuardDecision("deny", f"protected file blocked: {path}")

    if content and SECRET_CONTENT.search(content):
        return GuardDecision("deny", "secret-like content detected")

    return GuardDecision("allow")


def normalize_path_for_matching(path: str) -> str:
    expanded = os.path.expanduser(path)
    try:
        return str(Path(expanded).resolve())
    except OSError:
        return expanded


def main_branch_commit_warning(command: str, *, cwd: str | None = None) -> str:
    if not re.search(r"^\s*(git\s+commit|git\s+-C\s+\S+\s+commit)\b", command):
        return ""

    workdir = cwd or os.getcwd()
    branch = run_git(["branch", "--show-current"], cwd=workdir)
    if branch not in {"main", "master"}:
        return ""

    repo_root = run_git(["rev-parse", "--show-toplevel"], cwd=workdir)
    commit_count = run_git(["rev-list", "--count", "HEAD"], cwd=workdir)
    home = str(Path.home())
    try:
        commits = int(commit_count)
    except ValueError:
        commits = 0

    if repo_root != home and commits >= 100:
        return (
            f"WARNING: You are on the protected '{branch}' branch. "
            "Create a feature branch before committing."
        )
    return ""


def run_git(args: list[str], *, cwd: str) -> str:
    try:
        result = subprocess.run(
            ["git", *args],
            cwd=cwd,
            check=False,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.TimeoutExpired):
        return ""
    if result.returncode != 0:
        return ""
    return result.stdout.strip()
