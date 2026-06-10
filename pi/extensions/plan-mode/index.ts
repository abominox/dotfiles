/**
 * Read-Only Mode Extension
 *
 * Toggle-able read-only mode for Pi. When active:
 * - Mutating tools (write, edit, create, etc.) are blocked
 * - Bash commands are restricted to an allowlist of read-only commands
 * - The mode is clearly shown in Pi's footer via setStatus
 * - System prompt tells the LLM it's read-only
 *
 * Does NOT conflict with Plannotator's full planning workflow.
 * This is a simpler "read-only exploration" toggle.
 *
 * Toggle: /readonly command, Ctrl+Alt+R shortcut, or --readonly CLI flag
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { isSafeCommand, MUTATING_TOOL_NAMES, PLAN_MODE_TOOLS } from "./utils.ts";

function updateStatus(ctx: ExtensionContext, enabled: boolean): void {
	if (enabled) {
		// Footer status (may show depending on terminal width and footer config)
		ctx.ui.setStatus(
			"readonly-mode",
			ctx.ui.theme.fg("warning", ctx.ui.theme.bold("⏸ READ ONLY")),
		);

		// Widget banner above the editor (always visible)
		ctx.ui.setWidget("readonly-mode-banner", (_tui, theme) => ({
			render: () => [
				"",
				theme.fg("warning", theme.bold("  🔒 READ ONLY MODE — use /readonly to disable.")),
			],
			invalidate: () => {},
		}));
	} else {
		ctx.ui.setStatus("readonly-mode", undefined);
		ctx.ui.setWidget("readonly-mode-banner", undefined);
	}
}

export default function planModeExtension(pi: ExtensionAPI): void {
	let planModeEnabled = false;
	let previousTools: string[] = [];

	// ── CLI flag ──────────────────────────────────────────────────────────
	// Using --readonly to avoid conflict with Plannotator's --plan flag
	pi.registerFlag("readonly", {
		description: "Start in read-only mode. Blocks all mutating tools and commands.",
		type: "boolean",
		default: false,
	});

	// ── Toggle function ───────────────────────────────────────────────────
	function togglePlanMode(ctx: ExtensionContext): void {
		planModeEnabled = !planModeEnabled;

		if (planModeEnabled) {
			// Save current tools so we can restore them when exiting plan mode
			previousTools = pi.getActiveTools().map((t) => t.name);
			pi.setActiveTools([...PLAN_MODE_TOOLS]);
			ctx.ui.notify(
				`Read-only mode ON — tools restricted to: ${PLAN_MODE_TOOLS.join(", ")}`,
				"warning",
			);
		} else {
			// Restore the tools that were active before plan mode was enabled
			const restoreTools =
				previousTools.length > 0 ? previousTools : undefined;
			previousTools = [];
			if (restoreTools) {
				pi.setActiveTools(restoreTools);
			} else {
				// Fallback: re-enable all tools
				pi.setActiveTools(pi.getAllTools().map((t) => t.name));
			}
			ctx.ui.notify("Read-only mode OFF — full access restored.", "info");
		}

		updateStatus(ctx, planModeEnabled);
		persistState();
	}

	function persistState(): void {
		pi.appendEntry("readonly-mode-state", { enabled: planModeEnabled });
	}

	// ── /readonly command ────────────────────────────────────────────────
	pi.registerCommand("readonly", {
		description: "Toggle read-only mode. Blocks all mutating tools and commands.",
		handler: async (_args, ctx) => togglePlanMode(ctx),
	});

	// ── Ctrl+Alt+R shortcut ──────────────────────────────────────────────
	// Uses Ctrl+Alt+R (r for readonly) to avoid conflict with Plannotator's Ctrl+Alt+P
	pi.registerShortcut(Key.ctrlAlt("r"), {
		description: "Toggle read-only mode",
		handler: async (ctx) => togglePlanMode(ctx),
	});

	// ── Block mutating tools at execution time ────────────────────────────
	pi.on("tool_call", async (event, ctx) => {
		if (!planModeEnabled) return;

		const toolName = event.toolName;

		// Block known mutating tools by name
		if (MUTATING_TOOL_NAMES.has(toolName)) {
			return {
				block: true,
				reason: `Read-only mode: the "${toolName}" tool is blocked. Use /readonly to disable first.`,
			};
		}

		// For bash, check command safety against the allowlist
		if (toolName === "bash") {
			const command = event.input?.command;
			if (typeof command !== "string" || !isSafeCommand(command)) {
				return {
					block: true,
					reason: [
						`Read-only mode: this command is blocked because it could mutate files or system state.`,
						`Use /readonly to disable read-only mode first.`,
						`Command: ${String(command)}`,
					].join("\n"),
				};
			}
		}
	});

	// ── Inject system prompt context ──────────────────────────────────────
	pi.on("before_agent_start", async (event) => {
		if (!planModeEnabled) return;

		return {
			systemPrompt:
				event.systemPrompt +
				[
					"",
					"## READ-ONLY MODE ACTIVE",
					"",
					"You are in Read-Only Mode — safe code analysis only.",
					"",
					"Restrictions:",
					"- You can ONLY use: read, bash, grep, find, ls",
					"- write, edit, create, delete, and mcp are BLOCKED",
					"- Bash commands are restricted to read-only commands",
					"- You CANNOT modify files, create files, or run destructive commands",
					"",
					"Analyze and describe what changes would be needed — do NOT make them.",
					"",
				].join("\n"),
		};
	});

	// ── Restore state on session start ────────────────────────────────────
	pi.on("session_start", async (_event, ctx) => {
		const flagEnabled = pi.getFlag("readonly") === true;

		// Restore persisted state if no flag was explicitly passed
		if (!flagEnabled) {
			const entries = ctx.sessionManager.getEntries();
			const stateEntry = [...entries]
				.reverse()
				.find(
					(e) =>
						typeof e === "object" &&
						"type" in e &&
						e.type === "custom" &&
						"customType" in e &&
					e.customType === "readonly-mode-state",
				) as { data?: { enabled: boolean } } | undefined;

			if (stateEntry?.data) {
				planModeEnabled = stateEntry.data.enabled;
			}
		} else {
			planModeEnabled = true;
		}

		// Apply the state — and save the full tool list BEFORE restricting
		if (planModeEnabled) {
			previousTools = pi.getActiveTools().map((t) => t.name);
			if (previousTools.length === 0) {
				previousTools = pi.getAllTools().map((t) => t.name);
			}
			pi.setActiveTools([...PLAN_MODE_TOOLS]);
		}

		// Mark widget/status for update at first opportunity
		// Use a simple setStatus (minimal API surface) to avoid crashes during startup
		try {
			if (planModeEnabled) {
				ctx.ui.setStatus("readonly-mode", ctx.ui.theme.fg("warning", ctx.ui.theme.bold("⏸ READ ONLY")));
			}
		} catch {
			// UI not ready during early startup — safe to ignore
		}
	});
}