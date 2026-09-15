#!/bin/bash
# Regenerates every pre-rendered PNG the manual embeds, then recompiles
# the manual file(s) that use them --- the two-pipeline approach: real
# example .typ files under docs/manual-snippets/ are compiled for real
# (plain and preview, genuinely separate compiles), and the manual
# itself (docs/manual*.typ) just does read()/image() on the results, no
# package import, no eval().
#
# Snippet convention, so this script can stay generic instead of
# special-casing each file:
# - A snippet with no `#document(...)` call, directly or via the real
#   `contexture.bundle`/`bundle.with(...)` pilot, is a "plain" file
#   (check()/na() directly, no bundle) -> compiled straight to
#   <name>/result-plain.png and <name>/result-preview.png.
# - A snippet using the bundle pilot is a bundle -> each named output
#   gets a `-plain`/`-preview` suffix: <name>/manuscript-plain.ext,
#   <name>/checklist-plain.ext, etc. (checklist.pdf never appears in
#   the preview compile: checklist()'s own `applicable` rule never
#   builds it under `preview: true` --- see src/pilot.typ.)
#
#   Unlike palimpsest's `variant` axis, checkitoff has no second, self-named
#   output the way `letter()`'s tracked manuscript is --- contexture's
#   bundle names the manuscript itself "manuscript-preview.pdf" under
#   `--input preview=true`, so no dedup logic is needed here the way
#   palimpsest's compile.sh needs for `variant`.
# - PNG export only supports a single-page document (Typst enforces
#   this) --- a snippet whose manuscript template fixes a real page size
#   instead of `height: auto` (see bundle-page-break-idiom.typ) can
#   genuinely span more than one page; this script always rasterizes
#   through a PDF and splits multi-page output into `-1`, `-2`, ... so
#   the manual only ever embeds PNGs.
set -e
cd "$(dirname "$0")/../.."

rasterize() {
    # $1: source file (any format typst can produce); $2: destination
    # stem (no extension). A single-page source becomes "$2.png"; a
    # multi-page PDF becomes "$2-1.png", "$2-2.png", etc.
    local src="$1" stem="$2"
    case "$src" in
        *.pdf)
            local pages
            pages="$(pdfinfo "$src" | awk '/^Pages:/ {print $2}')"
            if [ "$pages" = "1" ]; then
                pdftoppm -png -r 300 -f 1 -l 1 "$src" "$stem"
                mv "${stem}-1.png" "${stem}.png" 2>/dev/null || mv "${stem}-01.png" "${stem}.png"
            else
                pdftoppm -png -r 300 "$src" "$stem"
                for f in "$stem"-0*.png; do
                    [ -f "$f" ] || continue
                    mv "$f" "$(echo "$f" | sed -E 's/-0+([0-9]+)\.png$/-\1.png/')"
                done
            fi
            ;;
        *)
            cp "$src" "$stem.${src##*.}"
            ;;
    esac
}

for src in docs/manual-snippets/*.typ; do
    [ -f "$src" ] || continue
    name="$(basename "$src" .typ)"
    outdir="docs/manual-snippets/$name"
    rm -rf "$outdir"
    mkdir -p "$outdir"

    # Any snippet whose own story is about variant/preview needs all
    # four combinations shown, not just plain/preview -- otherwise the
    # manual could never demonstrate that the two axes compose
    # independently. bundle() already encodes both axes in each output's
    # own filename (manuscript.pdf / manuscript-X.pdf /
    # manuscript-preview.pdf / manuscript-X-preview.pdf), so the four
    # compiles below never collide on their own. Each such snippet picks
    # its own non-default variant name -- looked up here since it isn't
    # otherwise derivable from the file.
    four_way_variant=""
    case "$name" in
        bundle-combo-palimpsest-checkitoff) four_way_variant="tracked" ;;
        bundle-variant-preview) four_way_variant="internal" ;;
    esac

    if [ -n "$four_way_variant" ]; then
        for flags in "" "--input variant=$four_way_variant" \
                     "--input preview=true" \
                     "--input variant=$four_way_variant --input preview=true"; do
            tmp="$(mktemp -d)"
            typst compile --features bundle --format bundle --ppi 300 --root .. $flags "$src" "$tmp"
            for f in "$tmp"/*; do
                base="$(basename "$f")"
                stem="${base%.*}"
                rasterize "$f" "$outdir/$stem"
            done
            rm -rf "$tmp"
        done
        echo "  $name -> $outdir/ (4 combinations)"
        continue
    fi

    if grep -qE '#document\(|bundle\.with\(|show: *(contexture\.)?bundle\b' "$src"; then
        tmp_plain="$(mktemp -d)"
        tmp_preview="$(mktemp -d)"
        typst compile --features bundle --format bundle --ppi 300 --root .. "$src" "$tmp_plain"
        typst compile --features bundle --format bundle --ppi 300 --root .. --input preview=true "$src" "$tmp_preview"
        for f in "$tmp_plain"/*; do
            base="$(basename "$f")"
            stem="${base%.*}"
            rasterize "$f" "$outdir/${stem}-plain"
        done
        for f in "$tmp_preview"/*; do
            base="$(basename "$f")"
            stem="${base%.*}"
            case "$stem" in
                *-preview) rasterize "$f" "$outdir/${stem}" ;;
                *) rasterize "$f" "$outdir/${stem}-preview" ;;
            esac
        done
        rm -rf "$tmp_plain" "$tmp_preview"
    else
        typst compile --ppi 300 --root .. "$src" "$outdir/result-plain.png"
        typst compile --ppi 300 --root .. --input preview=true "$src" "$outdir/result-preview.png"
    fi
    echo "  $name -> $outdir/"
done

echo "Snippets regenerated. Compiling manual(s)..."
for manual in docs/manual*.typ; do
    [ -f "$manual" ] || continue
    typst compile --root .. "$manual"
    echo "  $manual"
done

echo "Done."
