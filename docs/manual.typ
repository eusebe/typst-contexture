// The real manual --- progressive, one primitive at a time. Imports
// NOTHING from contexture and runs no package code: every result shown
// below is a PNG produced by actually compiling a real file under
// docs/manual-snippets/, not a simulation. Regenerate everything with:
//   bash docs/manual-snippets/compile.sh

#set document(title: "contexture — manual")
#set page(paper: "a4", margin: (x: 2.2cm, y: 2cm))
#set text(size: 10.5pt, font: "Libertinus Serif")
#set heading(numbering: "1.1.")
#set par(justify: true)
#show raw: set text(font: "Linux Libertine Mono", size: 0.85em)

#let code(src) = block(
  fill: luma(247), stroke: 0.5pt + luma(210), inset: 10pt, radius: 3pt, width: 100%,
  raw(src, block: true, lang: if src.starts-with("typst") { "sh" } else { "typ" }),
)

#let code-of(path) = code(read(path))

#let shot(path, caption: none, width: 100%) = block(width: width)[
  #block(stroke: 0.5pt + luma(210), inset: 4pt, radius: 3pt, width: 100%, image(path, width: 100%))
  #if caption != none [#text(size: 0.78em, fill: luma(120), style: "italic")[#caption]]
]

#let side-by-side(..shots) = grid(columns: shots.pos().len(), gutter: 1em, ..shots)

#align(center)[
  #v(0.5cm)
  #text(size: 1.8em, weight: "bold")[contexture]
  #v(0.2em)
  #text(size: 1.1em, style: "italic")[User manual]
  #v(0.8cm)
]

#outline(indent: auto)
#pagebreak()

= What contexture is for

Typst can compile one source file into several output documents at once (the experimental bundle export, `--features bundle --format bundle`) that all share one introspection space: a `query()` run from any one of them sees content laid out in *all* of them, with real, final page numbers, because they were genuinely composed together in the same pass.

`contexture` is a small toolkit built directly on that capability:

- *`anchor` / `anchors`* --- mark a spot in one document, read it back from any other, by real page.
- *`satellite` / `bundle`* --- one shared entry point that decides which documents come out of a compile, so several independent pieces of code can each contribute a document without fighting over how the split works.
- *`variant` / `preview`* --- two small flags any document you build can read, to change what a compile produces without adding a new one-off command-line flag for each idea.
- *`diagnose` / `set-strict`* and *`xref`* --- a couple of shared conveniences: a visible way to flag a problem, and a `@label` that also prints its real page number.

`contexture` itself has no opinion on what any of this is *for* --- no notion of revisions, checklists, glossaries, or any other specific kind of document. Every example in this manual is self-contained: a manuscript plus a couple of small functions written directly against these primitives, nothing else involved, to show that the toolkit stands on its own. Only the closing chapter, "Composing independent packages," brings in outside packages --- not because this manual needs them to make its point, but to show what it looks like when two packages built independently on `contexture` end up sharing a compile.

= Installation and compiling

#code("#import \"@preview/contexture:0.1.0\": *")

Producing more than one document from a single file needs Typst's bundle export:

#code("typst compile --features bundle --format bundle main.typ")

Every project built on `contexture` can also be compiled with two extra flags, explained in full in "Two independent compile axes" below:

#code(
  "typst compile --features bundle --format bundle --input variant=... main.typ\n" +
  "typst compile --features bundle --format bundle --input preview=true main.typ"
)

= Quickstart: a manuscript with a generated companion

The simplest thing to build on `contexture`: a manuscript, plus a second document generated from it. Below, a two-function glossary --- `term()` marks where a term is first defined; `render-glossary()` lists every term found anywhere in the bundle, each with the real page it landed on. Neither function is part of `contexture` --- this *is* what a package built on it looks like, complete:

#code-of("manual-snippets/bundle-glossary-basics.typ")

Compiling this exact file --- `bundle-glossary-basics.typ`, the one shown above, nothing else --- with `typst compile --features bundle --format bundle` produces two PDFs. The first is `manuscript.pdf`:

#shot("manual-snippets/bundle-glossary-basics/manuscript-plain.png")

That name has nothing to do with the file just compiled, which could be called anything (`main.typ`, `report.typ`, ...) --- it comes entirely from `bundle()`'s own `manuscript-name:` parameter, `"manuscript"` by default. More on this in "`satellite` and `bundle`" below.

`glossary.pdf`, from the very same compile:

#shot("manual-snippets/bundle-glossary-basics/glossary-plain.png", width: 55%)

Three things are happening, and the rest of this manual is one chapter per thing:

+ `term()` calls `anchor("demo-term", ...)` --- drops a small, named piece of data at this exact spot, then renders `body` as usual. Covered next, in "The anchor primitive."
+ `render-glossary()` calls `anchors("demo-term")` --- every anchor of that kind, anywhere in the bundle, each with a real `location()` to read a page number off. Same chapter.
+ `satellite("glossary", ...)` describes the second document; `#show: bundle.with(documents: (glossary,))` is what actually produces both PDFs from one compile. Covered in "`satellite` and `bundle`."

If what brought you here is specifically the `variant`/`preview` flags, skip ahead --- they get their own chapter, with a dedicated example, further down.

This same shape --- an anchor at each interesting spot, a satellite that queries them --- covers more than a glossary: a list of figures or tables (the next worked example), an index of defined terms, an answer key kept apart from the exam it belongs to, an executive summary that cites the real page of whatever it's summarizing, supplementary material that cites "as shown in Figure 3, p. 7" of a document compiled in the very same pass. Nothing app-specific has to live inside `contexture` for any of these to work --- each is the same handful of primitives, arranged differently.

= The anchor primitive: `anchor`, `anchors`

/ `anchor(kind, payload)`: marks the current location with a namespaced, queryable piece of data. `kind` namespaces the anchor so two unrelated pieces of code picking the same `id` scheme never collide --- prefix it with something specific to what you're building (`"glossary-term"`, `"figure-list-entry"`). `payload` is whatever you need back later --- entirely opaque to `contexture` itself. Deliberately renders nothing on its own beyond the metadata: emitting it and deciding how (or whether) to render content around it are two different jobs, left to the caller, exactly as `term()` above does both explicitly.
/ `anchors(kind)`: every anchor of that kind, in document order, from *anywhere in the bundle* --- including a document other than the one this is called from, which is the entire point. Must be called from within a `context`.

== Re-emitting stored content: `strip-labels`

A term's `body` can be arbitrary content, including a labelled figure --- and re-emitting that figure verbatim into the glossary would otherwise plant a second copy of its label, which Typst rejects outright as a duplicate. `strip-labels(node)` reconstructs `node` with every label removed, and --- specifically for a `figure`, a labelled block equation, or a `heading` --- pins the *real*, already-resolved number of the true original onto the copy's own `numbering`, read directly via a fresh `query()` of that label. The copy shows the same number as the original; only the original stays a real, referenceable target.

#code-of("manual-snippets/bundle-glossary-figure.typ")

Both the manuscript and the glossary show "Table 1" --- the genuine, resolved number, not a guess:

#side-by-side(
  shot("manual-snippets/bundle-glossary-figure/manuscript-plain.png", caption: [manuscript.pdf]),
  shot("manual-snippets/bundle-glossary-figure/glossary-plain.png", caption: [glossary.pdf]),
)

== Structural utilities

`collect-metadata(body, tag)` and `collect-labels(body)` are the structural building blocks `strip-labels` and `anchor`/`anchors` themselves are built from --- a plain walk of an in-memory content tree, no `context` or layout involved, exposed directly for code that needs to inspect content it's holding but hasn't (or may never) placed into any document this compile. `is-blank(body)` answers "does this contain any real text at all" (handy for flagging an accidentally empty call to something like `term()`); `is-textual(body)` answers "is this safe to wrap in literal quotation marks", i.e. free of any `figure`, `table`, or block equation that a stray quote mark would otherwise float above.

= A fuller example: list of figures

The glossary above makes the mechanism easy to follow, at the cost of being a little toy --- two terms, one line each. Here's a version closer to what you'd actually paste into a real project: a "List of Figures" companion, several entries deep, spanning a page break, each citing the real page its figure landed on.

#code-of("manual-snippets/bundle-list-of-figures.typ")

`manuscript.pdf` --- three ordinary figures across two pages, nothing about them different from any other Typst document:

#side-by-side(
  shot("manual-snippets/bundle-list-of-figures/manuscript-plain-1.png", caption: [page 1]),
  shot("manual-snippets/bundle-list-of-figures/manuscript-plain-2.png", caption: [page 2]),
)

`list-of-figures.pdf`, from the same compile:

#shot("manual-snippets/bundle-list-of-figures/list-of-figures-plain.png", width: 70%)

`fig()` numbers its own entries by the order `anchor()` calls arrive in, rather than reading Typst's built-in `counter(figure)` --- simpler, and exactly right as long as `fig()` is the only thing creating figures in the document (a project mixing `fig()` with bare `figure()` calls would want `counter(figure).at(hit.location())` instead, the same real-counter trick `strip-labels` uses above). Either way, the page numbers are never guessed or hand-typed --- they come from `location().page()` on the anchor Typst itself placed, in the very compile that produced `manuscript.pdf`.

= `satellite` and `bundle`: the shared pilot

`document(...)` --- Typst's own primitive for naming one output of a bundle compile --- cannot be nested inside another `document(...)` call. That rules out letting several independent pieces of code each call `document(...)` on their own: whichever runs second would be trying to nest its document inside whatever the first one already produced. `contexture.bundle` is the fix: the *only* place that ever calls `document(...)`. Anything built on `contexture` instead exposes a small constructor that returns a `satellite(...)` value --- inert data, not a `document(...)` call --- and the author lists as many of those as they like under one shared `documents:`, exactly as the quickstart above already did with `glossary`.

/ `satellite(name, render:, applicable:, side-content: none)`: describes one document to build alongside the manuscript. `name` is the base filename (`bundle` appends the variant/preview suffix, see next chapter). `render() -> content` produces this document's content, called only when `applicable() -> bool` (default: always) says yes for the current compile.
/ `bundle(template:, documents: (), strict: false, manuscript-name: "manuscript", body)`: the pilot itself, called via `#show: bundle.with(...)` --- `body` is the rest of the document, typically `#include "manuscript.typ"`. Builds the manuscript (`template(body)`) plus every satellite whose `applicable` returns true, each as its own real document sharing this one compile's introspection space with all the others.

`manuscript-name:` is the *only* thing that decides the manuscript's output filename --- it has no connection at all to the name of whatever `.typ` file you actually run `typst compile` on (every example in this manual compiles the snippet file shown directly, e.g. `bundle-glossary-basics.typ`, and still produces `manuscript.pdf`). A project that keeps its manuscript's prose in its own file, `#include`d into `body`, is free to name that file anything --- calling it `manuscript.typ` is only a common convention, not a requirement `bundle()` checks for. Every example in this manual takes the simplest route instead: the file you see printed *is* the file compiled, with the manuscript's own content written directly after `#show: bundle.with(...)`, no separate `#include` at all.

*Restricting a compile to fewer documents.* `--input only=<comma-separated satellite names>` restricts a single compile to the manuscript plus just the named satellites --- `--input only=` with nothing after it produces the manuscript alone, whatever `documents:` lists. A command-line choice for a fast preview, not a property of the project: naming a satellite under `only:` that declines to build itself this compile (its own `applicable` says no) doesn't force it to.

*`side-content`.* Content a satellite wants placed in the manuscript regardless of whether *it itself* gets built this compile. Useful when a satellite defines anchors that something elsewhere in the manuscript depends on for a check of its own (e.g. "does this passage have a matching answer somewhere?") --- skip the satellite via `only=` and, without `side-content`, that check would wrongly report every single one of them as missing, purely because the satellite that would have answered them wasn't built this time. Paired with `collect-anchors(body, kind)` --- the structural counterpart to `anchors`, finding anchors already sitting inside an in-memory `body` that was never placed into any document --- and `reemit(collected)`, which registers one such found anchor as if it had been placed here.

= Two independent compile axes: `variant`, `preview`

Two flags are available to any document built on `contexture`, read by two plain functions:

/ `variant()`: which *version of the truth* this compile is producing --- an intrinsic property of what the content itself means. `"plain"` by default (`--input variant=...` to change it); a project defines whatever other values make sense to it and reads them back with `variant() == "..."`. Code with no notion of variants never touches this at all, and always sees `"plain"`.
/ `preview()`: `true`/`false`, from `--input preview=true`. A drafting aid only: "show me my own working, temporarily" --- never a reason to change what a document's content *means* (that's `variant`'s job), only how much of the plumbing is made visible while writing.

The difference in one sentence: `variant` decides *whether something is there at all*; `preview` decides *how much you can see of how it got there*. They're independent on purpose, so a project can cross them freely rather than picking one axis and losing the other.

A small worked example, built on the same `term()` as the quickstart, plus one new function that only exists to make the difference concrete:

#code-of("manual-snippets/bundle-variant-preview.typ")

`term()` highlights its own body whenever `preview()` is on --- a debug view of where the anchors are, nothing else changes. `note()` is a document aside that only renders --- box, text, and all --- when `variant()` is `"internal"`; its anchor is still registered on every compile, so `open-notes` can always find it, but its content genuinely doesn't exist outside the internal variant. `open-notes` itself only builds under `variant() == "internal"` --- a document listing every open note has nothing to say about a variant that has none.

Compiling this one file four ways produces four different, genuinely independent combinations:

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.5pt + gray,
  table.header[*Compile*][*Files produced*],
  [(no flags)], [`manuscript.pdf`],
  [`--input variant=internal`], [`manuscript-internal.pdf`, `open-notes-internal.pdf`],
  [`--input preview=true`], [`manuscript-preview.pdf`],
  [`--input variant=internal --input preview=true`], [`manuscript-internal-preview.pdf`, `open-notes-internal-preview.pdf`],
)

#side-by-side(
  shot("manual-snippets/bundle-variant-preview/manuscript.png", caption: [(no flags)]),
  shot("manual-snippets/bundle-variant-preview/manuscript-preview.png", caption: [`preview=true`]),
)
#side-by-side(
  shot("manual-snippets/bundle-variant-preview/manuscript-internal.png", caption: [`variant=internal`]),
  shot("manual-snippets/bundle-variant-preview/manuscript-internal-preview.png", caption: [both together]),
)

Notice what stays constant across each pair: turning `preview` on never makes the reviewer note appear --- that's `variant`'s call, not `preview`'s --- and switching to the internal variant never highlights the terms on its own. Only the fourth compile, with both flags, shows both effects at once, each exactly as it looks alone. That independence is the entire reason these are two flags rather than one shared string: a single flag can only ever represent one axis at a time, and code that treats "anything other than the default" as "my own alternate behavior is on" has no way to tell *which* alternate behavior a caller meant. Two flags, two distinct questions, make that ambiguity impossible rather than merely avoided by convention.

`bundle` folds both axes into every filename independently, in the same orthogonal way --- so a preview compile never silently overwrites the plain deliverable on disk, whatever `variant` happens to be at the same time, and a compile using both is simply both suffixes, in order.

= Diagnostics: `diagnose`, `set-strict`

Typst has no public API to emit a soft compiler warning from user code, so the closest available approximation is a visible marker rendered directly at the fault location, which most Typst editors preview live.

/ `diagnose(message, always: false)`: reports a problem at the call site. Under `set-strict(true)`, always a hard `panic` --- a real compile error, in any mode. Otherwise, a visible inline marker --- muted specifically when `variant() == "plain"` and `preview()` is off (`always: false`, the default), since that's the file most likely to leave this codebase and reach someone who never asked to see an internal warning; shown unconditionally when `always: true`, for a diagnostic embedded in a document that is *never* itself the deliverable (a generated report, an internal checklist) where muting it would mean it's never seen at all.
/ `set-strict(v)`: turns every `diagnose(...)` call, anywhere in the bundle, into a hard error at once --- one shared CI gate rather than a check per document. Normally set via `bundle(strict: true, ...)`, not called directly.

`xref` (below) always passes `always: true` --- a broken cross-reference should never be silently invisible even in the real, submitted deliverable:

#code-of("manual-snippets/xref-basic.typ")

#shot("manual-snippets/xref-basic/result-plain.png")

= `xref`: cross-references with a real page number

`xref(label)` behaves like `@label`/`ref(label)` --- which already resolves across documents in a bundle, a satellite's own `@tab-results` renders the manuscript's real "Table 3" --- but appends the real page number: "Table 3, p. 14". Explicit rather than a bare `@label`, so it stays correct even if a future document duplicates the same label, where a bare `ref` would become ambiguous between the two copies. It operates on plain Typst labels (figures, headings, equations, ...), not on `contexture.anchor()` --- a separate, narrower tool for the common case where a real Typst label already exists and only the page number needs adding.

= Composing independent packages <sec-composing>

Everything above is self-contained --- no example so far needed anything beyond `contexture` itself. In practice, `contexture` is meant as a shared foundation that several packages build on at once. `@preview/palimpsest` (manuscript revision letters) and `@preview/equator` (reporting-guideline checklists) are two such packages, published independently of each other and of `contexture`, neither aware the other exists. Combining them needs nothing beyond listing both of their satellites under the same `documents:` --- the scenario the whole design exists for:

#code-of("manual-snippets/bundle-combo-palimpsest-equator.typ")

One compile, four ways, exactly like "Two independent compile axes" above, now with two real packages instead of a self-contained demonstration:

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.5pt + gray,
  table.header[*Compile*][*Files produced*],
  [(no flags)], [`manuscript.pdf`, `response.pdf`, `checklist.pdf`],
  [`--input variant=tracked`], [`manuscript-tracked.pdf`, `response-tracked.pdf`],
  [`--input preview=true`], [`manuscript-preview.pdf`, `response-preview.pdf`],
  [`--input variant=tracked --input preview=true`], [`manuscript-tracked-preview.pdf`, `response-tracked-preview.pdf`],
)

The last compile shows both packages' overlays together, in the same document, each independent of the other:

#shot("manual-snippets/bundle-combo-palimpsest-equator/manuscript-tracked-preview.png")

Building a marking function that renders its own content, the way `passage()` and `check()` both do here, raises exactly one extra question that a single-package example never has to answer: what happens when two such functions from two different packages meet on the same document, or even the same span? Two rules keep that safe --- never nest one package's marking function inside another's, and never call two of them as independent, rendering siblings on the exact same span (one of them needs a body-free form instead, to register coverage without printing the text twice). Both rules, why they're necessary, and the exact two-shape pattern (`check(id)` vs. `check(id, body)`) that resolves the second one, are documented where they belong: in palimpsest's and equator's own manuals, each under a section called "Combining with another `contexture` package."

= Where to go next

This manual covers `contexture` on its own --- everything above works with no other package installed. For what to build with it:

- Manuscript revisions and a reviewer response letter that cites the real pages: `@preview/palimpsest`'s own manual.
- Reporting-guideline checklists (CONSORT, PRISMA, SPIRIT, STARD, STROBE) that cite the real pages: `@preview/equator`'s own manual.
- Combining several such packages in one compile: "Composing independent packages" above, and the "Combining with another `contexture` package" section in each package's own manual.
