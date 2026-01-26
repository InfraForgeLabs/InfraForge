// =====================
// InfraForge release metadata (single source of truth)
// =====================
const VERSION_URL =
  "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json";

async function getReleaseInfo() {
  const res = await fetch(VERSION_URL, { cache: "no-store" });
  if (!res.ok) throw new Error("Version metadata unavailable");

  const data = await res.json();
  if (!data.latest_version || !data.released_at) {
    throw new Error("Invalid version metadata");
  }

  const releasedAt = new Date(data.released_at);

  return {
    version: data.latest_version,
    releasedAt,
    isReleased: new Date() >= releasedAt,
    notes: data.notes || ""
  };
}

// =====================
// Section navigation
// =====================
function showSection(id) {
  document.querySelectorAll(".section")
    .forEach(sec => sec.classList.remove("active"));

  const el = document.getElementById(id);
  if (!el) return;

  el.classList.add("active");
  el.scrollIntoView({ behavior: "smooth" });
}

// =====================
// Scroll fade-in observer
// =====================
const observer = new IntersectionObserver(
  entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);

document.querySelectorAll(".fade-in").forEach(el => observer.observe(el));

// =====================
// Download button enable
// =====================
(async function enableDownload() {
  const btn = document.getElementById("download-btn");
  if (!btn) return;

  try {
    const info = await getReleaseInfo();
    if (!info.isReleased) return;

    btn.disabled = false;
    btn.classList.add("enabled");
    btn.textContent = "Download InfraForge (Linux)";
    btn.onclick = () =>
      window.location.href =
        "https://github.com/InfraForgeLabs/infraforge/releases/latest";
  } catch {}
})();

// =====================
// Download note updater
// =====================
(async function updateDownloadNote() {
  const el = document.getElementById("download-note");
  if (!el) return;

  try {
    const info = await getReleaseInfo();
    el.textContent = info.isReleased
      ? "Linux installers for Debian and RHEL-based distributions are now available."
      : `Linux installers for Debian and RHEL-based distributions will be available on ${info.releasedAt.toDateString()}.`;
  } catch {}
})();

// =====================
// Install section reveal
// =====================
(async function enableInstallSection() {
  const section = document.getElementById("install-section");
  if (!section) return;

  try {
    const info = await getReleaseInfo();
    if (info.isReleased) section.hidden = false;
  } catch {}
})();

// =====================
// Release badge updater
// =====================
(async function updateReleaseBadge() {
  const badge = document.getElementById("release-badge");
  if (!badge) return;

  try {
    const info = await getReleaseInfo();
    badge.textContent = info.isReleased
      ? `🚀 InfraForge v${info.version}`
      : "🚀 InfraForge";
  } catch {
    badge.textContent = "🚀 InfraForge";
  }
})();

// =====================
// Status line updater
// =====================
(async function updateStatusLine() {
  const el = document.getElementById("status-line");
  if (!el) return;

  try {
    const info = await getReleaseInfo();
    el.innerHTML = `<strong>Status:</strong> v${info.version}`;
  } catch {
    // fallback: keep static HTML
  }
})();

