#!/usr/bin/env python3
"""Shared safety policy for agent harness adapters.

Copyright: Ben Chatelain. Apache 2.0.
"""

from __future__ import annotations

import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class GuardDecision:
    decision: str
    reason: str = ""

    @property
    def allowed(self) -> bool:
        return self.decision in {"allow", "warn"}


PRIVILEGE_ESCALATION = re.compile(
    r"(^|;|&&|\|\||\||\n|\r|\$\(|`)\s*(sudo|su|doas|pkexec)\b",
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
    r"\.omp/agent/agent\.db|"
    r"\.omp/agent/secrets\.yml|"
    r"\.pi/agent/auth\.json|"
    r"\.gemini/google_accounts\.json|"
    r"\.gemini/oauth_creds\.json|"
    r"\.gemini/antigravity-cli/installation_id|"
    r"\.gemini/antigravity-cli/conversations/|"
    r"\.cursor/ai-tracking/|"
    r"\.grok/auth\.json|\.grok/mcp_credentials\.json"
    r")",
    re.IGNORECASE,
)

# The control plane: the files that decide what this policy permits. An agent
# able to edit these can switch off every other rule here — including the
# protected-path list above — and the first time the guard blocks something it
# will have a plausible reason to try. Keep them human-only: edit by hand.
#
# Deliberately narrow. Broad entries like `config\.yml$` or `\.gitignore$` would
# block routine agent work across every repository, and the cost of that lands
# on every session, not just on a self-improvement loop.
#
# Fragments end with a non-path lookahead rather than `$` so the same pattern
# matches both a bare path and a path embedded in a shell command.
_CONTROL_PLANE_FRAGMENTS = (
    r"/\.agents/harness/hooks/",
    r"/\.agents/harness/self-improve-policy\.json(?![\w.-])",
    # The generated-path manifest is the whole basis of the generated-file deny
    # rule, and load_generated_manifest() fails open. Blanking this file would
    # silently unlock all 274 generated artifacts, so it is control plane too.
    r"/\.agents/harness/generated-paths\.json(?![\w.-])",
    r"/scripts/agent-harnesses\.py(?![\w.-])",
    r"/scripts/agent_plugins\.py(?![\w.-])",
    r"/harness-guard\.(?:ts|py)(?![\w.-])",
    r"/(?:write|bash)-guard\.sh(?![\w.-])",
)

CONTROL_PLANE_PATHS = re.compile(
    "(?:" + "|".join(_CONTROL_PLANE_FRAGMENTS) + ")",
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

    # Path rules have to apply here too, not just in evaluate_write: `echo x >>
    # safety.py` reaches the same file as a write tool, and until this existed
    # one line of shell switched off every path rule in this module.
    target = writes_to(command, PROTECTED_PATHS)
    if target:
        return GuardDecision("deny", f"protected file blocked: {target}")

    target = writes_to(command, CONTROL_PLANE_PATHS)
    if target:
        return GuardDecision(
            "deny",
            f"control-plane file is human-only: {target}. It decides what the "
            "guard permits, so edit it directly rather than through an agent.",
        )

    warning = main_branch_commit_warning(command, cwd=cwd)
    if warning:
        return GuardDecision("warn", warning)

    return GuardDecision("allow")


def evaluate_write(*, path: str = "", content: str = "") -> GuardDecision:
    if path:
        display_path = normalize_path_for_matching(path)
        if PROTECTED_PATHS.search(display_path):
            return GuardDecision("deny", f"protected file blocked: {path}")
        if CONTROL_PLANE_PATHS.search(display_path):
            return GuardDecision(
                "deny",
                f"control-plane file is human-only: {path}. It decides what the "
                "guard permits, so edit it directly rather than through an agent.",
            )

    if content and SECRET_CONTENT.search(content):
        return GuardDecision("deny", "secret-like content detected")

    return GuardDecision("allow")


# Shell constructs that name a file the command writes to. Each captures the
# span in which a target may appear; path-like tokens are pulled out of it and
# matched against the ordinary path rules.
_REDIRECT_TARGET = re.compile(r">>?\s*(?P<span>[^\s;|&<>]+)")
_MUTATING_ARGV = re.compile(
    r"\b(?:rm|mv|cp|tee|ln|install|truncate|shred|unlink|touch|chmod|chown)\b"
    r"(?P<span>[^;|&]*)",
    re.IGNORECASE,
)
_SED_INPLACE = re.compile(r"\bsed\b(?P<span>[^;|&]*?-i(?:\S*)?[^;|&]*)", re.IGNORECASE)
_DD_TARGET = re.compile(r"\bdd\b[^;|&]*?\bof=(?P<span>[^\s;|&]+)", re.IGNORECASE)

_PATH_TOKEN = re.compile(r"[^\s;|&<>'\"]*[/~][^\s;|&<>'\"]*")


def candidate_write_targets(command: str) -> list[str]:
    """Path-like tokens that a shell command appears to write to.

    Regex, not a shell parser. It recognizes redirection, the common mutating
    commands, `sed -i`, and `dd of=`. A here-doc, a `python3 -c` one-liner, or
    an alias will get past it, and that is understood: the job here is to stop
    the guard being switched off by an ordinary one-line edit, not to sandbox
    the shell. The merge gate is what actually holds.
    """

    targets: list[str] = []
    for pattern in (_REDIRECT_TARGET, _MUTATING_ARGV, _SED_INPLACE, _DD_TARGET):
        for match in pattern.finditer(command):
            targets.extend(_PATH_TOKEN.findall(match.group("span")))
    return [token.strip("'\"") for token in targets if token.strip("'\"")]


def writes_to(command: str, pattern: re.Pattern[str]) -> str:
    """The first write target in `command` matching `pattern`, else ""."""

    for target in candidate_write_targets(command):
        if pattern.search(normalize_path_for_matching(target)):
            return target
    return ""


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
