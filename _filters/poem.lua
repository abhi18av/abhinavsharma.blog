-- Poem pages only: stanza anchors, licence/cite footer, JSON-LD.
local SITE    = "https://abhinavsharma.blog"
local DOI     = "10.5281/zenodo.23230176"   -- Zenodo concept DOI (always the latest version)
local LICENSE = "https://creativecommons.org/licenses/by-nc-nd/4.0/"
local ORCID   = "https://orcid.org/0000-0002-6402-6993"

local function esc_json(s)
  return (s:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', ' '))
end
local function esc_html(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'):gsub('"', '&quot;'))
end

function Pandoc(doc)
  local slug = (quarto.doc.input_file or ""):match("poems/([^/]+)/index%.qmd$")
  if not slug then return nil end

  local title = pandoc.utils.stringify(doc.meta.title or "")
  local date  = slug:match("^(%d%d%d%d%-%d%d%-%d%d)") or ""   -- ISO date from the folder name
  local url   = SITE .. "/poems/" .. slug .. "/"

  -- 1. Split each line block into stanzas (at empty lines), give each an id + permalink.
  local n = 0
  local function is_ornament(group)
    local txt = ""
    for _, line in ipairs(group) do txt = txt .. pandoc.utils.stringify(line) end
    return txt:gsub("[%s~]", "") == ""
  end
  doc.blocks = doc.blocks:walk({
    LineBlock = function(el)
      -- Split at empty lines. Two or more in a row = a deliberate "double" break (extra space).
      local groups, cur, pending, cur_gap = {}, {}, 0, false
      for _, line in ipairs(el.content) do
        if pandoc.utils.stringify(line):gsub("%s", "") == "" then
          if #cur > 0 then
            table.insert(groups, { lines = cur, gap = cur_gap })
            cur, pending = {}, 0
          end
          pending = pending + 1
        else
          if #cur == 0 then cur_gap = pending >= 2 end
          table.insert(cur, line)
        end
      end
      if #cur > 0 then table.insert(groups, { lines = cur, gap = cur_gap }) end

      local out = {}
      for _, grp in ipairs(groups) do
        local g = grp.lines
        local classes = {}
        if grp.gap then table.insert(classes, "stanza-gap") end
        if is_ornament(g) then
          table.insert(classes, "ornament")
          table.insert(out, pandoc.Div({ pandoc.LineBlock(g) }, pandoc.Attr("", classes)))
        else
          n = n + 1
          local id = "stanza-" .. n
          table.insert(classes, "stanza")
          table.insert(out, pandoc.Div({
            pandoc.LineBlock(g),
            pandoc.RawBlock("html",
              '<a class="stanza-link" href="#' .. id .. '" aria-label="Link to this stanza"></a>'),
          }, pandoc.Attr(id, classes)))
        end
      end
      return out
    end,
  })

  -- 2. Licence + cite footer.
  local footer = string.format([[
<div class="poem-footer">
<p><strong>Reuse.</strong> © Abhinav Sharma. <a rel="license" href="%s">CC BY-NC-ND 4.0</a>:
you may share this poem unmodified, or quote <em>one stanza</em>, with attribution and a link back to this page.
Anything longer, or any adaptation, needs permission.</p>
<p><strong>Cite.</strong> Sharma, A. “%s”. In <em>Poems</em>. Zenodo. <a href="https://doi.org/%s">doi:%s</a>.</p>
</div>]], LICENSE, esc_html(title), DOI, DOI)
  table.insert(doc.blocks, pandoc.RawBlock("html", footer))

  -- 3. Machine-readable attribution in <head>.
  local ld = string.format(
    '{"@context":"https://schema.org","@type":"CreativeWork","name":"%s","genre":"poetry",' ..
    '"inLanguage":"en","url":"%s","dateCreated":"%s","license":"%s",' ..
    '"author":{"@type":"Person","name":"Abhinav Sharma","@id":"%s"},' ..
    '"copyrightHolder":{"@type":"Person","name":"Abhinav Sharma","@id":"%s"},' ..
    '"isPartOf":{"@type":"CreativeWork","name":"Poems","sameAs":"https://doi.org/%s"}}',
    esc_json(title), url, esc_json(date), LICENSE, ORCID, ORCID, DOI)
  local head = '<link rel="license" href="' .. LICENSE .. '">' ..
               '<script type="application/ld+json">' .. ld .. '</script>'
  local hi = doc.meta["header-includes"] or pandoc.MetaList({})
  if hi.t ~= "MetaList" then hi = pandoc.MetaList({ hi }) end
  hi:insert(pandoc.MetaBlocks({ pandoc.RawBlock("html", head) }))
  doc.meta["header-includes"] = hi

  return doc
end
