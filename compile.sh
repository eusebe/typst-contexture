#!/bin/bash
echo "🚀 Compiling Typst Contexture..."
cd "$(dirname "$0")"

status=0

# bundle-modes: the 4 (variant, preview) combinations, checking that
# each satellite's own applicable() is respected independently — the
# direct regression test for the bug found combining palimpsest and
# checkitoff (see the test file's own comment). Passing an explicit output
# path makes `typst compile --format bundle` create a directory of that
# name holding one file per named document(), instead of the default
# "<input-stem>/" directory every combo would otherwise share and
# overwrite.
dir="tests/bundle-modes"
for combo in "plain:false" "plain:true" "tracked:false" "tracked:true"; do
  variant="${combo%%:*}"
  prev="${combo##*:}"
  out="$dir/out-$variant-$prev"
  rm -rf "$out"
  if ! typst compile --features bundle --format bundle --root . --input variant="$variant" --input preview="$prev" "$dir/main.typ" "$out/result" 2>&1 | grep -v "^warning\|hint"; then
    :
  fi
  docs=$(ls "$out/result" 2>/dev/null | tr '\n' ' ')
  echo "variant=$variant preview=$prev -> ${docs:-<none produced>}"
done

# bundle-anchors: cross-document anchor resolution + side-content.
dir="tests/bundle-anchors"
rm -rf "$dir/out" "$dir/out-only-none"
typst compile --features bundle --format bundle --root . "$dir/main.typ" "$dir/out/result" 2>&1 | grep -v "^warning\|hint"
typst compile --features bundle --format bundle --root . --input only= "$dir/main.typ" "$dir/out-only-none/result" 2>&1 | grep -v "^warning\|hint"
echo "bundle-anchors (default) -> $(ls "$dir/out/result" 2>/dev/null | tr '\n' ' ')"
echo "bundle-anchors (only=)   -> $(ls "$dir/out-only-none/result" 2>/dev/null | tr '\n' ' ')"

# bundle-strict-fail: EXPECTED TO FAIL.
dir="tests/bundle-strict-fail"
if typst compile --features bundle --format bundle --root . "$dir/main.typ" "$dir/out/result" 2>/dev/null; then
  echo "❌ $dir: expected a strict-mode compile failure, but it compiled successfully"
  status=1
else
  echo "✅ $dir: failed to compile as expected (strict mode)"
fi

exit $status
