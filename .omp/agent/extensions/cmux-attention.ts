// cmux-attention.ts — tell cmux when omp needs the user.
// Copyright: Ben Chatelain. MIT
//
// omp's approval overlays are TUI dialogs. When the session runs in a cmux
// terminal, the user may be looking at another tab, so the dialog is invisible
// and the agent looks stopped with no explanation.
//
// This extension mirrors omp's attention requests into cmux as a cmux
// notification, which lands in the Notifications panel, marks the tab unread,
// rings the surface, and posts a desktop banner.
//
// Two sources are covered:
//
// - omp's own approval gate (`tool_approval_requested`). omp already raises
//   the OSC 7501 blocked state for it, so only the notification is added.
//
// - Any extension dialog drawn through `ctx.ui.select` / `ctx.ui.confirm`,
//   most importantly the shared harness guard's bash approval prompt. That
//   dialog is not an omp approval event, so this extension also drives the
//   OSC 7501 blocked state for it. Wrapping the shared UI object covers every
//   extension without modifying any of them.
//
// The OSC 7501 status pill is not driven for omp's native approvals: omp
// raises `blocked` itself and restores `working` when they resolve, and
// writing the state from here as well would fight that machine.

import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import {
  inCmuxSurface,
  raiseAttention,
  lowerAttention,
  resetAttention,
  reportBlocked,
  reportWorking,
} from "../shared/cmux-attention";

/** The dialog methods that put a question in front of the user. */
type DialogMethod = "select" | "confirm";

/** One line describing what the agent wants, for the badge and the banner. */
function summarizeApproval(toolName: string, reason: string | undefined): string {
  const base = `omp wants to run ${toolName}`;
  if (!reason) return base;
  return `${base}: ${reason}`;
}

/**
 * Classify a dialog as a permission request or a plain question.
 *
 * The harness guard titles its bash approval prompt "ness: approve bash
 * command?"; anything else is treated as a question.
 */
function classifyDialog(title: string): "permission" | "question" {
  return /approve|permission|allow/i.test(title) ? "permission" : "question";
}

/** The parts of the extension UI context this extension wraps. */
interface WrappableUi {
  select?: (...args: unknown[]) => unknown;
  confirm?: (...args: unknown[]) => unknown;
}

export default function cmuxAttention(pi: ExtensionAPI): void {
  if (!inCmuxSurface()) return;

  // Approval prompts, keyed by tool call id so each one is lowered exactly once.
  const pendingApprovals = new Set<string>();
  // Dialogs observed through the wrapped UI, so each one is lowered once.
  let openDialogs = 0;
  // The UI object is shared by every extension in the session; wrap it once.
  let uiWrapped = false;

  const wrapDialog = (ui: WrappableUi, method: DialogMethod): void => {
    const original = ui[method];
    if (typeof original !== "function") return;
    ui[method] = async (...args: unknown[]) => {
      const title = typeof args[0] === "string" ? args[0] : "";
      const detail = typeof args[1] === "string" ? args[1] : undefined;
      const kind = classifyDialog(title);
      openDialogs += 1;
      reportBlocked({ kind, summary: title || "omp is waiting for your answer", detail });
      await raiseAttention({ kind, summary: title || "omp is waiting for your answer", detail });
      try {
        return await (original as (...callArgs: unknown[]) => unknown).apply(ui, args);
      } finally {
        openDialogs -= 1;
        lowerAttention();
        if (openDialogs === 0) {
          // omp never set a blocked status for an extension dialog, so
          // restore the working state it would have shown on its own.
          reportWorking();
        }
      }
    };
  };

  pi.on("tool_call", async (_event, ctx: ExtensionContext) => {
    if (uiWrapped) return;
    const ui = ctx.ui as unknown as WrappableUi;
    if (!ui || typeof ui !== "object") return;
    wrapDialog(ui, "select");
    wrapDialog(ui, "confirm");
    uiWrapped = true;
    return undefined;
  });

  pi.on("tool_approval_requested", async (event) => {
    const toolCallId = String(event.toolCallId ?? "");
    pendingApprovals.add(toolCallId);
    await raiseAttention({
      kind: "permission",
      summary: summarizeApproval(event.toolName, event.reason),
    });
  });

  pi.on("tool_approval_resolved", async (event) => {
    const toolCallId = String(event.toolCallId ?? "");
    if (!pendingApprovals.delete(toolCallId)) return;
    lowerAttention();
  });

  // An `ask` tool call is the other way omp waits on a human: it renders the
  // question dialog from the tool itself.
  pi.on("tool_execution_start", async (event) => {
    if (event.toolName !== "ask") return;
    await raiseAttention({
      kind: "question",
      summary: "omp is waiting for your answer",
    });
  });

  pi.on("tool_result", async (event) => {
    if (event.toolName !== "ask") return;
    lowerAttention();
  });

  pi.on("session_shutdown", async () => {
    resetAttention();
  });
}
