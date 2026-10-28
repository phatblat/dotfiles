// backlog-batch-delivery.ts — Plan Review helpers for the backlog-batch-delivery skill.
// Copyright: Ben Chatelain. MIT
//
// omp has no extension API that turns plan mode on, so this cannot open Plan
// Review from normal mode. It does two things:
// - `/backlog-batch [scope]` types `/plan /skill:backlog-batch-delivery <scope>`
//   into the composer (only the skill invocation when plan mode is already on).
// - When a plan-mode run of the skill writes a `local://*plan.md` file and ends
//   without opening a review (no `xd://propose`), it opens Plan Review itself
//   via `ctx.openPlanReview()` once the session is idle.
import type { ExtensionAPI, ExtensionContext } from "@oh-my-pi/pi-coding-agent";
import { appendLedger } from "../shared/flywheel-ledger";

const SKILL_INVOCATION = "/skill:backlog-batch-delivery";
const SKILL_TOKEN = /(^|\s)\/skill:backlog-batch-delivery(?=\s|$)/;
const SKILL_READ = /^skill:\/\/backlog-batch-delivery(?=$|[/:])/;
const PLAN_FILE = /local:\/\/[^\s"'\]#]*plan\.md/i;
// openPlanReview() refuses while the finishing run is still unwinding, so retry briefly.
const RETRY_MS = 250;
const MAX_ATTEMPTS = 20;

function logScaffoldFiring(detail: string): void {
  appendLedger("scaffolds.jsonl", {
    detail,
    harness: "omp",
    scaffold: "omp-backlog-batch-plan-review",
    ts: new Date().toISOString(),
  });
}

interface BatchState {
  active: boolean; // skill invoked or loaded in this session
  run: number; // bumped on every agent_start
  planWritten: boolean; // a local://*plan.md write/edit succeeded since the last user prompt
  reviewRequested: boolean; // a plan review opened since the last user prompt
}

// Plan mode persists as `mode_change` session entries; the newest one on the branch wins.
function isPlanModeActive(ctx: ExtensionContext): boolean {
  const branch = ctx.sessionManager.getBranch() as Array<{ type: string; mode?: string }>;
  for (let i = branch.length - 1; i >= 0; i--) {
    if (branch[i].type === "mode_change") return branch[i].mode === "plan";
  }
  return false;
}

export default function backlogBatchDelivery(pi: ExtensionAPI) {
  const sessions = new Map<string, BatchState>();
  const stateFor = (ctx: ExtensionContext): BatchState => {
    const id = ctx.sessionManager.getSessionId();
    let state = sessions.get(id);
    if (!state) {
      state = { active: false, run: 0, planWritten: false, reviewRequested: false };
      sessions.set(id, state);
    }
    return state;
  };

  pi.registerCommand("backlog-batch", {
    description: "Start backlog-batch-delivery in plan mode (fills in the composer)",
    handler: async (args, ctx) => {
      if (ctx.ui.supportsEditor !== true) {
        ctx.ui.notify("backlog-batch: this mode has no editable composer", "warning");
        return;
      }
      const scope = args.trim();
      const invocation = scope ? `${SKILL_INVOCATION} ${scope}` : SKILL_INVOCATION;
      ctx.ui.setEditorText(isPlanModeActive(ctx) ? invocation : `/plan ${invocation}`);
    },
  });

  // Plan mode re-prompts the agent after a turn that ends without a proposal, so one
  // user prompt can span several runs. Per-prompt flags reset on input, not on agent_start.
  pi.on("input", async (event, ctx) => {
    if (ctx.agent.kind !== "main") return;
    const state = stateFor(ctx);
    state.planWritten = false;
    state.reviewRequested = false;
    if (SKILL_TOKEN.test(event.text)) state.active = true;
  });

  pi.on("agent_start", async (_event, ctx) => {
    if (ctx.agent.kind !== "main") return;
    stateFor(ctx).run++;
  });

  pi.on("tool_result", async (event, ctx) => {
    if (ctx.agent.kind !== "main" || event.isError) return;
    const state = stateFor(ctx);
    if (event.toolName === "read" && SKILL_READ.test(String(event.input.path ?? ""))) {
      state.active = true;
    }
    if ((event.toolName === "write" || event.toolName === "edit") && PLAN_FILE.test(JSON.stringify(event.input))) {
      state.planWritten = true;
    }
  });

  pi.on("plan_review_requested", async (_event, ctx) => {
    if (ctx.agent.kind !== "main") return;
    stateFor(ctx).reviewRequested = true;
  });

  pi.on("agent_end", async (event, ctx) => {
    if (ctx.agent.kind !== "main" || event.willContinue === true) return;
    const state = stateFor(ctx);
    if (!state.active || !state.planWritten || state.reviewRequested) return;
    const run = state.run;
    let attempts = 0;
    const attempt = async () => {
      attempts++;
      if (state.run !== run || state.reviewRequested || !isPlanModeActive(ctx) || ctx.getPendingPlanReview()) return;
      if (await ctx.openPlanReview()) {
        logScaffoldFiring("openPlanReview fallback fired on agent_end");
        ctx.ui.notify("backlog-batch: opened plan review", "info");
        return;
      }
      if (attempts < MAX_ATTEMPTS) ctx.setTimeout(attempt, RETRY_MS);
    };
    ctx.setTimeout(attempt, RETRY_MS);
  });
}
