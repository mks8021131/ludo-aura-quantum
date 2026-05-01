// Premium Reveal Animations
const revealItems = document.querySelectorAll(".reveal");
const observer = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
        observer.unobserve(entry.target);
      }
    });
  },
  {
    threshold: 0.15,
    rootMargin: "0px 0px -50px 0px"
  }
);

revealItems.forEach((item) => observer.observe(item));

// Smooth Scroll for Navigation
document.querySelectorAll('a[href^="#"]').forEach((link) => {
  link.addEventListener("click", (event) => {
    const href = link.getAttribute("href");
    const target = document.querySelector(href);

    if (target) {
      event.preventDefault();
      const headerOffset = 80;
      const elementPosition = target.getBoundingClientRect().top;
      const offsetPosition = elementPosition + window.pageYOffset - headerOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: "smooth"
      });
    }
  });
});

// Dynamic Last Updated Date (Optional helper)
const updateDateElements = document.querySelectorAll('.dynamic-date');
if (updateDateElements.length > 0) {
    const now = new Date();
    const options = { year: 'numeric', month: 'long', day: 'numeric' };
    updateDateElements.forEach(el => {
        el.textContent = now.toLocaleDateString('en-US', options);
    });
}

// Parallax effect for Phone Mockup
window.addEventListener('scroll', () => {
    const mockup = document.querySelector('.phone-mockup');
    if (mockup) {
        const scrolled = window.pageYOffset;
        mockup.style.transform = `translateY(${scrolled * 0.05}px) rotateX(${scrolled * 0.01}deg)`;
    }
});
