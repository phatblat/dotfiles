// flywheel-outcome.ts — Record stage of the dotfiles agent flywheel (docs/flywheel.md).
// Copyright: Ben Chatelain. MIT
//
// Appends one outcome record per main-agent session to
// $XDG_STATE_HOME/flywheel/dotfiles/outcomes.jsonl (default ~/.local/state/...),
// outside git, when the session ends (switch or shutdown). The outcome is the
// session's observable end state, never a guess about task success:
// - last settled run ended with stopReason "error"   -> failed
// - last settled run ended with stopReason "aborted" -> abandoned
// - otherwise                                        -> success
// `corrected` is true when the user interrupted a run and then sent another prompt.
// No prompt or transcript text is stored; `task` is the working directory's basename.
import * as path from "node:path";
import type { AgentEndEvent, ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { appendLedger, opaqueSessionId, sanitizeText } from "../shared/flywheel-ledger";

interface SessionOutcome {
  runs: number; // settled main-agent runs
  lastStop: string; // stopReason of the last settled run's final assistant message
  abortedPending: boolean; // last settled run was aborted and no prompt followed yet
  corrected: boolean;
  cwd: string;
}

function finalStopReason(event: AgentEndEvent): string {
  for (let index = event.messages.length - 1; index >= 0; index -= 1) {
    const message = event.messages[index] as { role?: unknown; stopReason?: unknown };
    if (message?.role === "assistant" && typeof message.stopReason === "string") return message.stopReason;
  }
  return "";
}

function outcomeFor(stop: string): "success" | "failed" | "abandoned" {
  if (stop === "error") return "failed";
  if (stop === "aborted") return "abandoned";
  return "success";
}

export default function flywheelOutcome(pi: ExtensionAPI) {
  const sessions = new Map<string, SessionOutcome>();
  const stateFor = (ctx: ExtensionContext): SessionOutcome => {
    const id = ctx.sessionManager.getSessionId();
    let state = sessions.get(id);
    if (!state) {
      state = { runs: 0, lastStop: "", abortedPending: false, corrected: false, cwd: ctx.cwd };
      sessions.set(id, state);
    }
    return state;
  };

  pi.on("input", async (_event, ctx) => {
    if (ctx.agent.kind !== "main") return;
    const state = stateFor(ctx);
    if (state.abortedPending) state.corrected = true;
    state.abortedPending = false;
  });

  pi.on("agent_end", async (event, ctx) => {
    if (ctx.agent.kind !== "main" || event.willContinue === true) return;
    const state = stateFor(ctx);
    state.runs += 1;
    state.lastStop = finalStopReason(event);
    state.abortedPending = state.lastStop === "aborted";
  });

  // Write one record for a session that ran at least once, then forget it.
  const flush = (id: string): void => {
    const state = sessions.get(id);
    sessions.delete(id);
    if (!state || state.runs === 0) return;
    const record = {
      corrected: state.corrected,
      date: new Date().toISOString().slice(0, 10),
      harness: "omp",
      outcome: outcomeFor(state.lastStop),
      session_id: opaqueSessionId(id),
      task: sanitizeText(`omp session (${path.basename(state.cwd)})`),
    };
    appendLedger("outcomes.jsonl", record);
  };

  // /new, /resume, and fork end the current session without a shutdown.
  pi.on("session_before_switch", async (_event, ctx) => {
    flush(ctx.sessionManager.getSessionId());
  });

  // The process is ending: every session this instance tracked is over.
  pi.on("session_shutdown", async () => {
    for (const id of [...sessions.keys()]) flush(id);
  });
}
