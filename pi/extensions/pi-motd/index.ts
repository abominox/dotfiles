/**
 * Pi MOTD Extension
 *
 * Displays a Message of the Day on Pi startup, showing:
 * - Agent name + extension/skill counts
 * - Available skills list
 * - Rotating tip of the day
 *
 * Install in ~/.pi/agent/extensions/pi-motd/
 * (auto-discovered by Pi at startup)
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { readFileSync, readdirSync, existsSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

// ─── Header ──────────────────────────────────────────────────────────────────

const PI_HEADER = `╭──────────────────────────╮
│  🥧  —  Pi Coding Agent  │
╰──────────────────────────╯`;

// ─── Skill Discovery ─────────────────────────────────────────────────────────

interface SkillInfo {
	name: string;
	description: string;
}

/** Built-in skills that ship with Pi and shouldn't clutter the MOTD. */
const BUILT_IN_SKILLS = new Set([
	"extending-pi",
	"skill-creator",
]);

/**
 * Parse YAML frontmatter from a SKILL.md file.
 * Returns { name, description } or null.
 * Handles single-line and multi-line (|) YAML descriptions.
 */
function parseSkillMd(filePath: string): SkillInfo | null {
	try {
		const content = readFileSync(filePath, "utf-8");

		// Extract frontmatter between --- markers
		const match = content.match(/^---\n([\s\S]*?)\n---/);
		if (!match) return null;

		const frontmatter = match[1];
		const name = frontmatter.match(/^name:\s*(.+)$/m)?.[1]?.trim();
		if (!name) return null;

		// Try single-line description first
		let description = frontmatter.match(/^description:\s*(.+)$/m)?.[1]?.trim();

		// If description wasn't found or starts with | (block scalar), parse multi-line
		if (!description || description === "|") {
			const lines = frontmatter.split("\n");
			let inBlock = false;
			const blockLines: string[] = [];
			for (const line of lines) {
				if (line.trimStart().startsWith("description:")) {
					inBlock = true;
					continue;
				}
				if (inBlock) {
					// A block scalar line starts with at least 2 spaces (indented)
					if (/^\s{2,}/.test(line)) {
						blockLines.push(line.trim());
					} else {
						break;
					}
				}
			}
			if (blockLines.length > 0) description = blockLines.join(" ");
		}

		if (!description) return null;
		return { name, description };
	} catch {
		return null;
	}
}

/**
 * Scan a directory for SKILL.md files (recursive) or standalone .md files.
 */
function scanSkillDir(baseDir: string): SkillInfo[] {
	const skills: SkillInfo[] = [];

	try {
		if (!existsSync(baseDir)) return skills;

		const entries = readdirSync(baseDir, { withFileTypes: true });

		for (const entry of entries) {
			const fullPath = join(baseDir, entry.name);

			if (entry.isDirectory() || entry.isSymbolicLink()) {
				// For symlinks, stat to check if it's a directory
				try {
					const stat = statSync(fullPath);
					if (!stat.isDirectory()) continue;
				} catch {
					continue;
				}
				// Directory-based skill: look for SKILL.md inside
				const skillFile = join(fullPath, "SKILL.md");
				if (existsSync(skillFile)) {
					const info = parseSkillMd(skillFile);
					if (info) skills.push(info);
				}
			} else if (entry.isFile() && entry.name.endsWith(".md") && entry.name !== "README.md") {
				// Flat-file skill
				const info = parseSkillMd(fullPath);
				if (info) skills.push(info);
			}
		}
	} catch {
		// skip unreadable dirs
	}

	return skills;
}

/**
 * Discover all installed skills across all known skill locations.
 */
function discoverSkills(): SkillInfo[] {
	const seen = new Set<string>();
	const all: SkillInfo[] = [];

	const scanAndDedup = (dir: string) => {
		for (const skill of scanSkillDir(dir)) {
			if (!seen.has(skill.name) && !BUILT_IN_SKILLS.has(skill.name)) {
				seen.add(skill.name);
				all.push(skill);
			}
		}
	};

	const home = homedir();

	// Standard global locations
	scanAndDedup(join(home, ".pi", "agent", "skills"));
	scanAndDedup(join(home, ".agents", "skills"));

	// Package-based skills (e.g. from pi install)
	const gitSkillsDir = join(home, ".pi", "agent", "git");
	if (existsSync(gitSkillsDir)) {
		const walkDir = (dir: string) => {
			try {
				const entries = readdirSync(dir, { withFileTypes: true });
				for (const entry of entries) {
					const fullPath = join(dir, entry.name);
					if (entry.name.startsWith(".")) continue; // skip hidden
					if (entry.isDirectory() || entry.isSymbolicLink()) {
						// Check if this directory itself contains SKILL.md (any dir, not just "skills")
						const skillFile = join(fullPath, "SKILL.md");
						if (existsSync(skillFile)) {
							for (const s of scanSkillDir(fullPath)) {
								if (!seen.has(s.name) && !BUILT_IN_SKILLS.has(s.name)) {
									seen.add(s.name);
									all.push(s);
								}
							}
						} else {
							// Otherwise recurse deeper
							walkDir(fullPath);
						}
					}
				}
			} catch {
				// skip
			}
		};
		walkDir(gitSkillsDir);
	}

	// npm packaged skills
	const npmSkillsDir = join(home, ".pi", "agent", "npm", "node_modules");
	if (existsSync(npmSkillsDir)) {
		const entries = readdirSync(npmSkillsDir, { withFileTypes: true });
		for (const entry of entries) {
			if (entry.isDirectory()) {
				const pkgSkillsDir = join(npmSkillsDir, entry.name, "skills");
				if (existsSync(pkgSkillsDir)) {
					for (const s of scanSkillDir(pkgSkillsDir)) {
						if (!seen.has(s.name)) {
							seen.add(s.name);
							all.push(s);
						}
					}
				}
			}
		}
	}

	return all;
}

// ─── Tips ────────────────────────────────────────────────────────────────────

const TIPS = [
	"Use /tree to browse and navigate session history.",
	"Fork any point in history with /fork.",
	"Resume previous sessions with /resume.",
	"Toggle read-only mode with Ctrl+Alt+R.",
	"Load a skill on demand with /skill:name.",
	"Compact your session with /compact to save tokens.",
	"Switch models mid-session with /model.",
	"Swap between sessions with Ctrl+O.",
	"Reference files with @filename to add them to context.",
	"Run a bash command directly with !command.",
	"Use /settings to configure Pi's behavior.",
	"Pin an entry with a label using /label name.",
	"Clone the current thread to a new session with /clone.",
	"Rename your session with /session-name.",
	"Chain sub-agents for complex multi-step tasks.",
];

function pickTip(): string {
	const dayIndex = new Date().getDate();
	return TIPS[dayIndex % TIPS.length];
}

// ─── Extension Discovery ─────────────────────────────────────────────────────

function discoverExtensions(): string[] {
	const home = homedir();
	const extDir = join(home, ".pi", "agent", "extensions");
	const names: string[] = [];
	try {
		const entries = readdirSync(extDir, { withFileTypes: true });
		for (const entry of entries) {
			const fullPath = join(extDir, entry.name);
			if (entry.isDirectory() || entry.isSymbolicLink()) {
				try {
					const stat = statSync(fullPath);
					if (stat.isDirectory() && existsSync(join(fullPath, "index.ts"))) {
						names.push(entry.name);
					}
				} catch { /* skip */ }
			} else if (entry.isFile() && entry.name.endsWith(".ts")) {
				const base = entry.name.replace(/\.ts$/, "");
				names.push(base);
			}
		}
	} catch { /* skip */ }
	return names.sort();
}

// ─── MOTD Builder ────────────────────────────────────────────────────────────

function formatMOTD(skills: SkillInfo[], extensions: string[]): string {
	const lines: string[] = [];

	lines.push("");
	lines.push(PI_HEADER);
	lines.push("");
	lines.push("  ────────────────────────────────────────────");
	lines.push("");
	lines.push(`  🔌  ${extensions.length} extension(s) loaded  ·  ${skills.length} skill(s) available`);
	lines.push("");

	if (extensions.length > 0) {
		lines.push(`  🔩  Extensions: ${extensions.join(", ")}`);
		lines.push("");
	}

	if (skills.length > 0) {
		lines.push("  📦  Skills:");

		// Show up to 8 skills, then summarize the rest
		const visible = skills.slice(0, 8);
		const remaining = skills.length - visible.length;

		for (const skill of visible) {
			const desc = skill.description.length > 60
				? skill.description.slice(0, 57) + "..."
				: skill.description;
			lines.push(`       • ${skill.name.padEnd(18)} ${desc}`);
		}

		if (remaining > 0) {
			lines.push(`       • ... and ${remaining} more`);
		}

		lines.push("");
	} else {
		lines.push("  ℹ️  No skills installed. Add some to ~/.pi/agent/skills/");
		lines.push("");
	}

	lines.push(`  💡  Tip: ${pickTip()}`);
	lines.push("");

	return lines.join("\n");
}

// ─── Extension Entry Point ───────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	// Track whether we've shown the MOTD this session.
	// session_start fires on startup, /new, /resume, /fork, /reload.
	let shown = false;

	pi.on("session_start", async (event, ctx) => {
		// Only show on initial startup, not on /new, /resume, /fork, /reload
		if (event.reason !== "startup" || shown) return;
		shown = true;

		try {
			const skills = discoverSkills();
			const extensions = discoverExtensions();
			const motd = formatMOTD(skills, extensions);

			if (ctx.hasUI) {
				// In TUI/RPC mode, use notify for a clean notification
				ctx.ui.notify(motd, "info");
			} else {
				// In print/JSON mode, write to stderr so it doesn't interfere with output
				console.error(motd);
			}
		} catch (err) {
			// If something goes wrong, don't crash Pi
			console.error("[pi-motd] Error generating MOTD:", err);
		}
	});

	// Reset flag on shutdown so next process start shows it again
	pi.on("session_shutdown", async (_event) => {
		shown = false;
	});
}
