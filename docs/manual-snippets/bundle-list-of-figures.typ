#import "../../lib.typ": *

// A fuller example than the glossary above -- closer to something you
// might actually copy into a real project: a "List of Figures"
// companion, generated instead of hand-maintained, citing the real page
// each figure landed on. Numbers figures in anchor order (1, 2, 3, ...)
// rather than reading Typst's own figure counter -- simpler, and exact
// here since fig() is the only thing creating figures in this document;
// a project mixing fig() with bare figure() calls would want
// counter(figure).at(..) instead.

#let fig(caption, body) = {
  let content = figure(body, caption: caption)
  anchor("demo-figure", (caption: caption))
  content
}

#let render-list-of-figures() = context {
  let hits = anchors("demo-figure")
  for (i, h) in hits.enumerate() [
    *Figure #(i + 1).* #h.value.caption --- p. #h.location().page()
    #linebreak()
  ]
}

#let list-of-figures = satellite("list-of-figures", render: () => render-list-of-figures())

#show: bundle.with(
  template: body => {
    set page(width: 16.6cm, height: auto, margin: 12pt)
    set text(size: 10.5pt)
    body
  },
  documents: (list-of-figures,),
)

= Methods

#fig([Study flow diagram.], rect(width: 3cm, height: 1.5cm, align(center + horizon)[Flow]))

#lorem(90)
#pagebreak()

= Results

#fig([Primary outcome over time.], rect(width: 3cm, height: 1.5cm, align(center + horizon)[Chart A]))

#fig([Subgroup analysis.], rect(width: 3cm, height: 1.5cm, align(center + horizon)[Chart B]))
