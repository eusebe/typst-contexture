#import "../../../typst-palimpsest/lib.typ" as palimpsest
#import "../../../typst-checkitoff/lib.typ" as checkitoff
#import "../../lib.typ": bundle

// The flagship "composition" example: two independently-developed
// packages, each built on contexture and neither aware the other
// exists, combined in one compile through nothing more than one shared
// `documents:` list. `letter(...)` and `checklist(...)` are each just a
// `satellite(...)` value; `bundle(...)` (this package, not either of
// theirs) is the only thing that ever calls `document(...)`.

#let tiny-checklist = (
  name: "TINY",
  full-name: [Tiny reporting checklist],
  items: (
    (section: "Methods", topic: "Randomisation", group: none, id: "1",
      description: [How the allocation sequence was generated.]),
    (section: "Methods", topic: "Outcome assessment", group: none, id: "2",
      description: [How the primary outcome was assessed.]),
  ),
)

#let my-template(body) = {
  set page(width: 16.6cm, height: auto, margin: 12pt)
  set text(size: 10.5pt)
  body
}

#let exchanges = palimpsest.reviewer(1)[
  #palimpsest.exchange(<r1-1>)[Please clarify whether outcome assessment was blinded.][
    Blinding is now specified. #palimpsest.pinpoint(<r1-1>)
  ]
]

#show: bundle.with(
  template: my-template,
  documents: (
    palimpsest.letter(exchanges: exchanges),
    checkitoff.checklist(checklist: tiny-checklist),
  ),
)

// Item 1 has nothing to do with this reviewer exchange -- check() just
// renders its own text at its own spot, independently of passage().
#checkitoff.check("1")[Randomisation used a computer-generated sequence.]

// Item 2, though, IS the reviewer exchange: the added text is both a
// tracked revision AND the manuscript's answer to item 2. check(id, body)
// and passage() would each render their own body -- used together on
// the exact same span, that would print it twice. check(id)'s bare,
// point-marker form registers item 2's coverage without rendering
// anything; passage() is the only call that actually prints the text,
// once, and handles its tracked-mode marks.
#palimpsest.passage(<r1-1>)[
  The primary outcome was assessed #palimpsest.add[by a rater blinded to group assignment].
]
#checkitoff.check("2")
