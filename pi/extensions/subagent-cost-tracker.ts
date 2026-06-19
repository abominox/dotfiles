/**
 * Subagent Cost Tracker
 *
 * Extracts token usage and cost from subagent child sessions (both foreground
 * and async) and injects them into the parent session's tracked usage so the
 * status bar reflects the true total.
 *
 * How it works:
 *   - Foreground runs: Subagent results carry `details.results[].usage.cost`
 *     (a flat number). We hook `message_end` for `toolResult` messages from
 *     the `subagent` tool and accumulate that cost.
 *   - Async runs: The `subagent:async-complete` event fires when an async
 *     subagent finishes. The event payload contains `results[].sessionPath`
 *     (the child's .jsonl session file). We parse that file to extract
 *     `usage.cost.total` from each assistant message and accumulate it.
 *   - On the next `assistant` message_end, we drain the accumulated cost
 *     into the parent message's `usage.cost.total`, where pi's session
 *     tracker picks it up for the status bar.
 */

import * as fs from "node:fs";

export default function (pi: ExtensionAPI) {
  const pending = { cost: 0 };

  /* ── helper: parse one child session JSONL for total cost ── */
  function parseChildSessionCost(sessionFile: string): number {
    try {
      const content = fs.readFileSync(sessionFile, "utf-8");
      let total = 0;
      for (const line of content.split("\n")) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        try {
          const entry = JSON.parse(trimmed);
          // Session entries may wrap usage under different keys
          const usage = entry.usage ?? entry.message?.usage;
          if (usage?.cost?.total) {
            total += usage.cost.total;
          }
        } catch {
          // skip malformed lines
        }
      }
      return total;
    } catch {
      return 0;
    }
  }

  /* ── helper: drain pending cost into an assistant message ── */
  function drainIntoMessage(
    msg: Record<string, unknown>,
  ): Record<string, unknown> | undefined {
    if (pending.cost <= 0) return undefined;

    const costToAdd = pending.cost;
    pending.cost = 0;

    const existingUsage = (msg.usage as Record<string, unknown>) ?? {};
    const existingCost = (existingUsage.cost as Record<string, unknown>) ?? {};

    return {
      ...msg,
      usage: {
        ...existingUsage,
        cost: {
          input: (existingCost.input as number) ?? 0,
          output: (existingCost.output as number) ?? 0,
          cacheRead: (existingCost.cacheRead as number) ?? 0,
          cacheWrite: (existingCost.cacheWrite as number) ?? 0,
          total: ((existingCost.total as number) ?? 0) + costToAdd,
        },
      },
    };
  }

  /* ── Foreground: capture cost from subagent tool results ── */
  pi.on("message_end", (event, _ctx) => {
    const msg = event.message as Record<string, unknown>;

    // --- Capture from subagent tool results ---
    if (
      msg.role === "toolResult" &&
      msg.toolName === "subagent"
    ) {
      const details = msg.details as
        | { results?: Array<{ usage?: { cost?: number } }> }
        | undefined;
      if (details?.results) {
        for (const r of details.results) {
          if (r.usage?.cost) {
            pending.cost += r.usage.cost;
          }
        }
      }
      // Do NOT modify the toolResult message itself — it has no cost field.
      return;
    }

    // --- Drain pending cost into assistant messages ---
    if (msg.role === "assistant" && pending.cost > 0) {
      return { message: drainIntoMessage({ ...msg }) };
    }
  });

  /* ── Async: listen for async subagent completions ── */
  const asyncUnsub = pi.events.on(
    "subagent:async-complete" as string,
    (payload: unknown) => {
      const data = payload as {
        results?: Array<{ sessionPath?: string; sessionFile?: string }>;
      };
      const children = data.results ?? [];
      for (const child of children) {
        const sessionFile = child.sessionPath ?? child.sessionFile;
        if (sessionFile && typeof sessionFile === "string") {
          pending.cost += parseChildSessionCost(sessionFile);
        }
      }
    },
  );

  /* ── Cleanup ── */
  pi.on("session_shutdown", () => {
    asyncUnsub();
    pending.cost = 0;
  });
}
