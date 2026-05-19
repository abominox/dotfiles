/**
 * RTK (Rust Token Killer) Extension
 *
 * Transparently rewrites bash tool commands through `rtk` to compress
 * CLI output by 60–90% before it reaches the LLM context window.
 *
 * On every bash tool call, this extension:
 *   1. Runs `rtk rewrite "<command>"` to check for an RTK equivalent
 *   2. If found, replaces the command with the RTK-optimized version
 *   3. If not found, passes the original command through unchanged
 *
 * rtk automatically strips noise, truncates boilerplate, and compresses
 * output — all transparently, with zero config changes to your workflow.
 *
 * Install: `brew install rtk`
 * Dashboard: run `rtk gain` outside of Pi to see token savings.
 */

import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { createBashTool } from "@earendil-works/pi-coding-agent";

/**
 * Try to rewrite a shell command via `rtk rewrite`.
 * Returns the rewritten command if one exists, or null if rtk has no
 * equivalent (command is passed through unchanged).
 */
function tryRtkRewrite(command: string): string | null {
  try {
    const result = spawnSync("rtk", ["rewrite", command], {
      encoding: "utf-8",
      timeout: 5000,
      // rtk rewrite can exit non-zero (e.g. 3 = no hook installed)
      // but still produce valid output in stdout
      stdio: ["ignore", "pipe", "pipe"],
    });

    const stdout = (result.stdout ?? "").trim();
    if (!stdout) return null;

    // rtk returns the rewritten command on stdout
    // Only use it if it actually changed the command (starts with "rtk "
    // or contains "rtk " in a compound command context)
    if (stdout.startsWith("rtk ") || stdout.includes(" rtk ")) {
      return stdout;
    }

    return null;
  } catch {
    // Fallback: if spawnSync itself throws, run the original command
    return null;
  }
}

export default function (pi: ExtensionAPI) {
  const cwd = process.cwd();

  const bashTool = createBashTool(cwd, {
    spawnHook: ({ command, cwd, env }) => {
      // Skip very short commands (likely simple echo, cd, etc.)
      // Also skip commands starting with 'rtk' (avoid recursive rewriting)
      const trimmed = command.trimStart();
      if (
        trimmed.length < 6 ||
        trimmed.startsWith("rtk ") ||
        trimmed.startsWith("rtk\t") ||
        trimmed.startsWith("#")
      ) {
        return { command, cwd, env };
      }

      // Silence the "no hook installed" hint that rtk prints to stderr
      const rewritten = tryRtkRewrite(command);
      if (rewritten) {
        return {
          command: rewritten,
          cwd,
          env: { ...env, RTK_SILENCE_HINT: "1" },
        };
      }

      return { command, cwd, env };
    },
  });

  pi.registerTool({
    ...bashTool,
    // Override description to mention RTK integration
    description: `Execute a command in the terminal. Commands are transparently routed through rtk (Rust Token Killer) where possible to reduce token consumption by 60-90%.`,
    execute: async (id, params, signal, onUpdate, ctx) => {
      return bashTool.execute(id, params, signal, onUpdate, ctx);
    },
  });
}
