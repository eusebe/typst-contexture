#import "../../lib.typ": *

// A tiny satellite package, built from scratch out of contexture's
// primitives alone. `term()` anchors a short definition where it's
// first used; `render-glossary()` lists every one of them, in document
// order, with its real page number.

#let term(id, body) = {
  anchor("demo-term", (id: id, body: body))
  body
}

#let render-glossary() = context {
  let hits = anchors("demo-term")
  if hits.len() == 0 {
    [No terms defined.]
  } else {
    for h in hits [
      *#h.value.id* --- #h.value.body (p. #h.location().page())
      #linebreak()
    ]
  }
}

#let glossary = satellite("glossary", render: () => render-glossary())

#show: bundle.with(
  template: body => {
    set page(width: 16.6cm, height: auto, margin: 12pt)
    set text(size: 10.5pt)
    body
  },
  documents: (glossary,),
)

= Introduction

The trial used #term("itt")[intention-to-treat] analysis throughout.

= Methods

Randomisation used #term("block")[permuted blocks] of size 4.
