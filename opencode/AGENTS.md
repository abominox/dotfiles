# OpenCode Agent Policy

This policy applies to the primary agent. If you are a subagent, ignore the
fan-out instructions and complete the task you were launched with.

## Delegation

Long-horizon work should be decomposed. Use subagents to isolate context and
parallelize independent work. Do not delegate trivial tasks, and do not wrap a
single command in a subagent just to avoid running it yourself. If your agent
configuration denies the `subagent` action, do the work inline instead of
retrying.

### Roles

- `explore` — read-only codebase scout. Use it before editing unfamiliar code,
  or fan out one per subsystem/directory when mapping a large codebase.
- `researcher` — web research with citations. Use it for current information,
  source verification, or broad research; do not duplicate it with inline
  searches.
- `general` — independent multi-step worker with full tools. Use it for a
  self-contained implementation, investigation, or verification workstream.
- `reviewer` — read-only review of a diff or implementation. Use it after
  non-trivial changes, before declaring the work done.
- `oracle` — read-only architecture/design adviser. Use it before a non-trivial
  implementation when the approach, risks, or trade-offs are unclear.

### When to fan out

- **Unfamiliar codebase or subsystem:** spawn 2–4 `explore` agents, one per
  subsystem or directory, before reading files sequentially.
- **Independent workstreams:** spawn one `general` per workstream (default cap:
  4 concurrent children).
- **Non-trivial implementation:** run `oracle` before implementing if the
  approach is uncertain; run `reviewer` after implementing.
- **Broad research:** use `researcher`, one per question cluster.
- **Multiple review angles:** spawn separate `reviewer` children for different
  concerns (correctness, security, tests) rather than one giant review.

### How to launch

- Issue several `subagent` calls in one turn for parallel work. Foreground
  calls are best when you will synthesize the results in the same turn;
  `background: true` is for long-running side work that can finish later.
- Give every child a complete, self-contained prompt: goal, relevant
  paths/context, constraints, expected output, and what not to do. Children
  start with fresh context.
- Keep fan-out one level deep. Children cannot launch subagents by default; do
  not ask them to. Reuse a child with its `sessionID` for follow-ups instead of
  spawning a new one.
- Do not delegate a task that is only "run this command and report the output."
  Use the shell or `execute` directly. Delegate when judgment or context
  isolation is the point.

### Parallel write safety

- Read-only fan-out is preferred.
- For parallel edits, isolate each writer in its own worktree, or assign
  explicit, disjoint file ownership. Never let two children edit the same files.
- The parent owns integration, final edits, conflict resolution, and final
  verification.

### Synthesis and completion

- When you fan out for independent facts, wait for all children before
  synthesizing. Do not re-summarize after each return; that wastes context and
  produces an unstable picture.
- Treat child output as evidence, not truth. Check important claims against the
  repository or primary sources.
- A non-trivial implementation is not complete until a `reviewer` has reviewed
  it and the relevant tests/builds have run. Resolve or explicitly document
  every blocking finding.
- If a child fails, stalls, or returns shallow work, inspect its session, then
  retry with a narrower prompt or finish the task inline. Do not silently ignore
  it.
- Report what was delegated, what came back, and what the parent verified.

### Reference pattern

1. `explore` fan-out (2–4) → synthesize a map.
2. `oracle` if the approach is unclear → choose a plan.
3. Implement directly, or split independent work across `general` children
   with disjoint file ownership.
4. Run the relevant tests/builds.
5. `reviewer` → fix blocking findings → re-review if needed.

### Cost and models

- Children inherit the parent's model unless their agent configuration pins one.
  `reviewer` and `oracle` pin a stronger DeepSeek Pro model by default; change
  their `model` field if you prefer another provider.
- Keep prompts specific. A vague child burns tokens and returns noise.
