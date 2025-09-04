// This polyfill was done by Copilot after hours of struggle. Deleting game sessions turned out to be the only hell I couldn't escape from.
// I'll come back and conquer you, just wait a moment !

document.addEventListener('turbo:click', function(event) {
  var link = event.target.closest('a[data-method]');
  if (!link) return;

  var method = link.getAttribute('data-method').toUpperCase();
  if (method === 'GET') return;

  var confirmMessage = link.getAttribute('data-confirm');
  if (confirmMessage && !window.confirm(confirmMessage)) {
    event.preventDefault();
    return;
  }

  var form = document.createElement('form');
  form.method = 'POST';
  form.action = link.getAttribute('href');
  form.style.display = 'none';

  var csrfParam = document.querySelector('meta[name=csrf-param]');
  var csrfToken = document.querySelector('meta[name=csrf-token]');
  if (csrfParam && csrfToken) {
    var input = document.createElement('input');
    input.type = 'hidden';
    input.name = csrfParam.content;
    input.value = csrfToken.content;
    form.appendChild(input);
  }

  var methodInput = document.createElement('input');
  methodInput.type = 'hidden';
  methodInput.name = '_method';
  methodInput.value = method;
  form.appendChild(methodInput);

  document.body.appendChild(form);
  form.submit();
  event.preventDefault();
});
