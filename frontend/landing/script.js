// script.js
fetch('/assets/overview.txt')
  .then(response => {
    if (!response.ok) {
      throw new Error('File could not be loaded.');
    }
    return response.text();
  })
  .then(data => {
    document.getElementById('docContent').textContent = data;
  })
  .catch(error => {
    document.getElementById('docContent').textContent = 'Error loading documentation.';
    console.error(error);
  });