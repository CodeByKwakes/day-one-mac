import * as fs from 'node:fs/promises';
import * as z from 'zod/v4';

const name = z.string().regex(/^[a-z][a-z0-9_-]*$/);
const schema = z.object({
  schema: z.literal(1), transport: z.literal('stdio'),
  names: z.object({ codex: name, claude: name, vscode: name, raycast: name }).strict(),
  startupTimeoutSeconds: z.number().int().positive(),
  toolTimeoutSeconds: z.number().int().positive(),
  readOnlyTools: z.array(name).min(1),
  guides: z.record(name, z.string().regex(/^docs\/(?:[a-zA-Z0-9_-]+\/)*[a-zA-Z0-9_-]+\.md$/))
}).strict();

// Bundled at build time. Never read project/client configuration or home files.
export const serverSpec = schema.parse(JSON.parse(await fs.readFile(new URL('../server-spec.json', import.meta.url), 'utf8')));
if (!Object.keys(serverSpec.guides).length || new Set(serverSpec.readOnlyTools).size !== serverSpec.readOnlyTools.length) throw Error('Invalid MCP server specification.');
