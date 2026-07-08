const tabButtons = document.querySelectorAll('.tab-btn');
const projects = document.querySelectorAll('.project');

tabButtons.forEach((button) => {
button.addEventListener('click', () => {
  tabButtons.forEach((btn) => btn.classList.remove('active'));
  button.classList.add('active');

  const filter = button.getAttribute('data-filter');

  projects.forEach((project) => {
    const category = project.getAttribute('data-category');
    const matches = filter === 'all' || category === filter;
    project.style.display = matches ? 'block' : 'none';
  });
});
});