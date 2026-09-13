#import "../../lib.typ": *

// Same term() as the glossary quickstart, now doing one more thing:
// highlighting its own body whenever preview() is on -- a debug view of
// where every anchor sits, never part of the real deliverable.
//
// note() is new: an aside that only renders at all -- box, text, and
// all -- when variant() is "internal". Its anchor is still registered
// every time, so open-notes below can always find it, but its content
// only *exists* in the internal variant. That's the difference between
// the two axes: preview changes how something already there is shown;
// variant decides whether it's there at all.

#let term(id, body) = {
  anchor("demo-term", (id: id, body: body))
  if preview() {
    box(fill: yellow.lighten(80%), inset: 2pt, radius: 1pt)[#body]
  } else {
    body
  }
}

#let note(body) = {
  anchor("demo-note", (body: body))
  if variant() == "internal" {
    box(fill: red.lighten(90%), inset: 4pt, radius: 2pt, width: 100%)[
      #text(style: "italic", size: 0.9em)[Reviewer note: #body]
    ]
  }
}

#let render-open-notes() = context {
  let hits = anchors("demo-note")
  if hits.len() == 0 {
    [No open notes.]
  } else {
    for h in hits [- #h.value.body (p. #h.location().page())]
  }
}

#let open-notes = satellite(
  "open-notes",
  render: () => render-open-notes(),
  applicable: () => variant() == "internal",
)

#show: bundle.with(
  template: body => {
    set page(width: 16.6cm, height: auto, margin: 12pt)
    set text(size: 10.5pt)
    body
  },
  documents: (open-notes,),
)

= Methods

The trial used #term("itt")[intention-to-treat] analysis throughout.

#note[Double-check this matches the pre-registration.]

Randomisation used #term("block")[permuted blocks] of size 4.
