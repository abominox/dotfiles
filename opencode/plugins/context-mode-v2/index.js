/**
 * OpenCode V2 bridge for context-mode.
 *
 * context-mode currently publishes the OpenCode adapter using the V1
 * `{ id, server }` plugin shape. OpenCode 2.x requires a V2 `{ id, setup }`
 * definition, so this adapter translates the existing tools and hooks into
 * the V2 plugin domains without running a second MCP process.
 */

import { existsSync } from "node:fs"
import { homedir } from "node:os"
import { dirname, join, resolve } from "node:path"
import { pathToFileURL } from "node:url"

const contextModeRoots = [
  process.env.CONTEXT_MODE_PACKAGE_DIR,
  join(homedir(), ".npm-global", "lib", "node_modules", "context-mode"),
  join(homedir(), ".bun", "install", "global", "node_modules", "context-mode"),
].filter(Boolean)

function findContextModeRoot() {
  const root = contextModeRoots.find((candidate) =>
    existsSync(join(candidate, "build", "adapters", "opencode", "plugin.js")),
  )

  if (!root) {
    throw new Error(
      "context-mode package not found; set CONTEXT_MODE_PACKAGE_DIR to its installation directory",
    )
  }

  return resolve(root)
}

async function loadContextMode() {
  const root = findContextModeRoot()
  const pluginPath = join(root, "build", "adapters", "opencode", "plugin.js")
  const serverPath = join(root, "build", "server.js")
  const zodJsonSchemaCandidates = [
    join(root, "node_modules", "zod-to-json-schema", "dist", "esm", "index.js"),
    join(dirname(root), "zod-to-json-schema", "dist", "esm", "index.js"),
  ]
  const zodJsonSchemaPath = zodJsonSchemaCandidates.find((candidate) => existsSync(candidate))
  if (!zodJsonSchemaPath) {
    throw new Error("context-mode dependency zod-to-json-schema was not found")
  }

  const previousEmbeddedFlag = process.env.CONTEXT_MODE_EMBEDDED_PLUGIN_TOOLS
  process.env.CONTEXT_MODE_EMBEDDED_PLUGIN_TOOLS = "1"

  try {
    const [plugin, server, schema] = await Promise.all([
      import(pathToFileURL(pluginPath).href),
      import(pathToFileURL(serverPath).href),
      import(pathToFileURL(zodJsonSchemaPath).href),
    ])

    return {
      plugin,
      server,
      zodToJsonSchema: schema.zodToJsonSchema ?? schema.default,
    }
  } finally {
    if (previousEmbeddedFlag === undefined) {
      delete process.env.CONTEXT_MODE_EMBEDDED_PLUGIN_TOOLS
    } else {
      process.env.CONTEXT_MODE_EMBEDDED_PLUGIN_TOOLS = previousEmbeddedFlag
    }
  }
}

function textFromResult(result) {
  if (typeof result === "string") return result
  if (result && typeof result.output === "string") return result.output
  if (result === undefined) return ""
  return JSON.stringify(result)
}

function textFromSystemPart(part) {
  if (typeof part === "string") return part
  if (part && typeof part.text === "string") return part.text
  return JSON.stringify(part ?? "")
}

function asSystemParts(system) {
  return system.map((text) => ({ type: "text", text: String(text) }))
}

function inputSchemaFor(registered, zodToJsonSchema) {
  try {
    const schema = zodToJsonSchema(registered.config.inputSchema, {
      target: "jsonSchema7",
      $refStrategy: "none",
    })
    delete schema.$schema
    return schema
  } catch (error) {
    console.error(`[context-mode-v2] could not convert ${registered.name} schema:`, error)
    return { type: "object", properties: {}, additionalProperties: true }
  }
}

function toolContextFor(context) {
  return {
    sessionID: context.sessionID,
    messageID: context.messageID ?? "",
    agent: context.agent ?? "",
    directory: context.directory,
    worktree: context.worktree ?? context.directory,
    abort: context.abort,
    metadata: (input) => context.metadata?.(input),
  }
}

async function registerTools(ctx, legacyHooks, registeredTools, zodToJsonSchema) {
  const schemas = new Map(
    registeredTools.map((registered) => [
      registered.name,
      inputSchemaFor(registered, zodToJsonSchema),
    ]),
  )

  await ctx.tool.transform((editor) => {
    for (const [name, definition] of Object.entries(legacyHooks.tool ?? {})) {
      try {
        editor.add({
          name,
          description: definition.description ?? name,
          input: schemas.get(name) ?? {
            type: "object",
            properties: {},
            additionalProperties: true,
          },
          execute: async (args, toolContext) => {
            const result = await definition.execute(
              args ?? {},
              toolContextFor(toolContext),
            )
            if (typeof result === "string") return result
            return {
              content: textFromResult(result),
            }
          },
        })
      } catch (error) {
        console.error(`[context-mode-v2] could not register ${name}:`, error)
      }
    }
  })
}

async function registerToolHooks(ctx, legacyHooks) {
  await ctx.tool.hook("execute.before", async (event) => {
    const output = { args: event.input ?? {} }
    await legacyHooks["tool.execute.before"]?.(
      {
        tool: event.tool,
        sessionID: event.sessionID,
        callID: event.callID ?? "",
      },
      output,
    )

    // context-mode mutates this object for command routing. Preserve those
    // mutations on the V2 event object.
    if (event.input && output.args && output.args !== event.input) {
      Object.keys(event.input).forEach((key) => {
        if (!(key in output.args)) delete event.input[key]
      })
      Object.assign(event.input, output.args)
    }
  })

  await ctx.tool.hook("execute.after", async (event) => {
    const result = event.status === "completed" ? event.result : event.error
    await legacyHooks["tool.execute.after"]?.(
      {
        tool: event.tool,
        sessionID: event.sessionID,
        callID: event.callID ?? "",
        args: event.input ?? {},
      },
      {
        title: typeof result?.title === "string" ? result.title : event.tool,
        output: textFromResult(result),
        metadata: result?.metadata,
      },
    )
  })
}

async function registerSessionHooks(ctx, legacyHooks) {
  await ctx.session.hook("prompt", async (event) => {
    const text = event.prompt?.text
    if (typeof text !== "string") return

    await legacyHooks["chat.message"]?.(
      { sessionID: event.sessionID },
      {
        message: { role: "user" },
        parts: [{ type: "text", text }],
      },
    )
  })

  await ctx.session.hook("context", async (event) => {
    const output = {
      system: (event.system ?? []).map(textFromSystemPart),
    }

    await legacyHooks["experimental.chat.system.transform"]?.(
      { sessionID: event.sessionID, model: event.model },
      output,
    )

    if (Array.isArray(event.system)) {
      event.system.splice(0, event.system.length, ...asSystemParts(output.system))
    }
  })

  await ctx.session.hook("compaction", async (event) => {
    const output = { context: [] }

    await legacyHooks["experimental.session.compacting"]?.(
      { sessionID: event.sessionID },
      output,
    )

    // V1 exposed a mutable context array; V2 exposes the compaction messages.
    // Add the generated resume snapshot as a final user-visible compaction
    // message so the V2 summarizer retains the same continuity information.
    if (output.context.length > 0 && Array.isArray(event.messages)) {
      event.messages.push({
        role: "user",
        content: [{ type: "text", text: output.context.join("\n\n") }],
      })
    }
  })
}

async function registerEventHook(ctx, legacyHooks) {
  if (!ctx.event?.subscribe || !legacyHooks.event) return () => {}

  const controller = new AbortController()
  void (async () => {
    try {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        await legacyHooks.event({ event })
      }
    } catch (error) {
      if (!controller.signal.aborted) {
        console.error("[context-mode-v2] event subscription stopped:", error)
      }
    }
  })()

  return () => controller.abort()
}

export default {
  id: "context-mode",

  async setup(ctx) {
    const loaded = await loadContextMode()
    const factory = loaded.plugin.ContextModePlugin ?? loaded.plugin.default?.server

    if (typeof factory !== "function") {
      throw new Error("context-mode does not expose its OpenCode adapter factory")
    }

    const legacyHooks = await factory({
      directory: ctx.location?.directory ?? ctx.directory ?? process.cwd(),
      client: {
        app: {
          log: async ({ body }) => {
            try {
              await ctx.app?.log?.({ body })
            } catch {
              // Debug logging must never break an OpenCode turn.
            }
          },
        },
      },
    })

    await registerTools(
      ctx,
      legacyHooks,
      loaded.server.REGISTERED_CTX_TOOLS ?? [],
      loaded.zodToJsonSchema,
    )
    await registerToolHooks(ctx, legacyHooks)
    await registerSessionHooks(ctx, legacyHooks)
    return registerEventHook(ctx, legacyHooks)
  },
}
