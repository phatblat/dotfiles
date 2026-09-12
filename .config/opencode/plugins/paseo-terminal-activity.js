const V1_STATUS_EVENTS = {
  busy: "session.status.busy",
  retry: "session.status.retry",
  idle: "session.status.idle",
};

const V2_EVENTS = {
  "session.execution.started": "session.status.busy",
  "session.execution.succeeded": "session.status.idle",
  "session.execution.failed": "session.status.idle",
  "session.execution.interrupted": "session.status.idle",
  "permission.asked": "permission.asked",
  "permission.replied": "permission.replied",
};

function paseoEventForV1(event) {
  const type = event.type;
  if (type === "permission.asked") return "permission.asked";
  if (type === "permission.replied") return "permission.replied";
  if (type !== "session.status") return null;
  return V1_STATUS_EVENTS[event.properties.status.type] ?? null;
}

let pendingHook = Promise.resolve();

function runPaseoHook(event) {
  if (!process.env.PASEO_TERMINAL_ID) return;
  pendingHook = pendingHook.then(async () => {
    try {
      const child = Bun.spawn(["paseo", "hooks", "opencode", event], {
        stdin: "ignore",
        stdout: "ignore",
        stderr: "ignore",
      });
      await child.exited;
    } catch {}
  });
  return pendingHook;
}

export default {
  id: "paseo-terminal-activity",
  server() {
    return {
      event: async ({ event }) => {
        const paseoEvent = paseoEventForV1(event);
        if (paseoEvent) await runPaseoHook(paseoEvent);
      },
    };
  },
  setup(ctx) {
    const controller = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        const paseoEvent = V2_EVENTS[event.type];
        if (paseoEvent) await runPaseoHook(paseoEvent);
      }
    })().catch(() => {});
    return () => controller.abort();
  },
};
