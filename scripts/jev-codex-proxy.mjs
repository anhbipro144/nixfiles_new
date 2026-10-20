import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { parseEnv } from "node:util";

process.umask(0o077);
const [root, credentials, portText] = process.argv.slice(2);
const port = Number(portText);
if (!root || !credentials || !Number.isInteger(port) || port < 0 || port > 65535) {
  throw new Error("Expected Jev package directory, runtime credentials path, and proxy port");
}

try {
  const values = parseEnv(readFileSync(credentials, "utf8"));
  for (const key of ["JEV_API_KEY", "TYPESAFE_API_KEY"]) {
    if (process.env[key] === undefined && values[key]) process.env[key] = values[key];
  }
} catch (error) {
  if (error.code !== "ENOENT") throw new Error(`Cannot read Jev runtime credentials (${error.code})`);
}

const { loadEnv, jevKey } = await import(pathToFileURL(resolve(root, "src/env.mjs")));
loadEnv();
// Never allow runtime dotenv files to enable prompt or request dumps.
process.env.JEV_DEBUG = "";
process.env.JEV_DUMP = "";

const { startCodexProxy } = await import(pathToFileURL(resolve(root, "src/codex-proxy.mjs")));
const proxy = await startCodexProxy({ port });
if (!jevKey()) console.error("Jev routing key missing; fixed-model requests remain available");
console.log(`Jev proxy listening on 127.0.0.1:${proxy.port}`);
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => proxy.close());
