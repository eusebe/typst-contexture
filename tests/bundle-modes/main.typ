#import "../../lib.typ": *

// Regression test for the exact bug found combining palimpsest and
// checkitoff (MULTI-DOCUMENT-BUNDLE-DESIGN.md §1): two satellites with
// different, independent applicability rules on `variant`/`preview`
// must never interfere with each other.
//
// - "note" mimics checkitoff's checklist: built only when variant == plain
//   AND preview is off (its content would be misleading otherwise).
// - "tracked-only" mimics a satellite that only makes sense in tracked
//   variant (nothing real needs this today, it exists purely to prove
//   `variant` and `preview` don't leak into each other).
//
// Run compile.sh to exercise all four (variant, preview) combinations
// plus `--input only=` and `strict:`.

#let note = satellite(
  "note",
  applicable: () => variant() == "plain" and not preview(),
  render: () => [This satellite only builds under variant=plain, preview=false.],
)

#let tracked-only = satellite(
  "tracked-only",
  applicable: () => variant() == "tracked",
  render: () => [This satellite only builds under variant=tracked.],
)

#show: bundle.with(
  documents: (note, tracked-only),
)

= Manuscript

#anchor("demo-item", (id: "1"))
Some content.
#context [Variant: #variant() --- Preview: #preview()]
