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
  const btn = document.getElementById("download-btn");
  if (!btn) return;

  // Release date: January 26, 2026 (local time)
  const releaseDate = new Date("2026-01-26T00:00:00");
  const now = new Date();

  if (now >= releaseDate) {
    btn.disabled = false;
    btn.classList.add("enabled");

    btn.textContent = "Download InfraForge (Linux)";
    btn.addEventListener("click", () => {
      window.location.href =
        "https://github.com/InfraForgeLabs/infraforge/releases/latest";
    });
  }
})();


// =====================
// Download note updater (optional but recommended)
// =====================
(function updateDownloadNote() {
  const el = document.getElementById("download-note");
  if (!el) return;

  const releaseDate = new Date("2026-01-26T00:00:00");
  const now = new Date();

  if (now >= releaseDate) {
    el.textContent =
      "Linux installers for Debian and RHEL-based distributions are now available.";
  } else {
    el.textContent =
      "Linux installers for Debian and RHEL-based distributions will be available on January 26, 2026.";
  }
})();
