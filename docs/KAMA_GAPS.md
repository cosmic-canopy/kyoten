# kama gaps and bugs

The running list of what kyoten hits in [kama](../../kama). Two kinds of entry:

- **BUG**: kama does something wrong. Each entry carries a repro, and these should be fixed upstream.
- **GAP**: kama does not do something yet. Some gaps belong upstream; some are ours to build.

**Status values:** `open` · `worked-around` (we ship a local fix; upstream is still open) · `not kama's` ·
`wontfix`. There is no `fixed`: a fixed entry is deleted from this file, and the commit that deletes it says
which kama version closed it.

**Verify by running a repro, never by reading a version string.** Each entry names the kama version it was
reproduced on.

Built against kama **0.9.803** (seeded 2026-11-01; KY-1 re-checked on 0.9.803; KY-2 and KY-3 found on 0.9.803).

Ids are `KY-<n>` and are permanent. **Next id: KY-4**

| Id | Kind | Status | Summary |
|---|---|---|---|
| KY-1 | BUG | open | **`kama run` on a library builds it and then tries to run the archive.** In this repo, `kama run engine/kama.json` (the `kyoten` library) builds `libkyoten.a` under a temporary `.exe` name, executes it, and on Windows the OS answers *"This version of C:\msys64\tmp\kama-run-4784.exe is not compatible with the version of Windows you're running"* (exit 1). `kama build engine/kama.json` is correct: it builds `engine/out/x86_64-windows-gnu/debug/libkyoten.a`. kama's docs say `run` "compiles a native executable … runs it" and that a workspace "errors and names its members"; a library has no executable to run, so it should be refused the same way, by name. Reproduced on 0.9.793 and 0.9.803, Windows 11, msys2 UCRT64. Not tried on Linux or macOS. |
| KY-2 | GAP | open | **No Android target.** `kama transpile hello.kama --target ANDROID` answers *"unknown target 'ANDROID' (expected EMBEDDED\|HOST\|LINUX\|MACOS\|WASM\|WINDOWS, or an <arch>-<os>-<abi> triple)"*. The bare triple `aarch64-linux-android` transpiles and derives `OS_LINUX`, `ABI_ANDROID` and `HOSTED`, so std treats bionic as Linux, which nothing has exercised. A shippable build needs more than the triple: the NDK's clang and sysroot as a target entry, a shared library entered through `android_main` (a native activity) rather than `main`, the activity lifecycle (pause, resume, a lost surface), and APK/AAB packaging and signing. **Meta Quest's native route (OpenXR) runs on Android**, so kyoten's VR needs this ([design/xr.md](design/xr.md) question 4). Repro: a `println` hello, transpiled for each spelling, with a `@compileFor` probe per flag. Reproduced on 0.9.803, Windows 11; no NDK on this machine, so no link was tried. |
| KY-3 | GAP | open | **No iOS target.** `--target IOS` is refused as `ANDROID` is. `aarch64-ios-none` transpiles and derives `OS_IOS`, so std's `OS_MACOS` declarations (`std::net`'s `ListenOptions`, for one) fall to their generic branch, and since a triple's components are the only flags, nothing names what macOS and iOS share. **Apple's own spelling, `arm64-apple-ios`, derives `ARCH_ARM64` and `OS_APPLE`**: neither `ARCH_AARCH64` nor `OS_IOS` holds, a trap for a triple copied from Xcode. A shippable build also needs Apple's clang and the iOS SDK (so a Mac), an app entered through `UIApplicationMain` with frames from `CADisplayLink` (the OS owns the loop, as the browser does on wasm), and a signed `.app` with a provisioning profile. `dlopen` is barred there, so kama's planned hot reload is desktop-only (kama `docs/ROADMAP_DETAIL.md` § the hot-reload library). Reproduced on 0.9.803, Windows 11, by transpiling only; a build needs a Mac. |
