default:
    @just --list

# live-reload preview
preview:
    quarto preview

# full render into _site/
build:
    quarto render

# new post: just new poem the-slug   (poem|thought|idea)
new kind slug:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{kind}}" in poem) c=Poems;; thought) c=Thoughts;; idea) c=Ideas;; *) echo "kind must be poem|thought|idea"; exit 1;; esac
    d="posts/$(date +%Y-%m-%d)-{{slug}}"
    [ -e "$d" ] && { echo "$d exists"; exit 1; }
    mkdir -p "$d"
    sed -e "s/TITLE/{{slug}}/" -e "s/^date: .*/date: $(date +%Y-%m-%d)/" -e "s/categories: \[Poems\]/categories: [$c]/" posts/_template/index.qmd > "$d/index.qmd"
    echo "created $d/index.qmd"
