/**
 * fff-companion — ensures pi-fff can scan the home directory.
 *
 * The @ff-labs/pi-fff extension never sets `enableHomeDirScanning: true`
 * when creating the native FileFinder, causing it to refuse to index ~.
 * This tiny companion wraps FileFinder.create to always enable it.
 *
 * Place this file at: ~/.pi/agent/extensions/fff-companion.ts
 * It survives npm updates to pi-fff and has no other side effects.
 */
import { homedir } from "node:os";
import { join } from "node:path";

const fffNodePath = join(
  homedir(),
  ".pi",
  "agent",
  "npm",
  "node_modules",
  "@ff-labs",
  "fff-node",
  "dist",
  "src",
  "index.js",
);

export default async function fffCompanion() {
  const { FileFinder } = await import(fffNodePath);

  // eslint-disable-next-line @typescript-eslint/unbound-method
  const _originalCreate = FileFinder.create.bind(FileFinder);

  FileFinder.create = function (
    options: Parameters<typeof FileFinder.create>[0],
  ): ReturnType<typeof FileFinder.create> {
    return _originalCreate({ ...options, enableHomeDirScanning: true });
  };
}
