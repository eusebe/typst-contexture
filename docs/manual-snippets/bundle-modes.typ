#import "../../lib.typ": *

// Two independent, made-up satellites, each reading the two shared
// compile axes directly -- neither is palimpsest's or equator's, to show
// that `variant`/`preview` are plain, package-agnostic flags any
// satellite can hook into, and that they never leak into each other.

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
  template: body => {
    set page(width: 16.6cm, height: auto, margin: 12pt)
    set text(size: 10.5pt)
    body
  },
  documents: (note, tracked-only),
)

= Manuscript

#context [Variant: #variant() --- Preview: #preview()]
