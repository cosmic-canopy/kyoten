# kama gaps and bugs

The running list of what kyoten hits in [kama](../../kama). Two kinds of entry:

- **BUG**: kama does something wrong. Each entry carries a repro, and these should be fixed upstream.
- **GAP**: kama does not do something yet. Some gaps belong upstream; some are ours to build.

**Status values:** `open` · `worked-around` (we ship a local fix; upstream is still open) · `not kama's` ·
`wontfix`. There is no `fixed`: a fixed entry is deleted from this file, and the commit that deletes it says
which kama version closed it.

**Verify by running a repro, never by reading a version string.** Each entry names the kama version it was
reproduced on.

Built against kama **0.9.803** (seeded 2026-11-01; KY-1 re-checked on 0.9.803).

Ids are `KY-<n>` and are permanent. **Next id: KY-2**

| Id | Kind | Status | Summary |
|---|---|---|---|
| KY-1 | BUG | open | **`kama run` on a library builds it and then tries to run the archive.** In this repo, `kama run engine/kama.json` (the `kyoten` library) builds `libkyoten.a` under a temporary `.exe` name, executes it, and on Windows the OS answers *"This version of C:\msys64\tmp\kama-run-4784.exe is not compatible with the version of Windows you're running"* (exit 1). `kama build engine/kama.json` is correct: it builds `engine/out/x86_64-windows-gnu/debug/libkyoten.a`. kama's docs say `run` "compiles a native executable … runs it" and that a workspace "errors and names its members"; a library has no executable to run, so it should be refused the same way, by name. Reproduced on 0.9.793 and 0.9.803, Windows 11, msys2 UCRT64. Not tried on Linux or macOS. |
