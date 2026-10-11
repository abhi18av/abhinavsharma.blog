// Poem pages: add attribution to copied text, and copy stanza permalinks.
(function () {
  if (!document.querySelector('.poem-footer')) return;
  var main = document.querySelector('main') || document.body;
  var titleEl = document.querySelector('h1.title');
  var title = titleEl ? titleEl.textContent.trim() : document.title;
  var base = location.origin + location.pathname;
  var meta = document.querySelector('.poem-footer').dataset;
  var author = meta.author || 'Abhinav Sharma';
  var affiliation = meta.affiliation || '';
  var doi = meta.doi ? 'https://doi.org/' + meta.doi : '';
  var dateEl = document.querySelector('meta[name="dcterms.date"]');
  var year = dateEl ? (dateEl.content.match(/^\d{4}/) || [''])[0] : '';
  var who = author + (affiliation ? ', ' + affiliation : '');

  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  document.addEventListener('copy', function (e) {
    var sel = window.getSelection();
    if (!sel || sel.isCollapsed || !sel.rangeCount || !e.clipboardData) return;
    var range = sel.getRangeAt(0);
    var node = range.commonAncestorContainer;
    if (node.nodeType !== 1) node = node.parentElement;
    if (!node || !main.contains(node) || node.closest('.poem-footer, nav, header.quarto-title-block')) return;

    var stanzas = Array.prototype.slice.call(main.querySelectorAll('.stanza'));
    var touched = stanzas.filter(function (s) { return sel.containsNode(s, true); });
    var url = base + (touched.length === 1 ? '#' + touched[0].id : '');

    var text = sel.toString().replace(/\s+$/, '');
    var note = '';
    if (touched.length > 1 && touched.length < stanzas.length) {
      note = '\nNote: quoting more than one stanza needs permission (see the licence).';
    }
    var lic = 'CC BY-NC-ND 4.0';
    var plain = text + '\n\n— ' + who + '\n“' + title + '”' + (year ? ' (' + year + ')' : '') + ', in Poems' +
      (doi ? '\n' + doi : '') + '\n' + url + '\n' + lic + note;

    var box = document.createElement('div');
    box.appendChild(range.cloneContents());
    Array.prototype.forEach.call(box.querySelectorAll('.stanza-link'), function (n) { n.remove(); });
    Array.prototype.forEach.call(box.querySelectorAll('[id]'), function (n) { n.removeAttribute('id'); });
    var html = '<blockquote>' + box.innerHTML + '</blockquote>' +
      '<p>— ' + esc(who) + ',<br>' +
      '<a href="' + esc(url) + '">“' + esc(title) + '”</a>' + (year ? ' (' + esc(year) + ')' : '') + ', in <em>Poems</em>' +
      (doi ? ',<br><a href="' + esc(doi) + '">' + esc(doi) + '</a>' : '') +
      '<br><a href="https://creativecommons.org/licenses/by-nc-nd/4.0/">' + lic + '</a>' +
      (note ? '<br><em>' + esc(note.trim()) + '</em>' : '') + '</p>';

    e.clipboardData.setData('text/plain', plain);
    e.clipboardData.setData('text/html', html);
    e.preventDefault();
  });

  main.addEventListener('click', function (e) {
    var a = e.target.closest && e.target.closest('.stanza-link');
    if (!a) return;
    var url = base + a.getAttribute('href');
    try { navigator.clipboard.writeText(url); } catch (err) { /* link still navigates */ }
    a.classList.add('copied');
    setTimeout(function () { a.classList.remove('copied'); }, 1500);
  });
})();
