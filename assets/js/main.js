// Section navigation
function showSection(id) {
  document.querySelectorAll('.section')
    .forEach(sec => sec.classList.remove('active'));

  const el = document.getElementById(id);
  el.classList.add('active');
  el.scrollIntoView({ behavior: 'smooth' });
}

// Scroll fade-in observer
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
