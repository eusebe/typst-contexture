#import "../../lib.typ": *

// Exercises anchor()/anchors() resolving real pages across sibling
// documents (the core mechanic every package built on contexture relies
// on), plus `side-content`: "letter" is only built when `only:` allows
// it, but its `side-content` should still land in the manuscript
// whenever "letter" itself is skipped this compile — mirrors
// palimpsest's real need (register exchange metadata in the manuscript
// even on a manuscript-only preview compile).

#let report = satellite(
  "report",
  render: () => context {
    let hits = anchors("demo-item")
    [Found #hits.len() anchors.]
    for h in hits [
      #linebreak()
      id #h.value.id at p. #h.location().page()
    ]
  },
)

// A "note" anchor placed inside content that never gets rendered here
// (mirrors palimpsest's exchanges — evaluated eagerly as an argument, but
// its own document may never be built this compile).
#let unbuilt-exchanges = [#anchor("demo-note", (id: "x", text: "hello"))]

#let letter = satellite(
  "letter",
  applicable: () => false, // never built in this test — only side-content matters
  render: () => [unused],
  // Exercises collect-anchors()/reemit(): finds the "demo-note" anchor
  // structurally inside `unbuilt-exchanges` (never placed anywhere,
  // since "letter" itself never builds) and re-registers it here so it's
  // still queryable from the manuscript — the real need this pair of
  // functions exists for (palimpsest's letter satellite, see its own
  // docstring).
  side-content: collect-anchors(unbuilt-exchanges, "demo-note").map(reemit).sum(default: []),
)

#show: bundle.with(
  documents: (report, letter),
)

= Page one

#anchor("demo-item", (id: "a"))
Content A.

#pagebreak()

= Page two

#anchor("demo-item", (id: "b"))
Content B.

#context [Re-emitted "demo-note" anchors visible here: #anchors("demo-note").len()]
