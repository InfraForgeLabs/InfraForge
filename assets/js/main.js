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
// Download enable (version.json driven)
// =====================
(function enableDownloadFromVersion() {
  const btn = document.getElementById("download-btn");
  if (!btn) return;

  fetch(
    "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json",
    { cache: "no-store" }
  )
    .then(res => {
      if (!res.ok) throw new Error("version not available");
      return res.json();
    })
    .then(data => {
      if (!data.latest_version) throw new Error("no version");

      btn.disabled = false;
      btn.classList.add("enabled");
      btn.textContent = "Download InfraForge (Linux)";

      btn.addEventListener("click", () => {
        window.location.href =
          "https://github.com/InfraForgeLabs/infraforge/releases/latest";
      });
    })
    .catch(() => {
      // leave disabled if version.json is unreachable
    });
})();

// =====================
// Download note updater (version.json driven)
// =====================
(function updateDownloadNote() {
  const note = document.getElementById("download-note");
  if (!note) return;

  fetch(
    "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json",
    { cache: "no-store" }
  )
    .then(res => {
      if (!res.ok) throw new Error("version not found");
      return res.json();
    })
    .then(data => {
      if (!data.latest_version) throw new Error("invalid version data");

      note.textContent =
        "Linux installers for Debian and RHEL-based distributions are available.";
    })
    .catch(() => {
      note.textContent =
        "Installer information temporarily unavailable. Please refresh.";
    });
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

