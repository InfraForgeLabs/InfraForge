// =====================
// InfraForge release metadata (single source of truth)
// =====================
const VERSION_URL =
  "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json";

let RELEASE_INFO = null;

async function getReleaseInfo() {
  if (RELEASE_INFO) return RELEASE_INFO;

  const res = await fetch(VERSION_URL, { cache: "no-store" });
  if (!res.ok) throw new Error("Version metadata unavailable");

  const data = await res.json();
  if (!data.latest_version) {
    throw new Error("Invalid version metadata");
  }

  RELEASE_INFO = {
    version: data.latest_version,
    releasedAt: data.released_at || null,
    notes: data.notes || "",
    isReleased: true // 🔥 existence = released
  };

  return RELEASE_INFO;
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
// Release badge updater
// =====================
(async function updateReleaseBadge() {
  const badge = document.getElementById("release-badge");
  if (!badge) return;

  try {
    const info = await getReleaseInfo();
    badge.textContent = `🚀 InfraForge v${info.version}`;
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
    // keep static fallback
  }
})();
