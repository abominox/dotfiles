/**
 * Ask Mode Lockdown Extension
 *
 * When the /ask prompt template is active, restricts tools to read-only:
 * - Allowed: read, grep, find, ls (file reads)
 * - Allowed: bash with curl (web requests only, no output redirection)
 * - Blocked: write, edit (no mutations)
 * - Blocked: bash without curl, or curl with write redirection
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";

/** Set to true when /ask mode is detected */
let askModeActive = false;

/**
 * Check if a command contains curl and no write redirection.
 * Write patterns blocked: >, >>, | tee, curl -o, curl --output, curl -O, curl --remote-name
 */
function isSafeCurlCommand(cmd: string): boolean {
	const trimmed = cmd.trim();

	// Must be a curl command
	if (!trimmed.includes("curl")) return false;

	// Block output redirection
	const writePatterns = [
		">>",    // append redirection (check before >)
		">",     // overwrite redirection
		"| tee", // tee writes to file
		" -o ",  // curl output flag
		"--output",
		" -O",   // curl remote-name flag (space-prefixed to avoid matching -O in URLs)
		"--remote-name",
	];
	for (const pat of writePatterns) {
		if (trimmed.includes(pat)) return false;
	}

	return true;
}

export default function (pi: ExtensionAPI) {
	// Detect /ask mode by checking for the template's marker heading
	pi.on("before_agent_start", async (event) => {
		askModeActive = event.prompt.includes("## /ask Mode — Rules");
	});

	// Block disallowed tools when in /ask mode
	pi.on("tool_call", async (event, ctx) => {
		if (!askModeActive) return;

		// Block all file write operations
		if (isToolCallEventType("write", event) || isToolCallEventType("edit", event)) {
			ctx.ui?.notify?.("Blocked write operation in /ask mode", "warning");
			return { block: true, reason: "Write operations are disabled in /ask mode" };
		}

		// For bash, only allow curl commands without output redirection
		if (isToolCallEventType("bash", event)) {
			const cmd = event.input.command;
			if (!isSafeCurlCommand(cmd)) {
				ctx.ui?.notify?.("Blocked non-curl command in /ask mode", "warning");
				return {
					block: true,
					reason:
						"In /ask mode, only curl commands (web requests) without output " +
						"redirection are allowed. Use curl to fetch documentation or make API calls.",
				};
			}
		}

		// read, grep, find, ls — allowed by default (fall through)
	});
}