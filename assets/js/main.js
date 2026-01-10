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
