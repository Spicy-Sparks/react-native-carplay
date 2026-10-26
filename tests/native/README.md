# CarPlay native regressions

Run `python3 tests/native/run-regressions.py` on macOS with Xcode.

The runner compiles the production Objective-C navigation and cover update methods
against Foundation test doubles. The controller enforces the five-level audio
hierarchy and supports delayed/failing completions; the image loader completes on
a background queue and the items reject UI mutations off the main thread.

Coverage: deep navigation, rapid taps, pop failure, disconnect/reconnect while a
pop is pending, cover loading and row image loading, a template class CarPlay
refuses to push (it raises NSInvalidArgumentException), search results arriving
in either argument order, and a selected row without its index. The unpatched
2.4.11 source fails the depth check; 2.4.12 terminates on the refused push. Pass a source file as the first argument to compare it.

This checks native method behavior. It does not substitute for a CarPlay session
in a release app connected to a vehicle.

The second harness compiles the production request delegates and completion
methods: search supersession, out-of-order replies, wrong-template and duplicate
replies, independent templates, overlapping search/list selections, cancellation,
and hidden versus removed search templates. Run `node --test
tests/request-ownership.cjs` for the JavaScript wrapper regressions on any host.
Set `CARPLAY_PACKAGE_ROOT` to test a patched consumer package and
`CARPLAY_SOURCE_KIND=lib` to exercise its compiled entry points.

The optional token-aware native methods require a new binary. The JavaScript
fallback for older binaries ignores obsolete replies across templates, but an
old native binary cannot restore the completion callbacks it already overwrote.
