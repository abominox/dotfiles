/**
 * Pi MOTD Extension
 *
 * Displays a Message of the Day on Pi startup, showing:
 * - Boxed agent name with Pi version
 * - Extension count + names
 * - Skill names
 * - Current working directory
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

const PI_HEADER = `╔══════════════════════════════╗
║       🥧  Pi Coding Agent     ║
╚══════════════════════════════╝`;

// ─── Pi Version ──────────────────────────────────────────────────────────────

let piVersion: string | null = null;

function getPiVersion(): string {
	if (piVersion) return piVersion;

	const candidates = [
		"/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/package.json",
		"/usr/local/lib/node_modules/@earendil-works/pi-coding-agent/package.json",
		"/usr/lib/node_modules/@earendil-works/pi-coding-agent/package.json",
		join(homedir(), ".local", "share", "fnm", "default", "lib", "node_modules", "@earendil-works", "pi-coding-agent", "package.json"),
	];

	for (const pkgPath of candidates) {
		try {
			if (existsSync(pkgPath)) {
				const pkg = JSON.parse(readFileSync(pkgPath, "utf-8"));
				if (pkg.version) {
					piVersion = pkg.version;
					return piVersion;
				}
			}
		} catch { /* skip */ }
	}

	piVersion = "?";
	return piVersion;
}

// ─── Skill Discovery ─────────────────────────────────────────────────────────

interface SkillInfo {
	name: string;
	description: string;
}

const BUILT_IN_SKILLS = new Set(["extending-pi", "skill-creator"]);

function parseSkillMd(filePath: string): SkillInfo | null {
	try {
		const content = readFileSync(filePath, "utf-8");
		const match = content.match(/^---\n([\s\S]*?)\n---/);
		if (!match) return null;

		const frontmatter = match[1];
		const name = frontmatter.match(/^name:\s*(.+)$/m)?.[1]?.trim();
		if (!name) return null;

		let desc = frontmatter.match(/^description:\s*(.+)$/m)?.[1]?.trim();
		if (!desc || desc === "|") {
			const lines = frontmatter.split("\n");
			let inBlock = false;
			const block: string[] = [];
			for (const line of lines) {
				if (line.trimStart().startsWith("description:")) { inBlock = true; continue; }
				if (inBlock) {
					if (/^\s{2,}/.test(line)) block.push(line.trim());
					else break;
				}
			}
			if (block.length > 0) desc = block.join(" ");
		}
		if (!desc) return null;
		return { name, description: desc };
	} catch { return null; }
}

function scanSkillDir(baseDir: string): SkillInfo[] {
	const skills: SkillInfo[] = [];
	try {
		if (!existsSync(baseDir)) return skills;
		for (const e of readdirSync(baseDir, { withFileTypes: true })) {
			const fp = join(baseDir, e.name);
			if (e.isDirectory() || e.isSymbolicLink()) {
				try { if (!statSync(fp).isDirectory()) continue; } catch { continue; }
				const sf = join(fp, "SKILL.md");
				if (existsSync(sf)) { const i = parseSkillMd(sf); if (i) skills.push(i); }
			} else if (e.isFile() && e.name.endsWith(".md") && e.name !== "README.md") {
				const i = parseSkillMd(fp); if (i) skills.push(i);
			}
		}
	} catch { /* skip */ }
	return skills;
}

function discoverSkills(): SkillInfo[] {
	const seen = new Set<string>();
	const all: SkillInfo[] = [];
	const home = homedir();
	const add = (s: SkillInfo) => { if (!seen.has(s.name) && !BUILT_IN_SKILLS.has(s.name)) { seen.add(s.name); all.push(s); } };
	const scan = (dir: string) => { for (const s of scanSkillDir(dir)) add(s); };

	scan(join(home, ".pi", "agent", "skills"));
	scan(join(home, ".agents", "skills"));

	const gitDir = join(home, ".pi", "agent", "git");
	if (existsSync(gitDir)) {
		const walk = (dir: string) => {
			try {
				for (const e of readdirSync(dir, { withFileTypes: true })) {
					if (e.name.startsWith(".")) continue;
					const fp = join(dir, e.name);
					if (e.isDirectory() || e.isSymbolicLink()) {
						if (existsSync(join(fp, "SKILL.md"))) { for (const s of scanSkillDir(fp)) add(s); }
						else walk(fp);
					}
				}
			} catch { /* skip */ }
		};
		walk(gitDir);
	}

	const npmDir = join(home, ".pi", "agent", "npm", "node_modules");
	if (existsSync(npmDir)) {
		for (const e of readdirSync(npmDir, { withFileTypes: true })) {
			if (e.isDirectory()) {
				const sd = join(npmDir, e.name, "skills");
				if (existsSync(sd)) { for (const s of scanSkillDir(sd)) add(s); }
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
	return TIPS[new Date().getDate() % TIPS.length];
}

// ─── Extension Discovery ─────────────────────────────────────────────────────

function discoverExtensions(): string[] {
	const home = homedir();
	const names: string[] = [];

	try {
		for (const e of readdirSync(join(home, ".pi", "agent", "extensions"), { withFileTypes: true })) {
			const fp = join(home, ".pi", "agent", "extensions", e.name);
			if (e.isDirectory() || e.isSymbolicLink()) {
				try { if (statSync(fp).isDirectory() && existsSync(join(fp, "index.ts"))) names.push(e.name); } catch { /* skip */ }
			} else if (e.isFile() && e.name.endsWith(".ts")) {
				names.push(e.name.replace(/\.ts$/, ""));
			}
		}
	} catch { /* skip */ }

	const npmDir = join(home, ".pi", "agent", "npm", "node_modules");
	try {
		const walk = (dir: string) => {
			let entries: string[] = [];
			try { entries = readdirSync(dir); } catch { return; }
			for (const e of entries) {
				const fp = join(dir, e);
				const pj = join(fp, "package.json");
				try {
					if (existsSync(pj)) {
						const pkg = JSON.parse(readFileSync(pj, "utf-8"));
						if (pkg.pi?.extensions) {
							const displayName = (pkg.name || e).includes("/") ? (pkg.name || e).split("/").pop()! : (pkg.name || e);
							const es = Array.isArray(pkg.pi.extensions) ? pkg.pi.extensions : [pkg.pi.extensions];
							for (const ext of es) {
								if (typeof ext === "string" && (existsSync(join(fp, ext, "index.ts")) || (existsSync(join(fp, ext)) && statSync(join(fp, ext)).isFile() && ext.endsWith(".ts")))) {
									names.push(displayName);
									break;
								}
							}
						}
					}
					if (e.startsWith("@")) walk(fp);
				} catch { /* skip */ }
			}
		};
		walk(npmDir);
	} catch { /* skip */ }

	return [...new Set(names)].sort();
}

// ─── Word Wrap Helper ────────────────────────────────────────────────────────

function wrapCommaList(items: string[], maxLen: number, prefix: string): string[] {
	const text = items.join(", ");
	const result: string[] = [];
	let remaining = text;
	let first = true;
	const indent = "  ".repeat(5); // fixed 10-space indent for continuation lines

	while (remaining.length > 0) {
		const pad = first ? prefix : indent;
		const budget = maxLen - pad.length;

		if (remaining.length <= budget) {
			result.push(pad + remaining);
			break;
		}

		let cut = remaining.lastIndexOf(", ", budget);
		if (cut < 1) cut = budget;
		result.push(pad + remaining.slice(0, cut));
		remaining = remaining.slice(cut + 2);
		first = false;
	}
	return result;
}

// ─── MOTD Builder ────────────────────────────────────────────────────────────

function formatMOTD(skills: SkillInfo[], extensions: string[], cwd: string): string {
	const lines: string[] = [];
	const version = getPiVersion();
	const projectName = cwd.split("/").pop() || "";
	const maxLen = 120;

	lines.push("");
	lines.push(PI_HEADER);
	lines.push(`  ═════════  v${version}  ·  ${projectName}  ═════════`);
	lines.push("");

	if (extensions.length > 0) {
		lines.push(...wrapCommaList(extensions, maxLen, "  🔌  Extensions: "));
		lines.push("");
	}

	if (skills.length > 0) {
		lines.push(...wrapCommaList(skills.map(s => s.name), maxLen, "  📦  Skills: "));
		lines.push("");
	}

	lines.push(`  💡  ${pickTip()}`);
	lines.push("");

	return lines.join("\n");
}

// ─── Extension Entry Point ───────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
	let shown = false;
	getPiVersion();

	pi.on("session_start", async (event, ctx) => {
		if (event.reason !== "startup" || shown) return;
		shown = true;

		try {
			const skills = discoverSkills();
			const extensions = discoverExtensions();
			const motd = formatMOTD(skills, extensions, ctx.cwd);

			if (ctx.hasUI) {
				ctx.ui.notify(motd, "info");
			} else {
				console.error(motd);
			}
		} catch (err) {
			console.error("[pi-motd] Error generating MOTD:", err);
		}
	});

	pi.on("session_shutdown", async () => {
		shown = false;
	});
}