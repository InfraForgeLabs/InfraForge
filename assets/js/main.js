// =====================
// Release configuration
// =====================
const RELEASE_DATE = new Date("2026-01-26T00:00:00");
const IS_RELEASED = () => new Date() >= RELEASE_DATE;


// =====================
// Section navigation
// =====================
function showSection(id) {
  document.querySelectorAll('.section')
    .forEach(sec => sec.classList.remove('active'));

  const el = document.getElementById(id);
  if (!el) return;

  el.classList.add('active');
  el.scrollIntoView({ behavior: 'smooth' });
}


// =====================
// Scroll fade-in observer
// =====================
const observer = new IntersectionObserver(
  entries => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        observer.unobserve(entry.target);
      }
    });
  },
  { threshold: 0.15 }
);

document.querySelectorAll('.fade-in').forEach(el => {
  observer.observe(el);
});


// =====================
// Release countdown
// =====================
(function releaseCountdown() {
  const el = document.getElementById("countdown");
  if (!el) return;

  function update() {
    const now = new Date();
    const diff = RELEASE_DATE - now;

    if (diff <= 0) {
      el.textContent = "now available 🚀";
      return;
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
    const minutes = Math.floor((diff / (1000 * 60)) % 60);

    el.textContent = `${days}d ${hours}h ${minutes}m`;
  }

  update();
  setInterval(update, 60 * 1000);
})();


// =====================
// Download auto-enable
// =====================
(function enableDownloadOnRelease() {
  if (!IS_RELEASED()) return;

  const btn = document.getElementById("download-btn");
  if (!btn) return;

  btn.disabled = false;
  btn.classList.add("enabled");
  btn.textContent = "Download InfraForge (Linux)";

  btn.addEventListener("click", () => {
    window.location.href =
      "https://github.com/InfraForgeLabs/infraforge/releases/latest";
  });
})();


// =====================
// Download note updater
// =====================
(function updateDownloadNote() {
  const el = document.getElementById("download-note");
  if (!el) return;

  el.textContent = IS_RELEASED()
    ? "Linux installers for Debian and RHEL-based distributions are now available."
    : "Linux installers for Debian and RHEL-based distributions will be available on January 26, 2026.";
})();


// =====================
// Install section reveal
// =====================
(function enableInstallSection() {
  if (!IS_RELEASED()) return;

  const section = document.getElementById("install-section");
  if (!section) return;

  section.hidden = false;
})();


// =====================
// Release badge updater (version.json)
// =====================
(function updateReleaseBadge() {
  const badge = document.getElementById("release-badge");
  if (!badge) return;

  if (!IS_RELEASED()) return;

  fetch(
    "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json",
    { cache: "no-store" }
  )
    .then(res => {
      if (!res.ok) throw new Error("failed to fetch version metadata");
      return res.json();
    })
    .then(data => {
      if (!data.latest_version) throw new Error("latest_version missing");

      badge.textContent = `🚀 InfraForge v${data.latest_version}`;
    })
    .catch(() => {
      badge.textContent = "🚀 InfraForge released";
    });
})();


// =====================
// Status line updater (version.json)
// =====================
(function updateStatusLine() {
  const el = document.getElementById("status-line");
  if (!el) return;

  fetch(
    "https://raw.githubusercontent.com/InfraForgeLabs/infraforgelabs.github.io/main/meta/infraforge/version.json",
    { cache: "no-store" }
  )
    .then(res => {
      if (!res.ok) throw new Error("failed to fetch version metadata");
      return res.json();
    })
    .then(data => {
      if (!data.latest_version) throw new Error("latest_version missing");

      const isPre = data.latest_version.toLowerCase().includes("pre");
      const label = isPre ? "Pre-release" : "Stable";

      el.innerHTML =
        `<strong>Status:</strong> v${data.latest_version} (${label})`;
    })
    .catch(() => {
      // fallback: keep static HTML
    });
})();
