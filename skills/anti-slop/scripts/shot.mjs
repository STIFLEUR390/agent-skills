#!/usr/bin/env node
// Captures multi-largeurs via CDP, sans Playwright.
//
//   node shot.mjs <url|fichier> [--out .slop/shot] [--widths 390,768,1024,1440]
//                 [--height 900] [--fold] [--dark] [--reduced] [--bin <chemin>]
//                 [--scroll <px>] [--cookie nom=valeur] [--eval <js>]
//                 [--wait <ms>] [--audit [--json]]
//
// Moteur : un Chromium headless (chrome-headless-shell), installé une fois par
// scripts/install-browser.sh. Le script le cherche dans le PATH, puis BROWSER_BIN.
//
//   BROWSER_BIN : binaire Chromium explicite
//   CDP_URL     : serveur Chromium déjà lancé, ws://127.0.0.1:9222/devtools/browser

import { spawn } from "node:child_process";
import { mkdir, writeFile, mkdtemp, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { resolve, join } from "node:path";
import { tmpdir } from "node:os";
import { pathToFileURL } from "node:url";

if (typeof WebSocket === "undefined") {
  console.error("Node 22+ requis (WebSocket global).");
  process.exit(1);
}

const argv = process.argv.slice(2);
let source, outDir = ".slop/shot", widths = [390, 768, 1024, 1440], height = 900;
let fold = false, dark = false, reduced = false, bin = null, scroll = null;
let audit = false, json = false, waitMs = 700, cookie = null, evalJs = null;

for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === "--out") outDir = argv[++i];
  else if (a === "--widths") widths = argv[++i].split(",").map(Number);
  else if (a === "--height") height = Number(argv[++i]);
  else if (a === "--bin") bin = argv[++i];
  else if (a === "--scroll") scroll = Number(argv[++i]);
  else if (a === "--audit") audit = true;
  else if (a === "--json") json = true;
  else if (a === "--wait") waitMs = Number(argv[++i]);
  else if (a === "--cookie") cookie = argv[++i];
  else if (a === "--eval") evalJs = argv[++i];
  else if (a === "--fold") fold = true;
  else if (a === "--dark") dark = true;
  else if (a === "--reduced") reduced = true;
  else if (!a.startsWith("--")) source = a;
}
if (!source) {
  console.error("usage: shot.mjs <url|fichier> [--out dir] [--widths 390,768] [--fold] [--dark] [--reduced] [--bin chemin]");
  process.exit(2);
}
if (!widths.every((w) => Number.isInteger(w) && w > 0)) {
  console.error("--widths attend une liste d'entiers positifs");
  process.exit(2);
}
if (scroll !== null && (!Number.isInteger(scroll) || scroll < 0)) {
  console.error("--scroll attend un entier positif (pixels)");
  process.exit(2);
}

const isFile = existsSync(source);
const target = isFile ? pathToFileURL(resolve(source)).href : source;
const slug = source.replace(/^https?:\/\//, "").replace(/[^a-z0-9.]+/gi, "-").replace(/^-|-$/g, "").slice(0, 60) || "page";
await mkdir(outDir, { recursive: true });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function serverUp(port) {
  try {
    const r = await fetch(`http://127.0.0.1:${port}/json/version`, { signal: AbortSignal.timeout(1000) });
    return r.ok;
  } catch {
    return false;
  }
}

function findChromium() {
  const names = ["chrome-headless-shell", "chromium", "chromium-browser", "google-chrome", "google-chrome-stable", "chrome"];
  for (const n of names) {
    for (const dir of (process.env.PATH || "").split(":")) {
      const p = join(dir, n);
      if (p && existsSync(p)) return p;
    }
  }
  return null;
}

let child, profileDir;
let wsUrl = process.env.CDP_URL;
if (!wsUrl) {
  const exe = bin || process.env.BROWSER_BIN || findChromium();
  if (!exe) {
    console.error("Aucun Chromium headless trouvé. Installe-le une fois :");
    console.error("  bash scripts/install-browser.sh");
    console.error("ou passe --bin / BROWSER_BIN vers chrome-headless-shell.");
    process.exit(1);
  }
  const port = Number(process.env.CDP_PORT || 9223);
  if (!(await serverUp(port))) {
    profileDir = await mkdtemp(join(tmpdir(), "shot-profile-"));
    child = spawn(exe, [
      "--headless=new",
      `--remote-debugging-port=${port}`,
      "--remote-debugging-address=127.0.0.1",
      "--remote-allow-origins=*",
      "--no-sandbox",
      "--hide-scrollbars",
      "--disable-gpu",
      "--disable-dev-shm-usage",
      `--user-data-dir=${profileDir}`,
      ...(isFile ? ["--allow-file-access-from-files"] : []),
      "about:blank",
    ], { stdio: ["ignore", "ignore", "pipe"] });
    let stderr = "";
    child.stderr?.on("data", (d) => { stderr = (stderr + d).slice(-800); });
    child.on("error", () => {
      console.error(`Lancement impossible : ${exe}`);
      process.exit(1);
    });
    for (let i = 0; i < 60 && !(await serverUp(port)); i++) await sleep(200);
    if (!(await serverUp(port))) {
      console.error(`Chromium n'a pas démarré sur le port ${port}.`);
      if (stderr.trim()) console.error(stderr.trim());
      process.exit(1);
    }
  }
  const info = await fetch(`http://127.0.0.1:${port}/json/version`).then((r) => r.json());
  wsUrl = info.webSocketDebuggerUrl;
}

const ws = new WebSocket(wsUrl);
let seq = 0;
const pending = new Map();
const listeners = new Map();
ws.onmessage = (e) => {
  const m = JSON.parse(e.data);
  if (m.id && pending.has(m.id)) {
    pending.get(m.id)(m);
    pending.delete(m.id);
    return;
  }
  const key = m.sessionId ? `${m.sessionId}:${m.method}` : m.method;
  listeners.get(key)?.();
};
await new Promise((res, rej) => {
  ws.onopen = res;
  ws.onerror = () => rej(new Error(`connexion CDP impossible: ${wsUrl}`));
});
const send = (method, params = {}, sessionId) =>
  new Promise((res) => {
    const id = ++seq;
    pending.set(id, res);
    ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
  });

const once = (key, ms) =>
  new Promise((res) => {
    const t = setTimeout(res, ms);
    listeners.set(key, () => {
      clearTimeout(t);
      listeners.delete(key);
      res();
    });
  });


const AUDIT = `(() => {
  const px = (n) => Math.round(n);
  const parseColor = (c) => {
    const m = String(c).match(/[\\d.]+/g);
    return m ? m.map(Number) : [0, 0, 0];
  };
  const lum = ([r, g, b]) => {
    const f = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  const ratio = (a, b) => {
    const l1 = lum(a), l2 = lum(b);
    return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
  };
  const bgOf = (el) => {
    let n = el;
    while (n && n !== document.documentElement) {
      const c = parseColor(getComputedStyle(n).backgroundColor);
      if (c.length === 3 || (c[3] ?? 1) > 0.95) return c.slice(0, 3);
      n = n.parentElement;
    }
    // Fond de toile transparent = blanc du navigateur, pas noir.
    const body = parseColor(getComputedStyle(document.body).backgroundColor);
    return (body[3] ?? 1) > 0.95 ? body.slice(0, 3) : [255, 255, 255];
  };
  const label = (el) => {
    const cls = typeof el.className === "string" ? el.className.trim().split(/\\s+/)[0] : "";
    return cls ? "." + cls : el.tagName.toLowerCase();
  };

  const doc = document.documentElement;
  const out = {
    viewport: [innerWidth, innerHeight],
    page: { height: px(doc.scrollHeight), width: px(doc.scrollWidth) },
    overflowX: Math.max(0, px(doc.scrollWidth - innerWidth)),
    sections: [],
    lowContrast: [],
    smallTargets: [],
    images: { total: 0, noAlt: 0, emptyAlt: 0 },
    controls: { clickableDivs: 0, unlabeledInputs: 0 },
  };

  for (const sec of document.querySelectorAll("main > section, footer")) {
    const r = sec.getBoundingClientRect();
    const wrap = sec.querySelector(".wrap") || sec;
    let top = Infinity, bottom = -Infinity;
    for (const child of wrap.children) {
      const b = child.getBoundingClientRect();
      if (b.height === 0) continue;
      top = Math.min(top, b.top);
      bottom = Math.max(bottom, b.bottom);
    }
    const content = bottom > top ? bottom - top : 0;
    out.sections.push({
      id: sec.id || label(sec),
      height: px(r.height),
      content: px(content),
      fill: r.height > 0 ? Math.round((content / r.height) * 100) : 0,
      topGap: top === Infinity ? 0 : px(top - r.top),
      bottomGap: bottom === -Infinity ? 0 : px(r.bottom - bottom),
    });
  }

  const textNodes = [...document.querySelectorAll("p,li,td,th,a,span,label,code,button,h1,h2,h3,h4,figcaption,small")].filter((el) => {
    if (!el.textContent.trim()) return false;
    if (el.querySelector("p,li,td,th,a,span,label,code,button,h1,h2,h3,h4")) return false;
    const r = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && cs.visibility !== "hidden" && cs.opacity !== "0";
  });
  for (const el of textNodes) {
    const cs = getComputedStyle(el);
    const fg = parseColor(cs.color).slice(0, 3);
    const r = ratio(fg, bgOf(el));
    const size = parseFloat(cs.fontSize);
    const large = size >= 24 || (size >= 18.66 && Number(cs.fontWeight) >= 700);
    if (r < (large ? 3 : 4.5)) {
      out.lowContrast.push({ el: label(el), text: el.textContent.trim().slice(0, 42), ratio: Math.round(r * 10) / 10, size: px(size) });
    }
  }
  out.lowContrast = out.lowContrast.slice(0, 12);

  const targets = [...document.querySelectorAll("a,button,[role=button],input,select,textarea,label")];
  for (const el of targets) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    if (r.width < 2 && r.height < 2) continue; // contrôle masqué (sr-only)
    const cs = getComputedStyle(el);
    // Exception WCAG 2.5.8 : lien inline au fil du texte.
    if (el.tagName === "A" && cs.display.startsWith("inline")) continue;
    // Cibles au sens WCAG : contrôles, pas les liens de texte au fil de la page.
    const text = el.textContent.trim();
    // Un <label> dont le contrôle est déjà assez grand n'est pas la cible.
    if (el.tagName === "LABEL") {
      const id = el.getAttribute("for");
      const ctl = id ? document.getElementById(id) : el.querySelector("input,select,textarea");
      if (ctl) {
        const c = ctl.getBoundingClientRect();
        if (c.width >= 24 && c.height >= 24) continue;
      }
    }
    const control = /^(BUTTON|INPUT|SELECT|TEXTAREA|LABEL)$/.test(el.tagName) || el.getAttribute("role") === "button";
    const iconOnly = el.tagName === "A" && text.length < 3;
    if (!control && !iconOnly) continue;
    if (r.width < 24 || r.height < 24) {
      out.smallTargets.push({ el: label(el), w: px(r.width), h: px(r.height), text: text.slice(0, 18) });
    }
  }
  out.smallTargets = out.smallTargets.slice(0, 10);

  const scrollAreas = [];
  for (const el of document.querySelectorAll("body *")) {
    const cs = getComputedStyle(el);
    const oy = cs.overflowY;
    if ((oy === "auto" || oy === "scroll") && el.clientHeight > 0 && el.scrollHeight > el.clientHeight + 24) {
      scrollAreas.push({ el: label(el), view: px(el.clientHeight), content: px(el.scrollHeight) });
    }
  }
  out.scrollAreas = scrollAreas.slice(0, 8);

  for (const img of document.images) {
    out.images.total++;
    if (!img.hasAttribute("alt")) out.images.noAlt++;
    else if (img.getAttribute("alt") === "") out.images.emptyAlt++;
  }
  out.images.eager = [...document.images].filter((i) => i.loading === "eager").length;
  out.images.oversized = [...document.images]
    .filter((i) => i.getBoundingClientRect().height > 120 && !i.closest("figure"))
    .map((i) => ({ src: (i.currentSrc || i.src).slice(-40), h: px(i.getBoundingClientRect().height) }))
    .slice(0, 6);
  out.controls.clickableDivs = [...document.querySelectorAll("div,span,article,section")]
    .filter((el) => el.hasAttribute("onclick") || el.getAttribute("role") === "button" && el.tagName === "DIV").length;
  out.anchors = { total: 0, broken: [] };
  for (const a of document.querySelectorAll('a[href^="#"]')) {
    const id = a.getAttribute("href").slice(1);
    out.anchors.total++;
    if (!id) continue;
    if (!document.getElementById(id)) out.anchors.broken.push(a.getAttribute("href"));
  }
  if (out.anchors.broken.length) out.anchors.broken = out.anchors.broken.slice(0, 8);

  out.controls.unlabeledInputs = [...document.querySelectorAll("input:not([type=hidden]),select,textarea")]
    .filter((el) => {
      if (el.closest("label")) return false;
      if (el.id && document.querySelector('label[for="' + CSS.escape(el.id) + '"]')) return false;
      return !el.getAttribute("aria-label") && !el.getAttribute("aria-labelledby") && !el.getAttribute("title");
    }).length;

  return out;
})()`;

const showAudit = (a) => {
  const lines = [];
  lines.push(`AUDIT ${a.viewport[0]}x${a.viewport[1]} — page ${a.page.width}x${a.page.height}`);
  if (a.overflowX > 0) lines.push(`  ✗ débordement horizontal : ${a.overflowX}px`);
  // Un hero et un footer peuvent respirer : on ne juge que les sections de contenu.
  const empty = a.sections.filter((s) => s.fill < 55 && s.height > 320 && !/hero|closing|foot/.test(s.id));
  for (const s of empty) {
    lines.push(`  ✗ ${s.id} : ${s.fill}% rempli (${s.height}px de haut, ${s.bottomGap}px vide en bas)`);
  }
  for (const c of a.lowContrast) lines.push(`  ✗ contraste ${c.ratio}:1 (${c.size}px) ${c.el} « ${c.text} »`);
  for (const t of a.smallTargets) lines.push(`  ✗ cible ${t.w}×${t.h} ${t.el} « ${t.text} »`);
  for (const s of a.scrollAreas) lines.push(`  ! scroll imbriqué ${s.el} : ${s.content}px dans ${s.view}px`);
  if (a.images.noAlt) lines.push(`  ✗ ${a.images.noAlt} image(s) sans alt`);
  if (a.images.oversized?.length) lines.push(`  ! ${a.images.oversized.length} image(s) > 120px de haut hors figure`);
  if (a.images.eager) lines.push(`  ! ${a.images.eager} image(s) en loading=eager`);
  if (a.controls.unlabeledInputs) lines.push(`  ✗ ${a.controls.unlabeledInputs} champ(s) sans label`);
  if (a.controls.clickableDivs) lines.push(`  ✗ ${a.controls.clickableDivs} div cliquable(s)`);
  for (const h of a.anchors.broken) lines.push(`  ✗ ancre cassée ${h} (aucun élément avec cet id)`);
  if (lines.length === 1) lines.push("  ✓ rien de mécanique détecté");
  console.error(lines.join("\n"));
};

const scrollThrough = `(async () => {
  const step = innerHeight * 0.8;
  for (let y = 0; y < document.body.scrollHeight; y += step) {
    scrollTo(0, y); await new Promise(r => setTimeout(r, 60));
  }
  scrollTo(0, 0);
  if (document.fonts) await document.fonts.ready;
  await new Promise(r => setTimeout(r, 150));
})()`;

let failed = false;
try {
  for (const width of widths) {
    const created = await send("Target.createTarget", { url: "about:blank" });
    if (created.error) throw new Error(JSON.stringify(created.error));
    const targetId = created.result.targetId;
    const attached = await send("Target.attachToTarget", { targetId, flatten: true });
    if (attached.error) throw new Error(JSON.stringify(attached.error));
    const sid = attached.result.sessionId;

    const loaded = once(`${sid}:Page.loadEventFired`, 20000);
    await send("Page.enable", {}, sid);
    await send("Emulation.setDeviceMetricsOverride", {
      width,
      height,
      deviceScaleFactor: 1,
      mobile: width < 500,
    }, sid);
    if (cookie) {
      const [name, ...rest] = cookie.split("=");
      await send("Network.setCookie", { name, value: rest.join("="), url: target }, sid);
    }
    if (dark || reduced) {
      await send("Emulation.setEmulatedMedia", {
        media: "screen",
        features: [
          ...(dark ? [{ name: "prefers-color-scheme", value: "dark" }] : []),
          ...(reduced ? [{ name: "prefers-reduced-motion", value: "reduce" }] : []),
        ],
      }, sid);
    }

    const nav = await send("Page.navigate", { url: target }, sid);
    if (nav.error || nav.result?.errorText) throw new Error(nav.result?.errorText || JSON.stringify(nav.error));
    await loaded;
    await send("Runtime.evaluate", { expression: scrollThrough, awaitPromise: true }, sid);
    await sleep(waitMs);
    if (evalJs) await send("Runtime.evaluate", { expression: evalJs, awaitPromise: true }, sid);
    if (audit) {
      const r = await send("Runtime.evaluate", { expression: AUDIT, returnByValue: true }, sid);
      if (r.result?.exceptionDetails) console.error("Audit impossible:", r.result.exceptionDetails.text);
      else if (json) console.log(JSON.stringify(r.result.result.value, null, 2));
      else showAudit(r.result.result.value);
    }
    if (scroll !== null) {
      await send("Runtime.evaluate", { expression: `scrollTo(0, ${scroll})`, awaitPromise: true }, sid);
      await sleep(300);
    }

    const metrics = await send("Page.getLayoutMetrics", {}, sid);
    const fullHeight = Math.ceil(metrics.result.cssContentSize.height);
    const shot = await send("Page.captureScreenshot", {
      format: "png",
      captureBeyondViewport: !(fold || scroll !== null),
      ...(fold || scroll !== null ? {} : { clip: { x: 0, y: 0, width, height: fullHeight, scale: 1 } }),
    }, sid);
    if (shot.error) throw new Error(JSON.stringify(shot.error));

    const file = `${outDir}/${slug}-${width}.png`;
    await writeFile(file, Buffer.from(shot.result.data, "base64"));
    console.log(`${file}  ${width}x${fold ? height : fullHeight}`);
    await send("Target.closeTarget", { targetId });
  }
} catch (e) {
  failed = true;
  console.error("Échec:", e.message);
  if (String(e.message).includes("file://")) {
    console.error("Accès fichiers refusé : un Chromium lancé à la main a besoin de --allow-file-access-from-files.");
  }
} finally {
  ws.close();
  if (child && child.exitCode === null) {
    child.kill();
    await sleep(400);
    if (child.exitCode === null) child.kill("SIGKILL");
  }
  if (profileDir) await rm(profileDir, { recursive: true, force: true });
}
process.exit(failed ? 1 : 0);
