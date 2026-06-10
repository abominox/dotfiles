/**
 * Pure utility functions for plan mode.
 * Extracted for testability and clean separation.
 */

// Destructive command patterns blocked in plan mode
const DESTRUCTIVE_PATTERNS = [
	// File system mutations
	/\brm\b/i,
	/\brmdir\b/i,
	/\bmv\b/i,
	/\bcp\b/i,
	/\bmkdir\b/i,
	/\btouch\b/i,
	/\bchmod\b/i,
	/\bchown\b/i,
	/\bchgrp\b/i,
	/\bln\b/i,
	/\btee\b/i,
	/\btruncate\b/i,
	/\bdd\b/i,
	/\bshred\b/i,
	// Redirection (write)
	/(^|[^<])>(?!>)/,
	/>>/,
	// Package manager mutations
	/\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
	/\byarn\s+(add|remove|install|publish)/i,
	/\bpnpm\s+(add|remove|install|publish)/i,
	/\bpip\s+(install|uninstall)/i,
	/\bnpx\s/i,
	/\bbun\s+(add|remove|install)/i,
	/\bapt(-get)?\s+(install|remove|purge|update|upgrade)/i,
	/\bbrew\s+(install|uninstall|upgrade|update|reinstall)/i,
	// Git mutations
	/\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)/i,
	// System mutations
	/\bsudo\b/i,
	/\bsu\b/i,
	/\bkill\b/i,
	/\bpkill\b/i,
	/\bkillall\b/i,
	/\breboot\b/i,
	/\bshutdown\b/i,
	/\bsystemctl\s+(start|stop|restart|enable|disable)/i,
	/\bservice\s+\S+\s+(start|stop|restart)/i,
	// Editors
	/\b(vim?|nano|emacs|code|subl|nvim)\b/i,
];

// Safe read-only commands allowed in plan mode
const SAFE_PATTERNS = [
	/^\s*cat\b/,
	/^\s*head\b/,
	/^\s*tail\b/,
	/^\s*less\b/,
	/^\s*more\b/,
	/^\s*grep\b/,
	/^\s*fgrep\b/,
	/^\s*egrep\b/,
	/^\s*zgrep\b/,
	/^\s*find\b/,
	/^\s*ls\b/,
	/^\s*pwd\b/,
	/^\s*echo\b/,
	/^\s*printf\b/,
	/^\s*wc\b/,
	/^\s*sort\b/,
	/^\s*uniq\b/,
	/^\s*diff\b/,
	/^\s*file\b/,
	/^\s*stat\b/,
	/^\s*du\b/,
	/^\s*df\b/,
	/^\s*tree\b/,
	/^\s*which\b/,
	/^\s*whereis\b/,
	/^\s*type\b/,
	/^\s*env\b/,
	/^\s*printenv\b/,
	/^\s*uname\b/,
	/^\s*whoami\b/,
	/^\s*id\b/,
	/^\s*date\b/,
	/^\s*cal\b/,
	/^\s*uptime\b/,
	/^\s*ps\b/,
	/^\s*top\b/,
	/^\s*htop\b/,
	/^\s*free\b/,
	/^\s*df\b/,
	/^\s*du\b/,
	// Git read-only
	/^\s*git\s+(status|log|diff|show|branch|remote|config|stash\s+list|stash\s+show)/i,
	/^\s*git\s+ls-/i,
	// Package read-only
	/^\s*npm\s+(list|ls|view|info|search|outdated|audit)/i,
	/^\s*yarn\s+(list|info|why|audit)/i,
	// Tools
	/^\s*node\s+(--version|-e|-p)/i,
	/^\s*python\s+(--version|-c)/i,
	/^\s*curl\s/i,
	/^\s*wget\s/i,
	/^\s*jq\b/,
	/^\s*sed\s+-n/i,
	/^\s*awk\b/,
	/^\s*rg\b/,
	/^\s*fd\b/,
	/^\s*bat\b/,
	/^\s*eza\b/,
	/^\s*glow\b/,
	/^\s*hexdump\b/,
	/^\s*xxd\b/,
	/^\s*od\b/,
	/^\s*strings\b/,
	/^\s*realpath\b/,
	/^\s*readlink\b/,
	/^\s*expr\b/,
	/^\s*test\b/,
	/^\s*\[{2}\s/i,
	/^\s*true\b/,
	/^\s*false\b/,
	/^\s*source\b/,
	/^\s*\.\s+/,
];

/**
 * Check if a bash command is safe (read-only) for plan mode.
 * A command is safe only if it matches a safe pattern AND does NOT match any destructive pattern.
 */
export function isSafeCommand(command: string): boolean {
	const trimmed = (command ?? "").trim();
	if (!trimmed) return false;
	const isDestructive = DESTRUCTIVE_PATTERNS.some((p) => p.test(trimmed));
	const isSafe = SAFE_PATTERNS.some((p) => p.test(trimmed));
	return !isDestructive && isSafe;
}

/**
 * Known mutating tool names to block in plan mode.
 * These are the built-in tools that change files or system state.
 */
export const MUTATING_TOOL_NAMES = new Set([
	"edit",
	"write",
	"create",
	"delete",
	"patch",
	"mcp", // MCP gateway can run arbitrary mutations through server tools
]);

/**
 * Read-only tools allowed in plan mode.
 */
export const PLAN_MODE_TOOLS = ["read", "bash", "grep", "find", "ls"] as const;

/**
 * All tools available in normal mode (default active set).
 */
export const NORMAL_MODE_TOOLS = [
	"read",
	"bash",
	"edit",
	"write",
	"grep",
	"find",
	"ls",
	"mcp",
] as const;
