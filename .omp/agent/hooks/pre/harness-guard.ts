// Copyright: Ben Chatelain. Apache 2.0.
//
// Routes omp tool calls through the compiled harness guard (ness) so omp
// enforces the same protected paths, blocked command categories, and
// secret-content rules as every other harness. Hand-written on purpose:
// ~/.omp/agent is tracked manually, not emitted by scripts/agent-harnesses.py.

import { execFileSync } from "node:child_process";
import { appendFileSync, mkdirSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

type GuardResult = { decision: "allow" | "warn" | "deny"; reason?: string };

const NESS = join(homedir(), ".local", "bin", "ness");
const GUARD_TIMEOUT_MS = 5_000;
const MAX_DERIVED_PATHS = 64;
const FAILED = "Shared guard failed closed";
const REMEDY =
  "Run `just ness-install`; if the hook source changed mid-session (e.g. `git pull`), " +
  "restart omp — a running session keeps the module it loaded.";

// 2026-09-07 optimize-harness audit: bash sees a 9.2% tool-error rate
// (871/9460 attempts) and its own p95 (7197ms) exceeds GUARD_TIMEOUT_MS
// (5000ms), so some fraction of "bash failed" is plausibly the guard
// timing out rather than the shell command itself failing. This log lets
// a future scan tell "ness denied/timed out" apart from "the command
// failed" before tuning further. Best-effort only: a logging failure must
// never affect the guard's decision.
const GUARD_LOG_PATH = join(
  homedir(),
  ".omp",
  "agent",
  "logs",
  "harness-guard.log"
);
let guardLogDirReady = false;

function logGuardVerdict(tool: string, result: GuardResult, ms: number): void {
  try {
    if (!guardLogDirReady) {
      mkdirSync(dirname(GUARD_LOG_PATH), { recursive: true });
      guardLogDirReady = true;
    }
    const reason = result.reason
      ? ` reason=${JSON.stringify(result.reason)}`
      : "";
    appendFileSync(
      GUARD_LOG_PATH,
      `${new Date().toISOString()} tool=${tool} decision=${result.decision} ms=${ms}${reason}\n`
    );
  } catch {
    // Best-effort diagnostics; never let logging break the guard.
  }
}

// Tool-input keys whose value is executed rather than stored. Key-driven so no
// per-device table has to be maintained as xd:// devices come and go.
const CODE_KEYS: Record<string, true> = {
  code: true,
  command: true,
  cmd: true,
  expression: true,
  program: true,
  application: true,
  text: true,
};

const SECTION = /^\[(.+)#[0-9A-Fa-f]{4}\]\s*$/;
const MOVE = /^MV\s+(.+?)\s*$/;
const QUOTED = /^["'](.*)["']$/;
// Absolute, ~-relative, and ./ ../-relative tokens only. The lookbehind keeps
// `src/foo.ts` and `https://host/path` out (a bare relative path has no
// unambiguous root, and ness resolves against its own cwd).
const PATH_TOKEN = /(?<![\w:@./])(?:~|\.{1,2})?\/[^\s"'`,;()[\]{}<>|]+/g;
// Quoted bare dotfiles: `open(".env")` never has a slash to anchor on.
const QUOTED_DOTFILE = /(?<=["'`])\.[\w.-]+(?=["'`])/g;

function bytesOf(value: unknown): string {
  if (typeof value === "string") return value;
  if (value instanceof Uint8Array) return Buffer.from(value).toString("utf8");
  return "";
}

function field(error: unknown, key: string): unknown {
  return error && typeof error === "object" && key in error
    ? (error as Record<string, unknown>)[key]
    : undefined;
}

// Exported for the throwaway driver. Deliberately a pure formatter: the guard
// binary path stays a hardcoded const, because any override seam (env var,
// option) would be a way to neuter the guard from inside a session.
export function spawnFailureReason(error: unknown): string {
  const stdout = bytesOf(field(error, "stdout")).trim();
  if (stdout) {
    const clipped = stdout.replace(/\s+/g, " ").slice(0, 200);
    return `${FAILED}: ness printed output that is not a verdict: ${clipped}. ${REMEDY}`;
  }
  const code = String(field(error, "code") ?? "");
  const stderr = bytesOf(field(error, "stderr")).trim().split("\n")[0] ?? "";
  if (code === "ENOENT") {
    return `${FAILED}: ${NESS} is not installed (run: just ness-install)`;
  }
  if (code === "EACCES" || code === "ENOEXEC") {
    return `${FAILED}: ${NESS} is not executable (${code}). ${REMEDY}`;
  }
  if (code === "E2BIG") {
    return `${FAILED}: this call is too large for the guard's argv interface (E2BIG; ARG_MAX is 1048576 bytes on this machine). Split the change into smaller calls or apply it outside the agent — restarting will not help.`;
  }
  if (field(error, "killed") === true || code === "ETIMEDOUT") {
    return `${FAILED}: ness did not answer within ${GUARD_TIMEOUT_MS}ms. ${REMEDY}`;
  }
  const message = String(field(error, "message") ?? error);
  return `${FAILED}: ${code || "spawn failed"}: ${
    stderr ? `${message} (stderr: ${stderr})` : message
  }. ${REMEDY}`;
}

function runGuard(args: string[], cwd: string): GuardResult {
  const flags = cwd ? [...args, "--cwd", cwd] : args;
  const started = Date.now();
  const tool = args[1] ?? "unknown"; // args = ["--tool", <write|bash>, ...]
  try {
    const output = execFileSync(NESS, ["guard", "--harness", "omp", ...flags], {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "pipe"],
      timeout: GUARD_TIMEOUT_MS,
      ...(cwd ? { cwd } : {}),
    });
    const result = JSON.parse(output) as GuardResult;
    logGuardVerdict(tool, result, Date.now() - started);
    return result;
  } catch (error: unknown) {
    // ness exits 2 on deny but still prints its verdict; anything else means
    // the policy engine was unreachable, which stays fail-closed.
    const stdout = bytesOf(field(error, "stdout")).trim();
    if (stdout) {
      try {
        const result = JSON.parse(stdout) as GuardResult;
        logGuardVerdict(tool, result, Date.now() - started);
        return result;
      } catch {
        // Unparseable output is an engine failure, not a verdict.
      }
    }
    const result: GuardResult = {
      decision: "deny",
      reason: spawnFailureReason(error),
    };
    logGuardVerdict(tool, result, Date.now() - started);
    return result;
  }
}

// omp's `edit` input is a hashline patch, not {path, content}: section headers
// carry the targets and `+` rows carry the new bytes. Mirrors ness's Codex
// apply_patch handling (hook.rs:146-162): every target first, then the added
// content in one content-only call.
export function editTargets(patch: string): { paths: string[]; added: string } {
  const paths: string[] = [];
  const added: string[] = [];
  for (const line of patch.split("\n")) {
    const section = SECTION.exec(line);
    if (section) {
      paths.push(section[1]);
      continue;
    }
    const move = MOVE.exec(line);
    if (move) {
      paths.push(move[1].replace(QUOTED, "$1"));
      continue;
    }
    if (line.startsWith("+")) added.push(line.slice(1));
  }
  return { paths, added: added.join("\n") };
}

export function pathTokens(text: string): string[] {
  const out: string[] = [];
  for (const match of text.matchAll(PATH_TOKEN)) out.push(match[0]);
  for (const match of text.matchAll(QUOTED_DOTFILE)) out.push(match[0]);
  return out;
}

export function walkInput(
  value: unknown,
  key: string,
  commands: string[],
  strings: string[],
  depth = 0
): void {
  if (depth > 8) return;
  if (typeof value === "string") {
    strings.push(value);
    if (CODE_KEYS[key]) commands.push(value);
    return;
  }
  if (Array.isArray(value)) {
    if (key === "args" && value.every((item) => typeof item === "string")) {
      commands.push(value.join(" "));
      for (const item of value) strings.push(item as string);
      return;
    }
    for (const item of value)
      walkInput(item, key, commands, strings, depth + 1);
    return;
  }
  if (value && typeof value === "object") {
    for (const [childKey, child] of Object.entries(value)) {
      walkInput(child, childKey, commands, strings, depth + 1);
    }
  }
}

type Checks = {
  commands: string[];
  writes: Array<{ path: string; content: string }>;
  paths: string[];
};

export function checksFor(
  toolName: string,
  input: Record<string, unknown>
): Checks {
  const commands: string[] = [];
  const writes: Array<{ path: string; content: string }> = [];
  const strings: string[] = [];

  if (toolName === "bash") {
    commands.push(String(input.command ?? ""));
  } else if (toolName === "write") {
    const path = String(input.file_path ?? input.path ?? "");
    const content = String(input.content ?? "");
    writes.push({ path, content });
    if (path.startsWith("xd://")) {
      // Device args ride in `content` as JSON: ast_edit rewrites files, lsp
      // renames them, the repl devices execute code. The raw content is
      // already secret-scanned by the write call above; this reaches the
      // targets and code inside it.
      try {
        walkInput(JSON.parse(content), "", commands, strings);
      } catch {
        // Malformed device JSON never reaches a device; nothing to guard.
      }
    }
  } else if (toolName === "edit") {
    const { paths, added } = editTargets(String(input.input ?? ""));
    for (const path of paths) writes.push({ path, content: "" });
    if (added) writes.push({ path: "", content: added });
  } else if (toolName === "eval" || toolName === "hub") {
    walkInput(input, "", commands, strings);
  }

  const paths: string[] = [];
  for (const text of strings) paths.push(...pathTokens(text));
  return { commands, writes, paths };
}

export default function hook(pi: ExtensionAPI): void {
  let notifiedUnreachable = false;

  pi.on("tool_call", async (event, ctx) => {
    const input = (event.input ?? {}) as Record<string, unknown>;
    const checks = checksFor(event.toolName, input);
    const derived = [...new Set(checks.paths)];
    if (!checks.commands.length && !checks.writes.length && !derived.length) {
      return undefined;
    }
    if (derived.length > MAX_DERIVED_PATHS) {
      return {
        block: true,
        reason: `${FAILED}: ${derived.length} path-like values in this call exceed the ${MAX_DERIVED_PATHS}-path check budget; split the call into smaller ones.`,
      };
    }

    const cwd = typeof ctx?.cwd === "string" ? ctx.cwd : "";
    const calls: string[][] = [];
    for (const write of checks.writes) {
      calls.push([
        "--tool",
        "write",
        "--path",
        write.path,
        "--content",
        write.content,
      ]);
    }
    for (const command of checks.commands) {
      calls.push(["--tool", "bash", "--command", command]);
    }
    for (const path of derived) {
      calls.push(["--tool", "write", "--path", path, "--content", ""]);
    }

    for (const args of calls) {
      const result = runGuard(args, cwd);
      if (result.decision === "deny") {
        const reason = result.reason || "Blocked by shared harness guard";
        if (reason.startsWith(FAILED) && !notifiedUnreachable) {
          notifiedUnreachable = true;
          if (ctx?.hasUI) ctx.ui.notify(reason, "info");
        }
        return { block: true, reason };
      }
      if (result.decision === "warn" && result.reason && ctx?.hasUI) {
        // ness's main-branch-commit warning; every other harness surfaces it.
        ctx.ui.notify(result.reason, "info");
      }
    }
    return undefined;
  });
}
