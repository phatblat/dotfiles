const STATUS_EVENTS = {
  busy: "session.status.busy",
  retry: "session.status.retry",
  idle: "session.status.idle",
};

function paseoEventFor(event) {
  if (event?.type === "permission.asked") return "permission.asked";
  if (event?.type === "permission.replied") return "permission.replied";
  if (event?.type !== "session.status") return null;
  return STATUS_EVENTS[event?.properties?.status?.type] ?? null;
}

function runPaseoHook(event) {
  if (!process.env.PASEO_TERMINAL_ID) return;
  try {
    const child = Bun.spawn(["paseo", "hooks", "opencode", event], {
      stdin: "ignore",
      stdout: "ignore",
      stderr: "ignore",
    });
    void child.exited.catch(() => {});
  } catch {}
}

export default async () => ({
  event: async ({ event }) => {
    const paseoEvent = paseoEventFor(event);
    if (paseoEvent) runPaseoHook(paseoEvent);
  },
});
