#!/usr/bin/env python3
"""Fill `description:` in poem front matter with the first two lines of the poem.

The listing (home page, Poems page, feeds, social previews) shows `description`
under the title. Only poems WITHOUT a description are touched, so a hand-written
one is never overwritten. Usage: scripts/poem-descriptions.py [--dry-run] [files...]
"""
import json, re, sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

def plain(line: str) -> str:
    s = line.replace("\\~", "").strip()
    s = re.sub(r"\[([^\]]*)\]\{[^}]*\}", r"\1", s)     # [text]{.underline} -> text
    s = re.sub(r"~~(.*?)~~", r"\1", s)                  # strikethrough
    s = re.sub(r"[*_]{1,3}([^*_]+)[*_]{1,3}", r"\1", s) # emphasis
    return re.sub(r"\s+", " ", s).strip()

def first_lines(body: str, title: str = "", n: int = 2):
    out = []
    for raw in body.splitlines():
        if not raw.startswith("|"):
            if out:            # stop at the end of the first line block
                break
            continue
        text = plain(raw[1:])
        if not text:           # blank line inside the block = stanza break
            if out:
                break
            continue
        if not out and text.casefold().strip('?!."“” ') == title.casefold().strip('?!."“” '):
            continue           # poem repeats its own title as the first line
        out.append(text)
        if len(out) == n:
            break
    return out

def process(path: pathlib.Path, dry: bool) -> str:
    src = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", src, re.S)
    if not m:
        return "no front matter"
    fm, body = m.group(1), m.group(2)
    if re.search(r"^description:", fm, re.M):
        return "has description (kept)"
    tm = re.search(r'^title:\s*"?(.*?)"?\s*$', fm, re.M)
    lines = first_lines(body, tm.group(1) if tm else "")
    if not lines:
        return "no line block found (skipped)"
    desc = " / ".join(lines)
    new_fm = re.sub(r"^(title:.*)$", lambda t: t.group(1) + "\ndescription: " + json.dumps(desc, ensure_ascii=False),
                    fm, count=1, flags=re.M)
    if not dry:
        path.write_text("---\n" + new_fm + "\n---\n" + body, encoding="utf-8")
    return "→ " + desc

if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    files = [pathlib.Path(a) for a in args] or sorted((ROOT / "poems").glob("*/index.qmd"))
    for f in files:
        print(f"{f.parent.name}: {process(f, dry)}")
