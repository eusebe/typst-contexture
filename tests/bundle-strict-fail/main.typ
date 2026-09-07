#import "../../lib.typ": *

// EXPECTED TO FAIL TO COMPILE — on purpose. strict: true must turn
// diagnose(..., always: true) into a hard error.

#show: bundle.with(strict: true)

= Manuscript

#diagnose("deliberate failure for the strict-mode regression test", always: true)
