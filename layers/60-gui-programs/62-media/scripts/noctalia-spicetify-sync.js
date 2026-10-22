#!/usr/bin/env node
const fs = require("fs");
const path = require("path");

const homeDir = process.env.HOME || "/home/t0psh31f";
const configDir = process.env.XDG_CONFIG_HOME || path.join(homeDir, ".config");
const colorIniPath = path.join(configDir, "spicetify/Themes/Comfy/color.ini");

if (!fs.existsSync(colorIniPath)) {
  process.exit(0);
}

const content = fs.readFileSync(colorIniPath, "utf8");
const lines = content.split("\n");
const vars = [];

for (const line of lines) {
  const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s*=\s*#?([0-9a-fA-F]{6})\s*$/);
  if (match) {
    const key = match[1];
    const hex = match[2];
    const r = parseInt(hex.slice(0, 2), 16);
    const g = parseInt(hex.slice(2, 4), 16);
    const b = parseInt(hex.slice(4, 6), 16);
    vars.push(`  --spice-${key}: #${hex} !important;`);
    vars.push(`  --spice-rgb-${key}: ${r},${g},${b} !important;`);
  }
}

if (vars.length === 0) {
  process.exit(0);
}

const css = `:root {\n${vars.join("\n")}\n}`;

// Save CSS to cache file for reference
try {
  const cacheDir = path.join(homeDir, ".cache/spicetify");
  if (!fs.existsSync(cacheDir)) {
    fs.mkdirSync(cacheDir, { recursive: true });
  }
  fs.writeFileSync(path.join(cacheDir, "noctalia-theme-override.css"), css);
} catch (e) {
  // Non-fatal
}

async function sync() {
  try {
    const res = await fetch("http://127.0.0.1:9222/json", {
      signal: AbortSignal.timeout(1000)
    });
    if (!res.ok) return;

    const targets = await res.json();
    const pages = targets.filter(t => t.type === "page" && (t.url.includes("xpui") || t.title.includes("Spotify")));

    for (const page of pages) {
      if (!page.webSocketDebuggerUrl) continue;
      await injectCss(page.webSocketDebuggerUrl, css);
    }
  } catch (err) {
    // Spotify not running or CDP unreachable - normal exit
  }
}

function injectCss(wsUrl, cssText) {
  return new Promise((resolve) => {
    let ws;
    const timer = setTimeout(() => {
      if (ws) ws.close();
      resolve();
    }, 1200);

    try {
      ws = new WebSocket(wsUrl);
      ws.onopen = () => {
        const js = `(function() {
          const css = ${JSON.stringify(cssText)};
          try {
            localStorage.setItem("noctalia-theme-override", css);
          } catch(e) {}
          let style = document.getElementById("noctalia-theme-override");
          if (!style) {
            style = document.createElement("style");
            style.id = "noctalia-theme-override";
            (document.head || document.documentElement).appendChild(style);
          }
          style.textContent = css;
        })()`;

        ws.send(JSON.stringify({
          id: 1,
          method: "Runtime.evaluate",
          params: { expression: js }
        }));
      };

      ws.onmessage = () => {
        clearTimeout(timer);
        ws.close();
        resolve();
      };

      ws.onerror = () => {
        clearTimeout(timer);
        ws.close();
        resolve();
      };
    } catch (e) {
      clearTimeout(timer);
      resolve();
    }
  });
}

sync();
