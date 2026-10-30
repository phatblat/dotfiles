// cmux-attention.ts — report an omp attention request to cmux.
// Copyright: Ben Chatelain. MIT
//
// Two independent channels, because cmux drives them from different signals:
//
// 1. A cmux notification (`cmux notify`), which is what lands in the
//    Notifications panel, drives the workspace unread badge, draws the
//    surface attention ring, and posts the desktop banner.
//
// 2. OSC 7501 program status (`setRunStatus`), which cmux projects into the
//    workspace/sidebar status pill. `blocked` is the state that means "the
//    agent is waiting on you"; cmux renders it with the bell icon.
//
// The CLI path is used rather than a raw OSC 9/777 escape on purpose: cmux
// suppresses raw terminal notifications on surfaces running a hook-integrated
// agent (see Workspace.suppressesRawTerminalNotification), and `cmux notify`
// is not subject to that suppression.
//
// Every call is best-effort: a missing cmux, an unreachable socket, or a
// closed surface must never break the agent's turn.

import { spawn } from "node:child_process";
import type { ChildProcess } from "node:child_process";
import { existsSync } from "node:fs";
import { setRunStatus } from "@oh-my-pi/pi-coding-agent/utils/run-status";

/** cmux's binary name; overridable for installs outside PATH. */
const CMUX_BIN = "cmux";
/** A cmux call that must not hold up the turn. */
const CMUX_TIMEOUT_MS = 5_000;

export type AttentionKind = "permission" | "question";

export interface AttentionRequest {
  /** What the agent is waiting for. */
  kind: AttentionKind;
  /** One-line summary of the ask, shown in the badge and banner. */
  summary: string;
  /** The detail shown under the summary (the command, the question body). */
  detail?: string;
}

/**
 * True when this session runs inside a cmux terminal surface.
 *
 * cmux exports both variables into every terminal it opens; a session started
 * elsewhere (a plain shell, an SSH hop) must not try to talk to cmux.
 */
export function inCmuxSurface(): boolean {
  return Boolean(process.env.CMUX_SURFACE_ID && process.env.CMUX_WORKSPACE_ID);
}

/**
 * Resolve the cmux binary to invoke.
 *
 * `CMUX_OMP_CMUX_BIN` lets a user point at a specific cmux build, but it must
 * name an executable. A shell function or alias cannot be spawned, so an
 * override that is not an executable file falls back to `cmux` on PATH instead
 * of silently disabling the bridge.
 */
function cmuxBinary(): string {
  const override = process.env.CMUX_OMP_CMUX_BIN;
  if (override && override.includes("/")) {
    return existsSync(override) ? override : CMUX_BIN;
  }
  return CMUX_BIN;
}

/**
 * State shared by every copy of this module in one omp process.
 *
 * omp loads a fresh copy of a module per session (each import uses a unique
 * cache-busting URL), so module scope is per-session while the cmux surface
 * is per-process. Several extensions can raise attention at once, so the
 * notification id and the open-request count live on globalThis.
 */
interface AttentionState {
  /** Id of the cmux notification currently on screen, if any. */
  notificationId: string | undefined;
  /** How many attention requests are open at once. */
  depth: number;
}

const globals = globalThis as typeof globalThis & { __cmuxOmpAttention?: AttentionState };

function state(): AttentionState {
  globals.__cmuxOmpAttention ??= { notificationId: undefined, depth: 0 };
  return globals.__cmuxOmpAttention;
}

/** Create a cmux notification on the caller's surface. Resolves to its id. */
export function postNotification(request: AttentionRequest): Promise<string | undefined> {
  const surfaceId = process.env.CMUX_SURFACE_ID;
  if (!surfaceId) return Promise.resolve(undefined);
  const body = request.detail ? `${request.summary}\n${request.detail}` : request.summary;
  const args = [
    "notify",
    "--surface",
    surfaceId,
    "--title",
    request.kind === "permission" ? "Permission needed" : "Question",
    "--body",
    body,
    "--json",
  ];
  return new Promise<string | undefined>((resolve) => {
    let child: ChildProcess;
    try {
      child = spawn(cmuxBinary(), args, { stdio: ["ignore", "pipe", "ignore"], env: process.env });
    } catch {
      resolve(undefined);
      return;
    }
    let out = "";
    child.stdout?.on("data", (chunk: Buffer) => {
      out += chunk.toString("utf8");
    });
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      resolve(undefined);
    }, CMUX_TIMEOUT_MS);
    timer.unref();
    child.on("error", () => {
      clearTimeout(timer);
      resolve(undefined);
    });
    child.on("close", () => {
      clearTimeout(timer);
      try {
        const parsed: unknown = JSON.parse(out);
        if (!parsed || typeof parsed !== "object") {
          resolve(undefined);
          return;
        }
        const id = (parsed as Record<string, unknown>).id;
        resolve(typeof id === "string" ? id : undefined);
      } catch {
        resolve(undefined);
      }
    });
  });
}

/** Mark a previously posted cmux notification as read. */
export function markNotificationRead(id: string | undefined): void {
  if (!id) return;
  try {
    const child = spawn(cmuxBinary(), ["mark-notification-read", "--id", id], {
      stdio: "ignore",
      env: process.env,
    });
    child.on("error", () => {});
    child.unref();
  } catch {
    // Best effort: a stale notification is not worth failing a turn over.
  }
}

/**
 * Announce that the agent is waiting on the user.
 *
 * The first request raises the cmux notification; nested requests only
 * refresh the OSC 7501 state, so a sequence of prompts does not spam the feed.
 */
export async function raiseAttention(request: AttentionRequest): Promise<void> {
  const current = state();
  current.depth += 1;
  if (current.depth > 1) return;
  const id = await postNotification(request);
  // Prompts still open (this one or a nested one) own the notification, so
  // the last one to lower marks it read. If every prompt was already answered
  // while the notify was in flight, nothing will lower it later: mark it now.
  if (state().depth > 0 && id) {
    state().notificationId = id;
  } else {
    markNotificationRead(id);
  }
}

/**
 * Announce that the prompt was answered.
 *
 * The notification is marked read rather than dismissed, so the badge clears
 * but the history entry stays: the user can still see what the agent asked.
 */
export function lowerAttention(): void {
  const current = state();
  if (current.depth === 0) return;
  current.depth -= 1;
  if (current.depth > 0) return;
  markNotificationRead(current.notificationId);
  current.notificationId = undefined;
}

/** Drop any pending attention state, e.g. when the session shuts down. */
export function resetAttention(): void {
  const current = state();
  current.depth = 0;
  markNotificationRead(current.notificationId);
  current.notificationId = undefined;
}

/**
 * Publish the waiting-on-you state to the terminal via OSC 7501.
 *
 * Only for prompts omp's own status machine does not already describe. omp
 * raises `blocked` by itself for its native approval gate and for the `ask`
 * tool, and it restores `working` when they resolve; writing the state from
 * an extension as well would fight that machine.
 */
export function reportBlocked(request: AttentionRequest): void {
  try {
    setRunStatus({
      state: "blocked",
      kind: request.kind,
      msg: request.detail ? `${request.summary} — ${request.detail}` : request.summary,
    });
  } catch {
    // Best effort: the status pill is a hint, not a correctness requirement.
  }
}

/**
 * Restore the working state after a prompt omp does not track itself.
 *
 * `working` rather than `idle`: the agent is still mid-turn.
 */
export function reportWorking(): void {
  try {
    setRunStatus({ state: "working" });
  } catch {
    // Best effort.
  }
}
