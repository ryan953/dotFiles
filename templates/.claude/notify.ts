#!/usr/bin/env npx tsx

import { execSync } from "node:child_process";
import { appendFileSync, readFileSync } from "node:fs";
import { homedir } from "node:os";

const [title, message] = process.argv.slice(2);

let input = "";
try {
  input = readFileSync("/dev/stdin", "utf8");
} catch {}

// appendFileSync("/tmp/claude-notify.log", `${input}\n`);

let cwd = "";
if (input) {
  try {
    cwd = JSON.parse(input).cwd ?? "";
  } catch {}
}

if (!cwd) {
  cwd = process.cwd();
}

if (cwd.includes("/.gc/")) {
  process.exit(0);
}

const home = homedir();
const shortCwd = cwd.startsWith(home) ? "~" + cwd.slice(home.length) : cwd;

const fullMessage = `📁 ${shortCwd}\n${message}`;

try {
  execSync("command -v terminal-notifier", { stdio: "ignore" });
  execSync(
    `terminal-notifier -title ${JSON.stringify(title)} -message ${JSON.stringify(fullMessage)} -sound default`
  );
} catch {}
