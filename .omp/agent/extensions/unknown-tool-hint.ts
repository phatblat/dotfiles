// unknown-tool-hint.ts — surfaces the correct tool name/URI form on the
// model's *first* miss instead of letting it retry blind.
//
// Evidence (30-day OMP session scan, 2026-08-25): underscore-prefixed native
// tool guesses (_bash, _read, _eval, _edit, _todo), case-typo'd native names
// (Bash, Read), and malformed MCP-device invocations (xd_bash, xd_edit,
// ctx_execute called directly instead of through an `xd://` path) each failed
// 100% of the time across every attempt observed, with no self-correction
// between attempts. This blocks each miss before it burns a real tool-call
// turn and tells the model the exact fix.
import type { ExtensionAPI } from "@oh-my-pi/pi-coding-agent";

// Curated fallback in case getAllTools() has not populated yet when a very
// early tool_call fires; getAllTools() (live registry) is always preferred.
const FALLBACK_NATIVE_TOOLS = [
  "bash", "read", "edit", "write", "grep", "glob", "task", "hub", "todo",
  "ask", "eval", "web_search", "learn", "manage_skill", "yield",
];

function levenshtein(a: string, b: string): number {
  const m = a.length;
  const n = b.length;
  const dp: number[][] = Array.from({ length: m + 1 }, () => new Array(n + 1).fill(0));
  for (let i = 0; i <= m; i++) dp[i][0] = i;
  for (let j = 0; j <= n; j++) dp[0][j] = j;
  for (let i = 1; i <= m; i++) {
    for (let j = 1; j <= n; j++) {
      dp[i][j] = a[i - 1] === b[j - 1]
        ? dp[i - 1][j - 1]
        : 1 + Math.min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
    }
  }
  return dp[m][n];
}

function bestMatch(name: string, registry: string[]): string | undefined {
  const lower = name.toLowerCase();
  let best: string | undefined;
  let bestDist = 3; // small window only; a wild guess is worse than no hint
  for (const candidate of registry) {
    const d = levenshtein(lower, candidate.toLowerCase());
    if (d < bestDist) {
      bestDist = d;
      best = candidate;
    }
  }
  return best;
}

export default function unknownToolHint(pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    const toolName = event.toolName;
    let registry: string[] = FALLBACK_NATIVE_TOOLS;
    try {
      const all = pi.getAllTools?.();
      if (Array.isArray(all) && all.length > 0) {
        registry = all.map((t: { name: string }) => t.name);
      }
    } catch {
      // getAllTools unavailable this early in lifecycle; use the fallback list.
    }

    if (registry.includes(toolName)) return; // known tool, nothing to do

    const lower = toolName.toLowerCase();
    const strippedUnderscore = lower.replace(/^_+/, "");
    if (strippedUnderscore !== lower && registry.includes(strippedUnderscore)) {
      return {
        block: true,
        reason:
          `Unknown tool '${toolName}'. Did you mean '${strippedUnderscore}'? ` +
          `(no leading underscore)`,
      };
    }

    if (/^xd_+/.test(lower) || /^ctx_/.test(lower) || /^mcp__/.test(lower)) {
      return {
        block: true,
        reason:
          `Unknown tool '${toolName}'. MCP/device tools are not called directly by ` +
          `name — write JSON args to the path 'xd://<tool>' using the 'write' tool ` +
          `(e.g. write to "xd://mcp__context_mode_ctx_execute"), or read 'xd://<tool>' ` +
          `first to see its schema.`,
      };
    }

    const hint = bestMatch(toolName, registry);
    if (hint) {
      return {
        block: true,
        reason: `Unknown tool '${toolName}'. Did you mean '${hint}'?`,
      };
    }

    // No confident guess — let the normal "unknown tool" failure surface
    // unmodified rather than block on a low-confidence hint.
    return;
  });
}
