default:
    @just --list

preview:
    quarto preview

build:
    quarto render

# new post: just new poem the-slug   (poem|thought|reading|note)
new kind slug:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{kind}}" in poem) s=poems;; thought) s=thoughts;; reading) s=reading;; note) s=notebook;; *) echo "kind: poem|thought|reading|note"; exit 1;; esac
    d="$s/$(date +%Y-%m-%d)-{{slug}}"
    [ -e "$d" ] && { echo "$d exists"; exit 1; }
    mkdir -p "$d"
    sed -e "s/TITLE/{{slug}}/" -e "s/DATE/$(date +%Y-%m-%d)/" _templates/{{kind}}.qmd > "$d/index.qmd"
    echo "created $d/index.qmd"
