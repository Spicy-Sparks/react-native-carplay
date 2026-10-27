# CarPlay native verification — 27 October 2026

The native CarPlay repairs now have executed macOS regression evidence and iOS
SDK compilation evidence. This is **not** a successful complete app build or a
physical vehicle acceptance test.

## Executed successfully

- Xcode 27.0 (27A266a), Apple clang 21.0.0, arm64 Mac mini.
- Both Foundation harnesses compile and run against the extracted production
  Objective-C methods. Navigation depth, rapid taps, failed pop, reconnect,
  background image callbacks, refused template classes, argument order and
  invalid indexes pass. Request supersession, wrong-template and duplicate
  responses, independent templates, overlapping search/list selections,
  cancellation, and hidden versus removed templates also pass.
- Three extraction regressions pass on Windows and macOS. The runner previously
  selected class-extension declarations instead of method implementations; fix
  `4bf8ff4` skips those declarations. It changes tests only.
- Six JavaScript request-wrapper regressions and the TypeScript build pass.
- Each brand's tracked patch applies to a pristine CarPlay 2.4.12 package.
  All four native `.m` files compile to objects for **both arm64 iPhoneOS and
  arm64 iPhoneSimulator SDK 27**: 16 successful compilations, no compiler errors.
  Deprecation/legacy warnings remain. Compiler flags and header/framework paths
  come from the corresponding existing CocoaPods target; prebuilt React
  framework slices are selected for the actual SDK.

The checked native source predates the test-only repair (fork `fa49de8`). Consumer
patch inputs are Lyra `767549769cb29ddd163f2a4b23cc7ffc4f7b71ed` and eSound
`110ada2811460b4758190edbe7892d91647dc846` (Git blob IDs). Both produce
`RNCarPlay.m` SHA-256
`cc18928738a8bdca2cf9debc48c2164a2af851c42d1a63777235420ea4c43bf6`.
The Mac's installed header environments are RN 0.87.1 for Lyra and RN 0.86.3 for
eSound; the eSound check is compatibility evidence against that installed
environment, not a claim that its entire current client is prepared for release.

## Complete app build: not verified green

A clean, isolated Lyra checkout `1d95bacecb2f511746206b66dec7a61c2e657817`
with exact Core pin `c06033e6ba5a499c2df241ea8a2736fad2f7f55f` passed the
release preflight, including all 154 required ancestors and canonical Core links.
Dependencies and Pods were copied with APFS copy-on-write into the owned QA
directory; only its CarPlay package was replaced with the freshly patched copy.

The trial was an unsigned Debug simulator build, with JavaScript bundling and
packager launch disabled. It was not a store archive or an app launch.

Initial preparation issues were resolved in that isolated directory: a generated
Codegen input needed to exist before compilation, and the ignored `Podfile.lock`
needed copying. The copied lock was byte-identical to the cloned Pods manifest.

The build then compiled all sources but failed linking Debug-only React Native
symbols (`Sealable`, `ShadowNode::getDebugName`). The copied framework advertised
Debug in its cache marker but exported none of these symbols; the cached Debug
tarball did export them. React Native's existing replacement script regenerated
the owned QA framework from that tarball, and its Debug symbols were verified.

The final build attempt was stopped by the disk-reserve guard: with concurrent
build work on the host, free space dropped below the 4 GiB reserve and eventually
below 1 GiB. **No successful full app build or signed binary resulted.**
Only owned QA copies/caches were removed, restoring approximately 8.6 GiB free.
Other build pipelines, their generated overlays, and primary checkouts were not
reset or cleaned.

## Hardware, audio and release limits

- No iPhone was connected to the checked Mac mini; no physical CarPlay test was
  executed. Keyboard input and the volume symptom remain unverified on a vehicle.
- The installed volume-manager observer and foreground callback already contain
  the earlier audio-session patch: they do not actively call `setCategory` or
  `setActive`. Comments mentioning those calls must not be counted as executable
  code. This does not identify the volume cause or prove what a shipped binary
  contains. No DSP/session change was made.
- At the initial Mac snapshot, installed CarPlay native files lacked the new
  request protocol despite the tracked patch. Primary release inputs also had
  Core-pin/dirty-checkout failures and were subsequently used by another build
  pipeline. Prepare aligned dependencies, exact source pins and CocoaPods inputs
  before a release; inspect the actual built binary for the request-aware native
  methods rather than inferring them from Git alone.
- No release, upload or support-case closure was performed by this verification.
  Native ownership/cleanup still requires a new iOS binary; OTA alone cannot
  supply the complete native repair.
