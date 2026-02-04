import init from "./pkg/frontend.js";
import { getCurrentWindow } from "@tauri-apps/api/window";

async function renderApp() {
  const container = document.getElementById("app");
  if (!container) throw new Error("Missing #app container");
  container.innerHTML = "";
  await init();
}

function debounce(fn, delay) {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => fn(...args), delay);
  };
}

// ----- DPI / scaling (treat platform scale as hostile input) -----

function getSafeDpr() {
  const dpr = window.devicePixelRatio;
  if (typeof dpr !== "number" || !Number.isFinite(dpr)) return 1;
  // Clamp to something sane so broken environments don't melt your UI.
  if (dpr <= 0) return 1;
  if (dpr > 5) return 5;
  return dpr;
}

function applyScale() {
  const dpr = getSafeDpr();
  const basePx = 16;
  const px = Math.round(basePx * dpr * 1000) / 1000;

  document.documentElement.style.fontSize = `${px}px`;

  console.log("DPI", {
    dpr,
    appliedRootPx: getComputedStyle(document.documentElement).fontSize,
    inner: [window.innerWidth, window.innerHeight],
    screen: [screen.width, screen.height],
  });
}

// Better than hardcoding a dpi media query string (and avoids stale DPR).
function watchDprChanges(onChange) {
  // Some webviews support this. Some pretend they do. We try, then fall back.
  let mql = null;

  const rebuild = () => {
    try {
      // This is intentionally re-created because DPR can change.
      const dpi = Math.round(getSafeDpr() * 96);
      mql = window.matchMedia(`(resolution: ${dpi}dpi)`);
      mql.addEventListener?.("change", onChange);
      mql.addListener?.(onChange); // old Safari/WebKit
      return true;
    } catch {
      return false;
    }
  };

  const ok = rebuild();
  if (!ok) {
    // Resize catches a lot of compositor scale changes in practice.
    window.addEventListener("resize", onChange, { passive: true });
  }

  // Also rebind on focus; some compositors only update DPR when focused.
  window.addEventListener("focus", () => {
    // remove old listener if any
    try {
      mql?.removeEventListener?.("change", onChange);
      mql?.removeListener?.(onChange);
    } catch {}
    rebuild();
    onChange();
  });
}

applyScale();
watchDprChanges(applyScale);
window.addEventListener("resize", applyScale, { passive: true });

// ----- App boot -----

renderApp().catch((e) => console.error("renderApp failed:", e));

// ----- Tauri hooks (optional, but useful) -----

const win = getCurrentWindow();
const debouncedRender = debounce(() => {
  renderApp().catch((e) => console.error("renderApp failed:", e));
}, 200);

// Scale-changed is nice when it works; on Linux/Wayland it can be… aspirational.
win.onScaleChanged(() => {
  console.log("Tauri scale change event");
  applyScale();
  debouncedRender();
});

win.listen("tauri://resize", (event) => {
  console.log("Window resized:", event);
  // If you actually need a rerender on resize, uncomment:
  // debouncedRender();
});

// ----- Debug dump (kept, but Tauri scaleFactor is untrusted) -----

async function dumpScale() {
  const htmlFs = getComputedStyle(document.documentElement).fontSize;
  console.log("UA:", navigator.userAgent);
  console.log("devicePixelRatio:", window.devicePixelRatio);
  console.log("safeDpr:", getSafeDpr());
  console.log("inner:", window.innerWidth, window.innerHeight);
  console.log("screen:", screen.width, screen.height);
  console.log("html font-size:", htmlFs);

  try {
    const sf = await win.scaleFactor();
    console.log("tauri scaleFactor():", sf, "(FYI: may be bogus on Wayland)");
  } catch (e) {
    console.log("tauri scaleFactor() failed:", e);
  }
}

dumpScale();
