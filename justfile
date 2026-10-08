default:
    @just --list

preview:
    quarto preview

build:
    quarto render

# new post: just new poem the-slug   (poem|essay|journal|reading|note)
new kind slug:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{kind}}" in poem) s=poems;; essay|journal) s=thoughts;; reading) s=reading;; note) s=notebook;; *) echo "kind: poem|essay|journal|reading|note"; exit 1;; esac
    d="$s/$(date +%Y-%m-%d)-{{slug}}"
    [ -e "$d" ] && { echo "$d exists"; exit 1; }
    t={{kind}}; [ "$t" = essay ] || [ "$t" = journal ] && t=thought
    mkdir -p "$d"
    sed -e "s/TITLE/{{slug}}/" -e "s/DATE/$(date +%Y-%m-%d)/" _templates/$t.qmd > "$d/index.qmd"
    [ "{{kind}}" = journal ] && sed -i '' "s/categories: \[Essay\]/categories: [Journal]/" "$d/index.qmd"; true
    echo "created $d/index.qmd"
