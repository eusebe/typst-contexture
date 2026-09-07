#import "../../lib.typ": *

// Same idea as bundle-glossary-basics.typ, but one term's body is itself
// a labelled figure --- re-emitting it verbatim in the glossary would
// otherwise plant a second copy of <tab-doses>, which Typst rejects as a
// duplicate label. strip-labels() drops the label from the copy while
// pinning the real, original "Figure 1" number onto it, read directly
// off the true instance via a query --- so both copies show the same
// number, and only one of them is a real, referenceable target.

#let term(id, body) = {
  anchor("demo-term", (id: id, body: body))
  body
}

#let render-glossary() = context {
  for h in anchors("demo-term") [
    *#h.value.id* (p. #h.location().page()):
    #strip-labels(h.value.body)
    #v(0.5em)
  ]
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

= Methods

#term("doses")[
  #figure(
    table(columns: 2, [*Arm*], [*Dose*], [A], [10mg], [B], [Placebo]),
    caption: [Study drug doses.],
  ) <tab-doses>
]

As shown in @tab-doses, two arms were compared.
