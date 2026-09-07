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

#let snippet(name, embed) = {
  code-of("manual-snippets/" + name + ".typ")
  v(0.5em)
  embed("manual-snippets/" + name + "/")
  v(1em)
}

#align(center)[
  #v(0.5cm)
  #text(size: 1.8em, weight: "bold")[contexture]
  #v(0.2em)
  #text(size: 1.1em, style: "italic")[User manual]
  #v(0.8cm)
]

#outline(indent: auto)
#pagebreak()

= What this package is for

Typst's experimental bundle export (`--features bundle --format bundle`) lets one compile produce several named documents that share one introspection space: a `query()` run from any one of them sees content laid out in *all* of them, with real, final page numbers --- because they were genuinely composed together, in the same pass. `contexture` is the backend that turns that raw capability into something pleasant to build on: one primitive to anchor a piece of data anywhere in the bundle and resolve it from anywhere else (`anchor`/`anchors`), one function that owns the only `document(...)` call in the whole bundle so independently-written packages never fight over it (`bundle`/`satellite`), two small compile-time flags shared by every package built on it (`variant`/`preview`), and a common way to report something wrong without necessarily failing the build (`diagnose`/`set-strict`).

`contexture` itself knows nothing about revisions, checklists, glossaries, or any other specific document type --- it only knows how to anchor data, resolve it across documents, and hand out real files at the end. Every example in the next few chapters builds something new directly on these primitives, with no other package involved at all, to show the mechanism stands on its own two feet. Only in the last chapter, "Composing independent packages," does a *pair* of real packages built on `contexture` --- `@preview/palimpsest` and `@preview/equator` --- enter the picture, not as this package's reason to exist, but as one further demonstration: that tools built independently on this backend, by people who've never seen each other's code, compose without friction.

= What else you could build

The examples ahead are one shape of a much larger family. Anything with the form "a source document, plus a companion that cites it with real page numbers, computed in the same pass" fits the same three-piece pattern: an anchor at each interesting location, a satellite that queries them, `bundle` to produce both files. None of the following exist as packages today --- they're sketches, meant to show the range this covers, not a roadmap:

- *A list of figures or tables*, generated instead of hand-maintained --- immune to renumbering when a figure moves, impossible to forget to update.
- *A glossary or index of terms* --- exactly the worked example in the next chapter, but just as at home in a legal contract's list of defined terms or a textbook's index.
- *An answer key*, kept separate from the exam it belongs to, citing the real question numbers and page each one landed on after layout.
- *An executive summary* that auto-cites the real page of whichever section of the full report it's summarizing.
- *A preview/final split with nothing to do with revision tracking* --- a form whose preview build shows field ids or validation state inline (via `preview()`), never present in the version actually handed to someone.
- *Supplementary materials* that cite "as shown in Figure 3, p. 7" of a main paper compiled in the very same pass, so the citation can never drift out of sync with a page a late edit renumbered.

Each is the same handful of primitives from the next two chapters, arranged differently --- nothing app-specific ever needs to live inside `contexture` itself for any of them to work.

= Installation and compiling

#code("#import \"@preview/contexture:0.1.0\": *")

A bundle compiles with the `bundle` feature and format flags Typst's experimental export requires; everything else about *how many* files come out, and what they're named, is decided by what's listed under `documents:` (see "`satellite` and `bundle`" below), not by anything on the command line:

#code("typst compile --features bundle --format bundle main.typ")

Two flags, read by `variant()`/`preview()`, are available to every satellite regardless of which package defined it --- see "Two independent compile axes" below for why there are two, not one:

#code(
  "typst compile --features bundle --format bundle --input variant=tracked main.typ\n" +
  "typst compile --features bundle --format bundle --input preview=true main.typ"
)

= The anchor primitive: `anchor`, `anchors`

/ `anchor(kind, payload)`: marks the current location with a namespaced, queryable piece of data. `kind` namespaces it so two unrelated packages picking the same `id` scheme never collide --- by convention, prefixed with the owning package's name (`"equator-item"`, `"palimpsest-passage"`). `payload` is whatever that package needs back later --- entirely opaque to `contexture` itself. Deliberately renders nothing on its own: emitting the metadata and deciding how (or whether) to render content around it are two different concerns, left to the caller.
/ `anchors(kind)`: every anchor of that kind, in document order, from *anywhere in the bundle* --- including a document other than the one this is called from, which is the entire point. Must be called from within a `context`.

This pair is the one mechanism every "cite this spot from another document, with its real page number" feature in this ecosystem is built from. The example below builds a small one from scratch: `term()` anchors a short definition where it's first used in the manuscript; a `glossary` satellite lists every one of them with the real page it was found on. Neither function exists in `contexture` itself --- this is exactly what a package built on it looks like, in miniature:

#code-of("manual-snippets/bundle-glossary-basics.typ")

`manuscript.pdf`:

#shot("manual-snippets/bundle-glossary-basics/manuscript-plain.png")

`glossary.pdf`, from the very same compile, citing the real pages the manuscript above was just laid out with:

#shot("manual-snippets/bundle-glossary-basics/glossary-plain.png", width: 55%)

== Re-emitting stored content: `strip-labels`

A term's `body` can be arbitrary content, including a labelled figure --- and re-emitting that figure verbatim into the glossary would otherwise plant a second copy of its label, which Typst rejects outright as a duplicate. `strip-labels(node)` reconstructs `node` with every label removed, and --- specifically for a `figure`, a labelled block equation, or a `heading` --- pins the *real*, already-resolved number of the true original onto the copy's own `numbering`, read directly via a fresh `query()` of that label. The copy shows the same number as the original; only the original stays a real, referenceable target.

#code-of("manual-snippets/bundle-glossary-figure.typ")

Both the manuscript and the glossary show "Table 1" --- the genuine, resolved number, not a guess:

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  shot("manual-snippets/bundle-glossary-figure/manuscript-plain.png", caption: [manuscript.pdf]),
  shot("manual-snippets/bundle-glossary-figure/glossary-plain.png", caption: [glossary.pdf]),
)

`collect-metadata(body, tag)` and `collect-labels(body)` are the structural building blocks `strip-labels` and `anchor`/`anchors` themselves are built from --- a purely structural walk of an in-memory content tree, no `context` or layout involved, exposed directly for a package that needs to inspect content it's holding but hasn't (or may never) place into any document this compile. `is-blank(body)` and `is-textual(body)` answer two narrower questions the same way: whether `body` contains any real text at all (used by both palimpsest and equator to flag an accidentally empty marking call), and whether `body` is safe to wrap in literal quotation marks without producing a stray quote mark floating above a figure or table.

== A fuller example: list of figures

The glossary above makes the mechanism easy to follow, at the cost of being a little toy --- two terms, one line each. Here's a version closer to what you'd actually paste into a real project: a "List of Figures" companion, several entries deep, spanning a page break, each citing the real page its figure landed on.

#code-of("manual-snippets/bundle-list-of-figures.typ")

`manuscript.pdf` --- three ordinary figures across two pages, nothing about them different from any other Typst document:

#grid(
  columns: (1fr, 1fr),
  gutter: 1em,
  shot("manual-snippets/bundle-list-of-figures/manuscript-plain-1.png", caption: [page 1]),
  shot("manual-snippets/bundle-list-of-figures/manuscript-plain-2.png", caption: [page 2]),
)

`list-of-figures.pdf`, from the same compile:

#shot("manual-snippets/bundle-list-of-figures/list-of-figures-plain.png", width: 70%)

`fig()` here numbers its own entries by the order `anchor()` calls arrive in, rather than reading Typst's built-in `counter(figure)` --- simpler, and exactly right as long as `fig()` is the only thing creating figures in the document (true here; a project mixing `fig()` with bare `figure()` calls would want `counter(figure).at(hit.location())` instead, the same real-counter trick `strip-labels` already uses above). Either way, the page numbers are never guessed or hand-typed --- they come from `location().page()` on the anchor Typst itself placed, in the very compile that produced `manuscript.pdf`.

= `satellite` and `bundle`: the shared pilot

`document(...)` --- Typst's own primitive for naming one output of a bundle compile --- cannot be nested inside another `document(...)` call. That means two packages each shipping their *own* pilot (each calling `document(...)` internally, each convinced it alone owns the split between the manuscript and everything else) can never be stacked in the same compile. `contexture.bundle` is the fix: the *only* place, in this entire ecosystem, that ever calls `document(...)`. Every package built on `contexture` instead exposes a small constructor that returns a `satellite(...)` value --- inert data, not a `document(...)` call --- and the author lists as many of those as they like under one shared `documents:`.

/ `satellite(name, render:, applicable:, side-content: none)`: describes one document to build alongside the manuscript. `name` is the base filename (`bundle` appends the variant/preview suffix). `render() -> content` produces this document's content, called only when `applicable() -> bool` (default: always) says yes for the current compile --- neither takes `variant`/`preview` as parameters: they're plain global functions, so a satellite that cares calls `variant()`/`preview()` itself, right inside its own closure, rather than having them threaded in (equator's checklist does exactly this in its own `applicable`, below).
/ `bundle(template:, documents: (), strict: false, manuscript-name: "manuscript", body)`: the pilot itself, called via `#show: bundle.with(...)` --- `body` is the rest of the document (typically `#include "manuscript.typ"`). Builds the manuscript (`template(body)`) plus every satellite whose `applicable` returns true, each as its own real Typst document sharing this one compile's introspection space with all the others.

From `bundle-glossary-basics.typ` above, the wiring is just:

#code(
  "#let glossary = satellite(\"glossary\", render: () => render-glossary())\n\n" +
  "#show: bundle.with(\n" +
  "  documents: (glossary,),\n" +
  ")"
)

*Restricting a compile to fewer documents:* `--input only=<comma-separated satellite names>` restricts a single compile to the manuscript plus just the named satellites --- `--input only=` with nothing after it produces the manuscript alone. A command-line choice for a fast preview, not a property of the project: naming a satellite under `only:` that declines to build itself this compile (its own `applicable` says no) doesn't force it to.

*`side-content`:* content a satellite wants placed in the manuscript regardless of whether *it itself* gets built this compile. Exists for one confirmed need so far: a satellite whose own anchors need to be registered even when a fast preview skips it (`--input only=manuscript`) --- otherwise some other check elsewhere in the manuscript (e.g. "this anchor has no matching response") would false-positive on every single anchor, purely because the satellite that would have answered them wasn't built this time. Paired with `collect-anchors(body, kind)` --- the structural counterpart to `anchors`, finding anchors already sitting inside an in-memory `body` that was never placed into any document --- and `reemit(collected)`, which registers one such found anchor as if it had been placed here.

= Two independent compile axes: `variant`, `preview`

/ `variant()`: `"plain"` (default) or `"tracked"`, from `--input variant=...`. An *intrinsic* property of what the manuscript's own content means --- do revision marks show, styled, or not. A package with no such concept (a reporting-checklist package, say) never touches this and always sees `"plain"`.
/ `preview()`: `true`/`false`, from `--input preview=true`. Whether to show debug highlighting for wherever a package's own anchors sit in the manuscript --- a drafting aid, never present in a real deliverable, and never a reason to change what a document's content *means* (that's `variant`'s job).

These are deliberately two separate flags, not one shared "mode" string, because of a concrete bug found combining two real packages built independently on the same idea: each treated "anything other than the default" as "my own alternate mode is on," so a preview request meant for one package silently flipped the other's rendering too, because both happened to read the same flag under incompatible vocabularies (`clean`/`tracked` vs `clean`/`annotated`, in the flag's very first version). Splitting the concept into two flags with two clearly distinct meanings, each with its own boolean-or-enum shape, made that collision structurally impossible rather than merely documented against. (`variant()`'s own default sentinel was renamed once more since, from `"clean"` to today's `"plain"` --- `"clean"` was itself borrowed from one specific consumer's vocabulary, not a neutral word; see `MULTI-DOCUMENT-BUNDLE-DESIGN.md` for the full story.)

Two independent, made-up satellites below --- neither is palimpsest's or equator's --- each read the two axes directly, to show they're plain, package-agnostic values, and that they never leak into each other:

#code-of("manual-snippets/bundle-modes.typ")

Compiling this one file four ways produces four genuinely different combinations, each satellite gated independently:

#table(
  columns: (auto, 1fr),
  align: (left, left),
  stroke: 0.5pt + gray,
  table.header[*Compile*][*Files produced*],
  [(no flags)], [`manuscript.pdf`, `note.pdf`],
  [`--input variant=tracked`], [`manuscript-tracked.pdf`, `tracked-only-tracked.pdf`],
  [`--input preview=true`], [`manuscript-preview.pdf`],
  [`--input variant=tracked --input preview=true`], [`manuscript-tracked-preview.pdf`, `tracked-only-tracked-preview.pdf`],
)

`note` builds exactly when `variant() == "plain"` and `preview()` is off; `tracked-only` builds exactly when `variant() == "tracked"`, regardless of `preview()`. Turning `preview` on never affects whether `tracked-only` builds, and switching `variant` never affects `note`'s own `preview`-gating --- the two axes compose freely because neither satellite (nor `bundle` itself) ever collapses them into one shared value.

`bundle` folds both axes into the manuscript's own filename independently, in that same orthogonal way --- `manuscript.pdf` / `manuscript-tracked.pdf` / `manuscript-preview.pdf` / `manuscript-tracked-preview.pdf` --- so a preview compile never silently overwrites the plain deliverable, whatever `variant` happens to be at the same time, and a tracked-and-preview compile is simply both suffixes, in order.

= Diagnostics: `diagnose`, `set-strict`

Typst has no public API to emit a soft compiler warning from user code, so the closest available approximation is a visible marker rendered directly at the fault location, which most Typst editors preview live.

/ `diagnose(message, always: false)`: reports a problem at the call site. Under `set-strict(true)`, always a hard `panic` --- a real compile error, in any mode. Otherwise, a visible inline marker --- muted specifically when `variant() == "plain"` and `preview()` is off (`always: false`, the default), since that's the file most likely to leave this codebase and reach someone who never asked to see an internal warning; shown unconditionally when `always: true`, for a diagnostic embedded in a document that is *never* itself the deliverable (a generated report, an internal checklist) where muting it would mean it's never seen at all.
/ `set-strict(v)`: turns every `diagnose(...)` call, from any package built on `contexture`, in any document, into a hard error at once --- one shared CI gate rather than one per package. Normally set via `bundle(strict: true, ...)`, not called directly.

`xref` (below) always passes `always: true` --- a broken cross-reference should never be silently invisible even in the real, submitted deliverable:

#code-of("manual-snippets/xref-basic.typ")

#shot("manual-snippets/xref-basic/result-plain.png")

= `xref`: cross-references with a real page number

`xref(label)` behaves like `@label`/`ref(label)` --- which already resolves across documents in a bundle, a satellite's own `@tab-results` renders the manuscript's real "Table 3" --- but appends the real page number: "Table 3, p. 14". Explicit rather than a bare `@label`, so it stays correct even if a future document duplicates the same label, where a bare `ref` would become ambiguous between the two copies. It operates on plain Typst labels (figures, headings, equations, ...), not on `contexture.anchor()` --- a separate, narrower tool from the anchor primitive above, for the common case where a real Typst label already exists and only the page number needs adding.

= Composing independent packages <sec-composing>

Two packages built independently on `contexture`, neither aware the other exists, combine by nothing more than listing both of their satellites under the same `documents:` --- the scenario the whole design exists for. `@preview/palimpsest`'s `letter(...)` and `@preview/equator`'s `checklist(...)` are each just a `satellite(...)` value; `bundle(...)` (this package, not either of theirs) is still the only thing that ever calls `document(...)`.

#code-of("manual-snippets/bundle-combo-palimpsest-equator.typ")

One compile, four ways --- each producing a genuinely different combination of files, exactly like the made-up example in "Two independent compile axes" above, now with two real packages instead of a toy demonstration:

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

`checklist.pdf` only ever comes out of the first, plain compile --- `checklist(...)`'s own `applicable` rule declines under either a tracked variant or preview mode, since either could shift page breaks relative to the real, submitted manuscript (see equator's manual for the full reasoning). Palimpsest's `letter(...)` has no such restriction --- a response letter is meaningful, and useful to preview, in every combination.

The last (tracked *and* preview) compile shows both packages' overlays together, in the same document, each independent of the other --- item 1 gets equator's full `preview` highlight box (its own span has nothing to do with the reviewer exchange), item 2 gets palimpsest's tracked-mode revision mark *and* a small `[2]` tag from equator's own bare, point-marker form (see below for why it's a tag with no box, rather than a full highlight):

#shot("manual-snippets/bundle-combo-palimpsest-equator/manuscript-tracked-preview.png")

*Rule 1 --- don't nest one package's marking function inside another's.* `#check(...)[#passage(...)[...]]` and the reverse each break something, for the same underlying reason both times: `passage()`'s own visual rendering and `check()`'s own preview-mode highlighting are each wrapped in a `context` block (needed to read live style state), and a `context` block is structurally opaque to anything trying to inspect its contents *before* layout. Nest `passage()` inside `check()` and `check()`'s own blank-content self-check can no longer see the real text inside --- it misreports the passage as empty, in *any* mode, not just under `preview: true`. Nest `check()` inside `passage()` and, under `preview: true` specifically, `passage()`'s own scan for `add`/`del`/`rep` marks can no longer see them --- it misreports "contains no mark". Two different symptoms, one cause, no nesting order avoids it.

*Rule 2 --- don't call them as two independent, rendering siblings on the exact same span either.* This is item 1's pattern above, and it's correct *there* only because item 1's span and the reviewer exchange are two different things. Try it on the *same* span --- the reviewer's requested change genuinely is the manuscript's answer to a checklist item, item 2's case --- and both calls render their own `body`, so the text prints twice, plainly, visibly duplicated:

#code(
  "// DON'T -- prints the sentence twice when body is the same text:\n" +
  "#check(\"2\")[The primary outcome was assessed by a rater blinded to group assignment.]\n" +
  "#passage(<r1-1>)[\n" +
  "  The primary outcome was assessed #add[by a rater blinded to group assignment].\n" +
  "]"
)

This is exactly why `check` (like palimpsest's own `passage`) accepts two shapes rather than one: `check(id, body)` for the common case, and a bare `check(id)` --- no second argument at all --- for exactly this collision. The bare form registers the same metadata (same page resolution, same everything `checklist.pdf` needs) but renders nothing beyond that small `[2]` tag under `preview: true`, and nothing at all in the plain compile --- there's no `body` here to duplicate or to nest, which is the whole point:

#code(
  "// item 2's actual code, above -- one render, one registration:\n" +
  "#passage(<r1-1>)[\n" +
  "  The primary outcome was assessed #add[by a rater blinded to group assignment].\n" +
  "]\n" +
  "#check(\"2\")"
)

Neither rule is specific to palimpsest or equator. Both follow directly from `anchor`'s own design: an anchor's content is rendered by whatever wraps it, structurally, so a structural pre-layout scan can only see through wrappers it already knows about (rule 1), and two independent calls that each render the same content will always render it twice, since nothing about `bundle`, `satellite`, or `anchor` deduplicates rendered output across calls (rule 2). Any future package built on `contexture` whose marking function renders its own `body` should expose the same two shapes --- a full form for the common case, and a bare, render-free form for when its own span coincides with something another package already renders (the way palimpsest's own `passage(anchors, body)`/`passage(body)` already does, for an unrelated reason --- arity dispatch turns out to be a natural fit for "this call sometimes needs less than its full argument list" in general, not just for this one case). Palimpsest's own manual walks through rule 1 in more depth, including the two failure modes as they actually looked before the fix; equator's manual covers `check(id)`'s own signature and trade-offs.
