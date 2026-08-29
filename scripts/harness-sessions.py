#!/usr/bin/env python3
"""Deterministic, privacy-bounded scanner over local agent-harness session
transcripts.

Reports two things, never raw transcript bytes: measured **feature usage**
(which skills/tools/MCP servers actually ran) and **friction** (tool errors,
hook cost, aborted turns, cache misses, MCP failures) across the eight
supported harnesses in `harness_paths.HARNESSES`.

Record schemas and the research behind them live in
`docs/agent-session-transcripts.md`. The privacy and evidence policy this
implements lives in
`~/.agents/skills/optimize-harness/references/session-usage-evidence.md`.

Usage:
    harness-sessions.py [HARNESS ...] [--since DAYS] [--json]
                         [--max-files N] [--repo PATH]
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import statistics
import subprocess
import sys
import tempfile
import time
from collections.abc import Iterator
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))
from harness_paths import CLI_BINARIES, HARNESSES, SESSION_STORES, SessionStore

HOME = Path(os.environ.get("HOME", str(Path.home()))).resolve()
MAX_FIELD_LEN = 64


class PrivacyError(ValueError):
    """Raised when a value would violate the emit() privacy contract."""


@dataclass(frozen=True)
class Obs:
    """One normalized observation. This is the only shape that ever leaves
    a transcript file -- no adapter may carry any other field out."""

    harness: str
    session: str
    ts: str
    actor: str
    kind: str
    name: str
    ok: bool | None
    ms: int | None
    detail: str


def emit(
    sink: list[Obs],
    *,
    harness: str,
    session: str,
    kind: str,
    ts: str = "",
    actor: str = "system",
    name: str = "",
    ok: bool | None = None,
    ms: int | None = None,
    detail: str = "",
) -> Obs:
    """The single chokepoint every adapter must call to record an
    observation. Structurally rejects anything that could carry transcript
    content: `name`/`detail` are bounded to 64 chars with no newline, and
    nothing else on Obs accepts free text."""
    for label, value in (("name", name), ("detail", detail)):
        if not isinstance(value, str):
            raise PrivacyError(f"{label} must be str, got {type(value).__name__}")
        has_newline = "\n" in value
        if len(value) > MAX_FIELD_LEN or has_newline:
            raise PrivacyError(
                f"{label} violates privacy contract: len={len(value)}, "
                f"newline={has_newline}"
            )
    obs = Obs(
        harness=harness,
        session=session,
        ts=ts,
        actor=actor,
        kind=kind,
        name=name,
        ok=ok,
        ms=ms,
        detail=detail,
    )
    sink.append(obs)
    return obs


def session_id(path: Path) -> str:
    """Opaque, non-reversible session identifier. Never the path or cwd."""
    return hashlib.sha256(str(path.resolve()).encode()).hexdigest()[:12]


def resolve_root(store: SessionStore) -> tuple[Path, str]:
    """First set env var wins, else HOME/default. Always returns which
    source resolved, so an unresolved historical root is a named coverage
    gap rather than a silent miss."""
    for var in store.env:
        val = os.environ.get(var)
        if val:
            return Path(val).expanduser(), f"env:{var}"
    return HOME / store.default, "default"

def _pi_session_dir() -> Path | None:
    """Return the effective Pi session directory from settings.json, if present."""
    settings_path = HOME / ".pi" / "agent" / "settings.json"
    if not settings_path.exists():
        return None
    try:
        with settings_path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None
    session_dir = data.get("sessionDir")
    if isinstance(session_dir, str) and session_dir:
        return Path(session_dir).expanduser()
    return None


def resolve_session_root(slug: str, store: SessionStore) -> tuple[Path, str]:
    """Profile-aware session root resolution for OMP/Pi; generic fallback otherwise.

    Returns the directory one level above the actual sessions directory so that
    the existing SESSION_STORES patterns (e.g. ``sessions/**/*.jsonl``) continue
    to work unchanged.
    """
    if slug == "omp":
        profile = os.environ.get("OMP_PROFILE") or os.environ.get("PI_PROFILE")
        if profile:
            return (
                HOME / ".omp" / "profiles" / profile / "agent",
                f"env:OMP_PROFILE={profile}",
            )
        agent_dir = os.environ.get("PI_CODING_AGENT_DIR")
        if agent_dir:
            return Path(agent_dir).expanduser(), "env:PI_CODING_AGENT_DIR"
        return HOME / store.default, "default"

    if slug == "pi":
        settings_dir = _pi_session_dir()
        if settings_dir is not None:
            return settings_dir.parent, "settings:sessionDir"
        session_dir = os.environ.get("PI_CODING_AGENT_SESSION_DIR")
        if session_dir:
            return Path(session_dir).expanduser().parent, "env:PI_CODING_AGENT_SESSION_DIR"
        agent_dir = os.environ.get("PI_CODING_AGENT_DIR")
        if agent_dir:
            return Path(agent_dir).expanduser(), "env:PI_CODING_AGENT_DIR"
        return HOME / store.default, "default"

    return resolve_root(store)


def iter_files(root: Path, pattern: str, max_files: int) -> list[Path]:
    """Newest-first files under root, capped at max_files."""
    if pattern:
        try:
            files = [p for p in root.glob(pattern) if p.is_file()]
        except OSError:
            return []
    elif root.is_file():
        files = [root]
    else:
        files = []
    files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return files[:max_files]


def parse_ts(value: Any) -> float | None:
    """Best-effort epoch-seconds parse of an ISO 8601 string or a numeric
    epoch (auto-detecting seconds vs milliseconds)."""
    if value is None:
        return None
    if isinstance(value, (int, float)):
        return value / 1000.0 if value > 1e12 else float(value)
    if isinstance(value, str) and value:
        try:
            return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()
        except ValueError:
            return None
    return None


def iso(epoch: float | None) -> str:
    if epoch is None:
        return ""
    return datetime.fromtimestamp(epoch, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class CallJoiner:
    """Joins a tool call with its eventual result by call id, so a call plus
    its result is emitted as one attempt with at most one success/error, per
    the aggregation contract. Unmatched calls flush as unresolved (ok=None);
    unmatched results are the caller's problem to emit standalone."""

    def __init__(self) -> None:
        self._pending: dict[str, dict[str, Any]] = {}

    def open(self, call_id: str, **fields: Any) -> None:
        if call_id:
            self._pending[call_id] = fields

    def close(self, call_id: str) -> dict[str, Any] | None:
        return self._pending.pop(call_id, None)

    def flush(self) -> list[dict[str, Any]]:
        remaining = list(self._pending.values())
        self._pending.clear()
        return remaining


@dataclass
class Coverage:
    harness: str
    root: str
    resolved_from: str
    cli_version: str | None
    files_seen: int = 0
    files_parsed: int = 0
    files_skipped_since: int = 0
    files_skipped_max: int = 0
    files_malformed: int = 0
    earliest: str = ""
    latest: str = ""
    gaps: list[str] = field(default_factory=list)

    def note_ts(self, ts: str) -> None:
        if not ts:
            return
        if not self.earliest or ts < self.earliest:
            self.earliest = ts
        if not self.latest or ts > self.latest:
            self.latest = ts

    def as_dict(self) -> dict[str, Any]:
        return {
            "harness": self.harness,
            "root": self.root,
            "resolved_from": self.resolved_from,
            "cli_version": self.cli_version,
            "files_seen": self.files_seen,
            "files_parsed": self.files_parsed,
            "files_skipped_since": self.files_skipped_since,
            "files_skipped_max": self.files_skipped_max,
            "files_malformed": self.files_malformed,
            "earliest": self.earliest,
            "latest": self.latest,
            "gaps": self.gaps,
        }


def cli_version(binary: str) -> str | None:
    try:
        result = subprocess.run(
            [binary, "--version"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    text = (result.stdout or result.stderr or "").strip().splitlines()
    return text[0][:MAX_FIELD_LEN] if text else None


def read_jsonl_lines(path: Path) -> Iterator[tuple[dict, bool]]:
    """Yield (record, ok) per non-blank line. ok=False marks a malformed
    line; the caller counts it and moves on -- one bad line never aborts a
    file."""
    try:
        with path.open("r", encoding="utf-8", errors="replace") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    record = json.loads(line)
                except json.JSONDecodeError:
                    yield {}, False
                    continue
                if isinstance(record, dict):
                    yield record, True
                else:
                    yield {}, False
    except OSError:
        return


# ---------------------------------------------------------------------------
# Per-harness adapters. Each returns (observations, coverage). Every adapter
# is read-only and touches nothing but the fields documented for it in
# docs/agent-session-transcripts.md.
# ---------------------------------------------------------------------------


def scan_claude(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        sid = session_id(path)
        joiner = CallJoiner()
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = str(record.get("timestamp", "") or "")
            coverage.note_ts(ts)
            rtype = record.get("type")
            is_subagent = bool(record.get("isSidechain")) or record.get(
                "agentId"
            ) is not None
            actor = "subagent" if is_subagent else "assistant"

            att = record.get("attachment")
            if isinstance(att, dict):
                atype = att.get("type")
                if atype == "hook_success":
                    hook_name = str(att.get("hookName", ""))[:MAX_FIELD_LEN]
                    hook_event = str(att.get("hookEvent", ""))[:MAX_FIELD_LEN]
                    name = f"{hook_event}:{hook_name}"[:MAX_FIELD_LEN]
                    exit_code = att.get("exitCode")
                    emit(
                        obs,
                        harness="claude",
                        session=sid,
                        kind="hook_run",
                        ts=ts,
                        actor="system",
                        name=name,
                        ok=(exit_code == 0) if exit_code is not None else None,
                        ms=att.get("durationMs"),
                    )
                elif atype == "invoked_skills":
                    for skill in att.get("skills") or []:
                        if isinstance(skill, dict) and skill.get("name"):
                            emit(
                                obs,
                                harness="claude",
                                session=sid,
                                kind="skill_invoke",
                                ts=ts,
                                actor=actor,
                                name=str(skill["name"])[:MAX_FIELD_LEN],
                            )
                elif atype == "command_permissions":
                    for tool in att.get("allowedTools") or []:
                        emit(
                            obs,
                            harness="claude",
                            session=sid,
                            kind="permission_state",
                            ts=ts,
                            actor="system",
                            name=str(tool)[:MAX_FIELD_LEN],
                        )

            if rtype in ("stop_hook_summary", "compact_boundary") or record.get(
                "subtype"
            ) in ("stop_hook_summary", "compact_boundary"):
                emit(
                    obs,
                    harness="claude",
                    session=sid,
                    kind="compaction",
                    ts=ts,
                    actor="system",
                    detail=str(record.get("subtype", ""))[:MAX_FIELD_LEN],
                )

            message = record.get("message")
            if isinstance(message, dict):
                diag = message.get("diagnostics")
                if isinstance(diag, dict):
                    reason = diag.get("cache_miss_reason")
                    if isinstance(reason, dict) and reason.get("type"):
                        emit(
                            obs,
                            harness="claude",
                            session=sid,
                            kind="cache_miss",
                            ts=ts,
                            actor=actor,
                            detail=str(reason["type"])[:MAX_FIELD_LEN],
                        )
                content = message.get("content")
                if isinstance(content, list):
                    for item in content:
                        if not isinstance(item, dict):
                            continue
                        if item.get("type") == "tool_use":
                            name = str(item.get("name", ""))[:MAX_FIELD_LEN]
                            call_id = str(item.get("id", ""))
                            kind = "mcp_call" if name.startswith("mcp__") else "tool_call"
                            if name == "Skill":
                                skill_input = item.get("input")
                                if isinstance(skill_input, dict) and skill_input.get(
                                    "skill"
                                ):
                                    emit(
                                        obs,
                                        harness="claude",
                                        session=sid,
                                        kind="skill_invoke",
                                        ts=ts,
                                        actor=actor,
                                        name=str(skill_input["skill"])[:MAX_FIELD_LEN],
                                    )
                            joiner.open(
                                call_id, ts=ts, name=name, kind=kind, actor=actor
                            )
                        elif item.get("type") == "tool_result":
                            call_id = str(item.get("tool_use_id", ""))
                            is_error = item.get("is_error", None)
                            ok = None if is_error is None else (not is_error)
                            opened = joiner.close(call_id)
                            if opened:
                                emit(
                                    obs,
                                    harness="claude",
                                    session=sid,
                                    kind=opened["kind"],
                                    ts=opened["ts"],
                                    actor=opened["actor"],
                                    name=opened["name"],
                                    ok=ok,
                                )
                            else:
                                emit(
                                    obs,
                                    harness="claude",
                                    session=sid,
                                    kind="tool_result",
                                    ts=ts,
                                    actor=actor,
                                    ok=ok,
                                )
        for opened in joiner.flush():
            emit(
                obs,
                harness="claude",
                session=sid,
                kind=opened["kind"],
                ts=opened["ts"],
                actor=opened["actor"],
                name=opened["name"],
                ok=None,
            )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


def scan_codex(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        sid = session_id(path)
        joiner = CallJoiner()
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = str(record.get("timestamp", "") or "")
            coverage.note_ts(ts)
            rtype = record.get("type")
            payload = record.get("payload")
            if rtype == "inter_agent_communication_metadata":
                actor = "subagent"
            else:
                actor = "assistant"

            if rtype == "compacted":
                emit(
                    obs,
                    harness="codex",
                    session=sid,
                    kind="compaction",
                    ts=ts,
                    actor="system",
                )
                continue
            if not isinstance(payload, dict):
                continue
            ptype = payload.get("type")

            if ptype == "sub_agent_activity":
                actor = "subagent"
            if ptype in ("custom_tool_call", "function_call"):
                name = str(payload.get("name", ""))[:MAX_FIELD_LEN]
                call_id = str(payload.get("call_id", ""))
                joiner.open(call_id, ts=ts, name=name, kind="tool_call", actor=actor)
            elif ptype in ("custom_tool_call_output", "function_call_output"):
                call_id = str(payload.get("call_id", ""))
                opened = joiner.close(call_id)
                if opened:
                    emit(
                        obs,
                        harness="codex",
                        session=sid,
                        kind=opened["kind"],
                        ts=opened["ts"],
                        actor=opened["actor"],
                        name=opened["name"],
                        ok=None,
                    )
                else:
                    emit(
                        obs,
                        harness="codex",
                        session=sid,
                        kind="tool_result",
                        ts=ts,
                        actor=actor,
                        ok=None,
                    )
            elif ptype == "mcp_tool_call_end":
                emit(
                    obs,
                    harness="codex",
                    session=sid,
                    kind="mcp_call",
                    ts=ts,
                    actor=actor,
                )
            elif ptype == "turn_aborted":
                emit(
                    obs,
                    harness="codex",
                    session=sid,
                    kind="turn_abort",
                    ts=ts,
                    actor=actor,
                    detail=str(payload.get("reason", ""))[:MAX_FIELD_LEN],
                    ms=payload.get("duration_ms"),
                )
            elif ptype == "context_compacted":
                emit(
                    obs, harness="codex", session=sid, kind="compaction", ts=ts, actor="system"
                )
            elif rtype == "turn_context":
                profile = payload.get("permission_profile")
                if isinstance(profile, dict) and profile.get("type"):
                    emit(
                        obs,
                        harness="codex",
                        session=sid,
                        kind="permission_state",
                        ts=ts,
                        actor="system",
                        name="permission_profile",
                        detail=str(profile["type"])[:MAX_FIELD_LEN],
                    )
                sandbox = payload.get("sandbox_policy")
                if isinstance(sandbox, dict) and sandbox.get("type"):
                    emit(
                        obs,
                        harness="codex",
                        session=sid,
                        kind="permission_state",
                        ts=ts,
                        actor="system",
                        name="sandbox_policy",
                        detail=str(sandbox["type"])[:MAX_FIELD_LEN],
                    )
        for opened in joiner.flush():
            emit(
                obs,
                harness="codex",
                session=sid,
                kind=opened["kind"],
                ts=opened["ts"],
                actor=opened["actor"],
                name=opened["name"],
                ok=None,
            )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


def scan_opencode(db_path: Path, coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    if not db_path.exists():
        return obs
    coverage.files_seen += 1
    with tempfile.TemporaryDirectory() as tmp:
        # Copy read-only so a live harness is never locked or mutated.
        tmp_db = Path(tmp) / "opencode.db"
        shutil.copyfile(db_path, tmp_db)
        try:
            con = sqlite3.connect(f"file:{tmp_db}?mode=ro", uri=True)
        except sqlite3.Error:
            coverage.files_malformed += 1
            return obs
        try:
            cur = con.cursor()
            session_by_id: dict[str, str] = {}
            try:
                cur.execute("select id from session")
                for (row_id,) in cur.fetchall():
                    session_by_id[row_id] = session_id(db_path / str(row_id))
            except sqlite3.Error:
                pass

            try:
                cur.execute("select id, session_id, data from message")
                message_rows = cur.fetchall()
            except sqlite3.Error:
                message_rows = []
            for msg_id, msg_session, blob in message_rows:
                try:
                    data = json.loads(blob)
                except (json.JSONDecodeError, TypeError):
                    coverage.files_malformed += 1
                    continue
                sid = session_by_id.get(msg_session, session_id(db_path / str(msg_session)))
                role = data.get("role", "")
                actor = "subagent" if data.get("parentID") else (
                    "assistant" if role == "assistant" else "user"
                )
                time_val = data.get("time")
                ts = ""
                if isinstance(time_val, dict):
                    ts = iso(parse_ts(time_val.get("created")))
                coverage.note_ts(ts)
                if data.get("error"):
                    emit(
                        obs,
                        harness="opencode",
                        session=sid,
                        kind="turn_abort",
                        ts=ts,
                        actor=actor,
                        detail="message_error",
                    )

            try:
                cur.execute("select id, session_id, data from part")
                part_rows = cur.fetchall()
            except sqlite3.Error:
                part_rows = []
            for part_id, part_session, blob in part_rows:
                try:
                    data = json.loads(blob)
                except (json.JSONDecodeError, TypeError):
                    coverage.files_malformed += 1
                    continue
                sid = session_by_id.get(part_session, session_id(db_path / str(part_session)))
                dtype = data.get("type")
                if dtype == "tool":
                    state = data.get("state") or {}
                    status = state.get("status")
                    ok = {"completed": True, "error": False}.get(status)
                    time_val = state.get("time") or {}
                    ms = None
                    if isinstance(time_val, dict) and "start" in time_val and "end" in time_val:
                        try:
                            ms = int(time_val["end"] - time_val["start"])
                        except TypeError:
                            ms = None
                    ts = iso(parse_ts(time_val.get("start"))) if isinstance(time_val, dict) else ""
                    coverage.note_ts(ts)
                    emit(
                        obs,
                        harness="opencode",
                        session=sid,
                        kind="tool_call",
                        ts=ts,
                        actor="assistant",
                        name=str(data.get("tool", ""))[:MAX_FIELD_LEN],
                        ok=ok,
                        ms=ms,
                    )
                elif dtype == "step-finish" and data.get("reason") == "length":
                    emit(
                        obs,
                        harness="opencode",
                        session=sid,
                        kind="turn_abort",
                        actor="assistant",
                        detail="length",
                    )
            coverage.files_parsed += 1
        finally:
            con.close()
    if coverage.files_parsed and coverage.files_seen:
        # Local volume is characteristically tiny relative to session count;
        # note it as a coverage caveat rather than implying disuse.
        coverage.gaps.append(
            "message/part volume is low relative to session count locally "
            "(see docs/agent-session-transcripts.md#opencode) -- report as "
            "low coverage, not as unused features"
        )
    return obs


def scan_pi(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        sid = session_id(path)
        joiner = CallJoiner()
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = str(record.get("timestamp", "") or "")
            coverage.note_ts(ts)
            message = record.get("message")
            if not isinstance(message, dict):
                continue
            role = message.get("role")
            if role == "user":
                text = message.get("content")
                text_str = text if isinstance(text, str) else ""
                if not text_str and isinstance(text, list):
                    for chunk in text:
                        if isinstance(chunk, dict) and chunk.get("type") == "text":
                            text_str = chunk.get("text", "")
                            break
                match = _PI_SKILL_TAG.match(text_str) if text_str else None
                if match:
                    emit(
                        obs,
                        harness="pi",
                        session=sid,
                        kind="skill_invoke",
                        ts=ts,
                        actor="user",
                        name=match.group("name")[:MAX_FIELD_LEN],
                    )
            elif role == "assistant":
                content = message.get("content")
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "toolCall":
                            name = str(item.get("name", ""))[:MAX_FIELD_LEN]
                            call_id = str(item.get("id", ""))
                            joiner.open(
                                call_id, ts=ts, name=name, kind="tool_call", actor="assistant"
                            )
                            args = item.get("arguments")
                            target = ""
                            if isinstance(args, dict):
                                target = str(
                                    args.get("path") or args.get("url") or ""
                                )
                            if name == "read" and (
                                target.endswith("SKILL.md") or target.startswith("skill://")
                            ):
                                if target.startswith("skill://"):
                                    skill_name = target[len("skill://") :].split("/")[0]
                                else:
                                    skill_name = Path(target).parent.name
                                emit(
                                    obs,
                                    harness="pi",
                                    session=sid,
                                    kind="skill_read",
                                    ts=ts,
                                    actor="assistant",
                                    name=skill_name[:MAX_FIELD_LEN],
                                )
            elif role == "toolResult":
                call_id = str(message.get("toolCallId", ""))
                is_error = message.get("isError")
                ok = None if is_error is None else (not is_error)
                opened = joiner.close(call_id)
                if opened:
                    emit(
                        obs,
                        harness="pi",
                        session=sid,
                        kind=opened["kind"],
                        ts=opened["ts"],
                        actor=opened["actor"],
                        name=opened["name"],
                        ok=ok,
                    )
                else:
                    emit(
                        obs, harness="pi", session=sid, kind="tool_result", ts=ts, actor="assistant", ok=ok
                    )
        for opened in joiner.flush():
            emit(
                obs,
                harness="pi",
                session=sid,
                kind=opened["kind"],
                ts=opened["ts"],
                actor=opened["actor"],
                name=opened["name"],
                ok=None,
            )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


import re as _re

_PI_SKILL_TAG = _re.compile(r'^<skill name="(?P<name>[^"]+)" location="[^"]*">')


def scan_omp(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        # Nested subagent JSONL sits beside the parent under the same
        # session directory; the top-level form is `<timestamp>_<id>.jsonl`,
        # anything else in that directory is a subagent transcript.
        is_top_level = bool(_re.match(r"^[\d T:.\-Z]+_[0-9a-f-]+\.jsonl$", path.name))
        default_actor = "assistant" if is_top_level else "subagent"
        sid = session_id(path)
        joiner = CallJoiner()
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = str(record.get("timestamp", "") or "")
            coverage.note_ts(ts)
            rtype = record.get("type")
            if rtype == "compaction":
                emit(
                    obs, harness="omp", session=sid, kind="compaction", ts=ts, actor="system"
                )
            elif rtype == "custom":
                custom_type = record.get("customType")
                data = record.get("data") or {}
                if custom_type == "tool_execution_start":
                    name = str(data.get("toolName", ""))[:MAX_FIELD_LEN]
                    call_id = str(data.get("toolCallId", ""))
                    started = str(data.get("startedAt", "") or ts)
                    joiner.open(
                        call_id,
                        ts=started,
                        name=name,
                        kind="tool_call",
                        actor=default_actor,
                    )
                elif custom_type == "session_exit":
                    emit(
                        obs,
                        harness="omp",
                        session=sid,
                        kind="turn_abort",
                        ts=ts,
                        actor="system",
                        detail=str(data.get("reason", ""))[:MAX_FIELD_LEN],
                    )
            elif rtype == "custom_message":
                if record.get("customType") == "skill-prompt":
                    details = record.get("details") or {}
                    if details.get("name"):
                        emit(
                            obs,
                            harness="omp",
                            session=sid,
                            kind="skill_invoke",
                            ts=ts,
                            actor=default_actor,
                            name=str(details["name"])[:MAX_FIELD_LEN],
                        )
            elif rtype == "message":
                message = record.get("message")
                if isinstance(message, dict) and message.get("role") == "toolResult":
                    call_id = str(message.get("toolCallId", ""))
                    is_error = message.get("isError")
                    ok = None if is_error is None else (not is_error)
                    opened = joiner.close(call_id)
                    if opened:
                        ms = None
                        start_epoch = parse_ts(opened["ts"])
                        end_epoch = parse_ts(ts)
                        if start_epoch is not None and end_epoch is not None:
                            ms = int((end_epoch - start_epoch) * 1000)
                        emit(
                            obs,
                            harness="omp",
                            session=sid,
                            kind=opened["kind"],
                            ts=opened["ts"],
                            actor=opened["actor"],
                            name=opened["name"],
                            ok=ok,
                            ms=ms,
                        )
                    else:
                        emit(
                            obs,
                            harness="omp",
                            session=sid,
                            kind="tool_result",
                            ts=ts,
                            actor=default_actor,
                            ok=ok,
                        )
        for opened in joiner.flush():
            emit(
                obs,
                harness="omp",
                session=sid,
                kind=opened["kind"],
                ts=opened["ts"],
                actor=opened["actor"],
                name=opened["name"],
                ok=None,
            )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


def scan_grok(session_dirs: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for sess_dir in session_dirs:
        sid = session_id(sess_dir)
        chat_history = sess_dir / "chat_history.jsonl"
        if chat_history.is_file():
            coverage.files_seen += 1
            parsed_any = False
            first_ts = ""
            for record, ok in read_jsonl_lines(chat_history):
                if not ok:
                    coverage.files_malformed += 1
                    continue
                parsed_any = True
                if not first_ts:
                    first_ts = str(record.get("timestamp", "") or "")
            if parsed_any:
                coverage.files_parsed += 1
                emit(
                    obs,
                    harness="grok",
                    session=sid,
                    kind="session_start",
                    ts=first_ts,
                    actor="user",
                )
        events = sess_dir / "events.jsonl"
        if events.is_file():
            coverage.files_seen += 1
            parsed_any = False
            for record, ok in read_jsonl_lines(events):
                if not ok:
                    coverage.files_malformed += 1
                    continue
                parsed_any = True
                ts = str(record.get("ts", "") or "")
                coverage.note_ts(ts)
                etype = record.get("type")
                if etype in (
                    "mcp_server_starting",
                    "mcp_server_connected",
                    "mcp_server_failed",
                ):
                    ok = {"mcp_server_connected": True, "mcp_server_failed": False}.get(
                        etype
                    )
                    emit(
                        obs,
                        harness="grok",
                        session=sid,
                        kind="mcp_lifecycle",
                        ts=ts,
                        actor="system",
                        name=str(record.get("server_name", ""))[:MAX_FIELD_LEN],
                        ok=ok,
                        ms=record.get("duration_ms"),
                        detail=str(record.get("error_type", "") or "")[:MAX_FIELD_LEN],
                    )
                elif etype == "yolo_toggled":
                    emit(
                        obs,
                        harness="grok",
                        session=sid,
                        kind="permission_state",
                        ts=ts,
                        actor="user",
                        name="yolo_toggled",
                    )
            if parsed_any:
                coverage.files_parsed += 1
        if not chat_history.is_file() and not events.is_file():
            continue
    if session_dirs:
        coverage.gaps.append("chat_history.jsonl carries no tool events")
    return obs


def scan_cursor(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        sid = session_id(path)
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = str(record.get("timestamp", "") or "")
            coverage.note_ts(ts)
            role = record.get("role")
            message = record.get("message")
            if isinstance(message, dict):
                content = message.get("content")
                if isinstance(content, list):
                    for item in content:
                        if isinstance(item, dict) and item.get("type") == "tool_use":
                            emit(
                                obs,
                                harness="cursor",
                                session=sid,
                                kind="tool_call",
                                ts=ts,
                                actor="assistant" if role == "assistant" else "user",
                                name=str(item.get("name", ""))[:MAX_FIELD_LEN],
                            )
            if record.get("type") == "turn_ended" and record.get("status") != "success":
                emit(
                    obs,
                    harness="cursor",
                    session=sid,
                    kind="turn_abort",
                    ts=ts,
                    actor="assistant",
                    detail=str(record.get("status", ""))[:MAX_FIELD_LEN],
                )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


def scan_antigravity(files: list[Path], coverage: Coverage) -> list[Obs]:
    obs: list[Obs] = []
    for path in files:
        sid = session_id(path)
        parsed_any = False
        for record, ok in read_jsonl_lines(path):
            if not ok:
                coverage.files_malformed += 1
                continue
            parsed_any = True
            ts = iso(parse_ts(record.get("timestamp")))
            coverage.note_ts(ts)
            emit(
                obs, harness="antigravity", session=sid, kind="session_start", ts=ts, actor="user"
            )
        coverage.files_seen += 1
        if parsed_any:
            coverage.files_parsed += 1
    return obs


# ---------------------------------------------------------------------------
# Orchestration
# ---------------------------------------------------------------------------

def scan_harness(slug: str, *, since_days: int, max_files: int) -> tuple[list[Obs], Coverage]:
    store = SESSION_STORES[slug]
    root, resolved_from = resolve_session_root(slug, store)
    version = cli_version(CLI_BINARIES[slug])
    coverage = Coverage(
        harness=slug,
        root=str(root),
        resolved_from=resolved_from,
        cli_version=version,
    )
    if store.note:
        coverage.gaps.append(store.note)
    if not store.verified and resolved_from != "default":
        coverage.gaps.append(f"{resolved_from} override not confirmed from primary CLI output")

    since_epoch = time.time() - since_days * 86400

    if store.kind == "none":
        coverage.gaps.append(
            "no session scanner: this harness has no transcript store this tool reads"
        )
        return [], coverage

    if store.kind == "sqlite":
        db_path = root
        if not db_path.exists():
            coverage.gaps.append(f"resolved root {root} does not exist")
            return [], coverage
        if db_path.stat().st_mtime < since_epoch:
            coverage.gaps.append("database not modified within --since window")
            return [], coverage
        return scan_opencode(db_path, coverage), coverage

    if not root.exists():
        coverage.gaps.append(f"resolved root {root} does not exist")
        return [], coverage

    if slug == "grok":
        session_dirs = [p for p in root.glob(store.pattern) if p.is_dir()]
        session_dirs.sort(
            key=lambda p: max(
                (f.stat().st_mtime for f in p.glob("*.jsonl") if f.is_file()), default=0
            ),
            reverse=True,
        )
        kept = []
        for d in session_dirs[:max_files]:
            mtimes = [f.stat().st_mtime for f in d.glob("*.jsonl") if f.is_file()]
            if mtimes and max(mtimes) >= since_epoch:
                kept.append(d)
            else:
                coverage.files_skipped_since += 1
        return scan_grok(kept, coverage), coverage

    all_files = iter_files(root, store.pattern, max_files=max_files + 10_000)
    coverage.files_skipped_max = max(0, len(all_files) - max_files)
    candidates = all_files[:max_files]
    kept = [p for p in candidates if p.stat().st_mtime >= since_epoch]
    coverage.files_skipped_since = len(candidates) - len(kept)

    if slug == "claude":
        return scan_claude(kept, coverage), coverage
    if slug == "codex":
        return scan_codex(kept, coverage), coverage
    if slug == "pi":
        return scan_pi(kept, coverage), coverage
    if slug == "omp":
        return scan_omp(kept, coverage), coverage
    if slug == "cursor":
        return scan_cursor(kept, coverage), coverage
    if slug == "antigravity":
        return scan_antigravity(kept, coverage), coverage
    raise AssertionError(f"no adapter for {slug}")


def aggregate_usage(observations: list[Obs]) -> list[dict[str, Any]]:
    groups: dict[tuple[str, str, str], list[Obs]] = {}
    for o in observations:
        groups.setdefault((o.harness, o.kind, o.name), []).append(o)
    rows: list[dict[str, Any]] = []
    for (harness, kind, name), items in groups.items():
        attempts = len(items)
        successes = sum(1 for i in items if i.ok is True)
        errors = sum(1 for i in items if i.ok is False)
        sessions = {i.session for i in items}
        top_level = sum(1 for i in items if i.actor != "subagent")
        subagent = sum(1 for i in items if i.actor == "subagent")
        durations = sorted(i.ms for i in items if i.ms is not None)
        p50 = statistics.median(durations) if durations else None
        p95 = (
            durations[min(len(durations) - 1, int(len(durations) * 0.95))]
            if durations
            else None
        )
        timestamps = sorted(i.ts for i in items if i.ts)
        if kind in ("tool_call", "tool_result", "mcp_call") and (successes or errors):
            confidence = "confirmed invocation"
        elif kind in ("tool_call", "tool_result", "mcp_call"):
            confidence = "corroborated probable"
        elif attempts:
            confidence = "confirmed invocation"
        else:
            confidence = "unknown/not observed"
        rows.append(
            {
                "harness": harness,
                "kind": kind,
                "name": name,
                "attempts": attempts,
                "successes": successes,
                "errors": errors,
                "distinct_sessions": len(sessions),
                "top_level_uses": top_level,
                "subagent_uses": subagent,
                "first_seen": timestamps[0] if timestamps else "",
                "last_seen": timestamps[-1] if timestamps else "",
                "p50_ms": p50,
                "p95_ms": p95,
                "evidence_kind": kind,
                "confidence": confidence,
            }
        )
    rows.sort(key=lambda r: r["attempts"], reverse=True)
    return rows


def aggregate_hook_cost(observations: list[Obs]) -> list[dict[str, Any]]:
    groups: dict[str, list[Obs]] = {}
    for o in observations:
        if o.harness == "claude" and o.kind == "hook_run":
            groups.setdefault(o.name, []).append(o)
    rows: list[dict[str, Any]] = []
    for name, items in groups.items():
        durations = sorted(i.ms for i in items if i.ms is not None)
        p50 = statistics.median(durations) if durations else None
        p95 = (
            durations[min(len(durations) - 1, int(len(durations) * 0.95))]
            if durations
            else None
        )
        rows.append(
            {
                "name": name,
                "firings": len(items),
                "total_ms": sum(durations) if durations else 0,
                "p50_ms": p50,
                "p95_ms": p95,
                "nonzero_exits": sum(1 for i in items if i.ok is False),
            }
        )
    rows.sort(key=lambda r: (-r["firings"], -(r["p95_ms"] or 0)))
    return rows


def aggregate_friction(usage_rows: list[dict[str, Any]], observations: list[Obs]) -> dict[str, Any]:
    tool_errors = [r for r in usage_rows if r["errors"] > 0]
    tool_errors.sort(key=lambda r: (-r["errors"], -(r["p95_ms"] or 0)))
    aborts = [o for o in observations if o.kind == "turn_abort"]
    abort_reasons: dict[str, int] = {}
    for o in aborts:
        abort_reasons[o.detail or "unknown"] = abort_reasons.get(o.detail or "unknown", 0) + 1
    cache_misses: dict[str, int] = {}
    for o in observations:
        if o.kind == "cache_miss":
            cache_misses[o.detail or "unknown"] = cache_misses.get(o.detail or "unknown", 0) + 1
    mcp_failures = [
        o for o in observations if o.kind == "mcp_lifecycle" and o.ok is False
    ]
    return {
        "tool_error_rates": tool_errors,
        "aborted_turns": {"count": len(aborts), "by_reason": abort_reasons},
        "cache_miss_reasons": cache_misses,
        "mcp_failures": len(mcp_failures),
    }


def render_markdown(
    coverages: list[Coverage],
    usage_rows: list[dict[str, Any]],
    friction: dict[str, Any],
    hook_cost: list[dict[str, Any]],
    since_days: int,
) -> str:
    lines = [f"# Harness Session Report (last {since_days}d)", "", "## Coverage", ""]
    lines.append(
        "| Harness | Root | Resolved from | CLI version | Parsed/Seen | Skipped (since/max) | Malformed | Earliest | Latest | Gaps |"
    )
    lines.append("|---|---|---|---|---|---|---|---|---|---|")
    for c in coverages:
        gaps = "; ".join(c.gaps) if c.gaps else "-"
        lines.append(
            f"| {c.harness} | `{c.root}` | {c.resolved_from} | {c.cli_version or 'not installed'} "
            f"| {c.files_parsed}/{c.files_seen} | {c.files_skipped_since}/{c.files_skipped_max} "
            f"| {c.files_malformed} | {c.earliest or '-'} | {c.latest or '-'} | {gaps} |"
        )

    lines += ["", "## Feature usage", ""]
    lines.append(
        "| Harness | Kind | Name | Attempts | Successes | Errors | Sessions | Top-level | Subagent | p50 ms | p95 ms | Confidence |"
    )
    lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
    for r in usage_rows:
        lines.append(
            f"| {r['harness']} | {r['kind']} | {r['name'] or '-'} | {r['attempts']} | "
            f"{r['successes']} | {r['errors']} | {r['distinct_sessions']} | {r['top_level_uses']} | "
            f"{r['subagent_uses']} | {r['p50_ms'] if r['p50_ms'] is not None else '-'} | "
            f"{r['p95_ms'] if r['p95_ms'] is not None else '-'} | {r['confidence']} |"
        )

    lines += ["", "## Friction", ""]
    if friction["tool_error_rates"]:
        lines.append("### Tool error rates")
        lines.append("")
        lines.append("| Harness | Kind | Name | Attempts | Errors | p95 ms |")
        lines.append("|---|---|---|---|---|---|")
        for r in friction["tool_error_rates"]:
            lines.append(
                f"| {r['harness']} | {r['kind']} | {r['name'] or '-'} | {r['attempts']} | "
                f"{r['errors']} | {r['p95_ms'] if r['p95_ms'] is not None else '-'} |"
            )
        lines.append("")
    lines.append(
        f"- Aborted turns: {friction['aborted_turns']['count']} "
        f"({', '.join(f'{k}: {v}' for k, v in friction['aborted_turns']['by_reason'].items()) or 'none'})"
    )
    lines.append(
        f"- Cache-miss reasons: "
        f"{', '.join(f'{k}: {v}' for k, v in friction['cache_miss_reasons'].items()) or 'none observed'}"
    )
    lines.append(f"- MCP connection failures: {friction['mcp_failures']}")

    if hook_cost:
        lines += ["", "## Hook cost", ""]
        lines.append("| Hook | Firings | Total ms | p50 ms | p95 ms | Non-zero exits |")
        lines.append("|---|---|---|---|---|---|")
        for r in hook_cost:
            lines.append(
                f"| {r['name']} | {r['firings']} | {r['total_ms']} | "
                f"{r['p50_ms'] if r['p50_ms'] is not None else '-'} | "
                f"{r['p95_ms'] if r['p95_ms'] is not None else '-'} | {r['nonzero_exits']} |"
            )
    lines.append("")
    return "\n".join(lines)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Measured harness feature usage and friction from local session transcripts."
    )
    parser.add_argument(
        "harness",
        nargs="*",
        help=f"harness slugs to scan (default: all of {', '.join(HARNESSES)})",
    )
    parser.add_argument("--since", type=int, default=30, help="session window in days (default 30)")
    parser.add_argument("--json", action="store_true", help="emit JSON instead of markdown")
    parser.add_argument(
        "--max-files", type=int, default=400, help="max files scanned per harness, newest first"
    )
    parser.add_argument(
        "--repo",
        default=None,
        help="reserved for parity with audit-ignored-config.py; currently unused since "
        "session stores are HOME-scoped, not repo-scoped",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    slugs = args.harness or list(HARNESSES)
    unknown = [s for s in slugs if s not in HARNESSES]
    if unknown:
        print(
            f"error: unknown harness(es): {', '.join(unknown)}. Valid slugs: {', '.join(HARNESSES)}",
            file=sys.stderr,
        )
        return 2

    all_obs: list[Obs] = []
    coverages: list[Coverage] = []
    hard_error = False
    for slug in slugs:
        try:
            obs, coverage = scan_harness(slug, since_days=args.since, max_files=args.max_files)
        except OSError as exc:
            coverage = Coverage(
                harness=slug, root="", resolved_from="", cli_version=None, gaps=[f"unreadable: {exc}"]
            )
            obs = []
            hard_error = True
        all_obs.extend(obs)
        coverages.append(coverage)

    usage_rows = aggregate_usage(all_obs)
    friction = aggregate_friction(usage_rows, all_obs)
    hook_cost = aggregate_hook_cost(all_obs)

    if args.json:
        print(
            json.dumps(
                {
                    "since_days": args.since,
                    "coverage": [c.as_dict() for c in coverages],
                    "usage": usage_rows,
                    "friction": friction,
                    "hook_cost": hook_cost,
                },
                indent=2,
                sort_keys=True,
            )
        )
    else:
        print(render_markdown(coverages, usage_rows, friction, hook_cost, args.since))

    return 1 if hard_error else 0


if __name__ == "__main__":
    raise SystemExit(main())
