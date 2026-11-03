# cosmic-forge: research for kyoten

Read-only survey of `C:\Users\Matt\Documents\cosmic-forge` at `1d0abca` (2026-10-31), 310 commits since `6364d1f`
(2026-10-13, "forge moves here"). Pointers are `cosmic-forge/<path>:<line>` or `§ heading`. *(inferred)* marks a
conclusion drawn from absence or from reading across files, not a statement the repo makes.

> **The owner, 2026-11-03:** "The tools are good to reference but the UX of cosmic forge is NOT great for humans yet.
> Perhaps the LLM CLI stuff... but not the UX so much yet." Read § 1's page, and anything below about the page, as
> what exists, not as a pattern for kyoten's `editor/`.
>
> **forge has moved since this survey.** It was pulled to `ff695ae` on 2026-11-03, 32 commits past `1d0abca`. It now
> has 76 tool manifests, a mesh in parts (GeoSAM2 labels, HoloPart, border clean-up), skeleton and camera thumbnails
> and, on the page, an asset browser and Duplicate. Audio R&D started 2026-11-03, with every route local. None of it is
> re-surveyed here.

## Summary

- forge is a **local, single-user asset pipeline**. It reads tool manifests and per-subject flow files as data, expands
  them into content-keyed steps, and runs external scripts (Python driving ComfyUI, Blender, AI-Toolkit). Its outputs
  are standard files: PNG, GLB, MP4, LoRA checkpoints and JSON reports.
- **Built today:** the engine, a CLI of about 45 commands, a localhost JSON API with SSE, and a WebAssembly page on
  `@kama/ui` with a WebGPU glTF viewer. There are 69 tool manifests and 6 kinds, nearly all for one job: a character
  goes from concept art to a game mesh, plus LoRA training, for the-mallow-man.
- **Not built:** publishing, provenance sidecars, adapters (kyoten's included), native viewers, any audio tool, the
  Postgres catalogue and store, remote runners, and the native page.
- **The "database" is files.** A forge project directory lives in the game's repo. Each subject's `flow.json` is the
  only source of truth, and the CLI and the page edit it through one code path (dotted-key writes). Ids are UUIDv7 and
  names are kept apart from ids.
- **No agent coordination, wiki, or record of who changed what exists in the product.** Coordination between AI
  sessions happens in repo docs: `docs/NEXT.md` is a 4,577-line session-handoff journal, alongside ROADMAP and
  KAMA_GAPS.
- **forge's docs already name kyoten:** a future adapter and native viewer; the `render` package, "shaped as kyoten's
  render package would be"; and the aim "forge as its asset pipeline", with a live preview.
- **Package status:** forge's kama packages are unpublished 0.1.0 path deps; `http` and `webnet` are slated for
  replacement by `@kama/http` (KR-173); `jsonvalue` overlaps std's `JsonValue` (kama 0.9.662); `jobs` is POSIX-only.

## 1. What forge is and does; built vs planned

forge's README describes it as "a composable asset tool for games, meant to become a content creation studio for any
game" (`cosmic-forge/README.md:3-6`). It is written in kama, and the tools it runs are scripts in any language. It
"knows no game engine": whatever one engine wants is an **adapter**, and outputs are published to destinations by URI
(`README.md:8-10`). It began inside the-mallow-man to replace that game's character tool (`README.md:22-24`;
`docs/ROADMAP.md:11`).

The current priority is the-mallow-man's launch: four campers, carried through stage 5 (colour bake, LODs, rig, clips,
the game's adapter) (`docs/ROADMAP.md:16-26`). The stated long-term goal is "every kind of asset (2D, 3D…, textures,
skies, audio)… handed to any engine through its adapter" (`docs/ROADMAP.md:3-9`).

| Area | Status | Pointer |
|---|---|---|
| Engine: manifests and flows as data, keys, state, early cutoff, seeds, gates | built | `docs/CONTRACT.md` § Steps, keys and state; `flows/README.md` |
| CLI and localhost server (JSON API, SSE, files) | built | `forge/src/main.kama:1-75`; `forge/src/serve.kama:24-161` |
| Page (WASM, `@kama/ui`), libraries, subject editor, A/B lanes, Clean, Undo | built | `forgeui/README.md:1-16` |
| 3D view: `render` web leg (glTF, PBR, orbit) | built (4f slice 1) | `render/README.md:1-9`; `docs/ROADMAP.md:516-521` |
| Native legs: `render` native, headless renders, native window and page | planned | `docs/ROADMAP.md:720-736`; `forgeui/README.md:225-227` |
| Character route: design → skeleton/cameras → views → Pixal3D/TRELLIS → clean → game mesh, LODs | built, iterating | `kinds/*.json`; `docs/NEXT.md` § The colour mended… |
| Worn parts (hair first), parts joined onto characters | slice 1 built | commit `ccb6d3e`; `docs/CONTRACT.md:1470-1495` |
| LoRA flow: dataset, AI-Toolkit trainer, screen, battery, Try | built | `docs/GUIDE_LORA.md` |
| Rig, weights, clips | planned (stage 5) | `docs/ROADMAP.md:19-26` |
| Publish step, destinations, provenance sidecar, adapters | planned; `destinations` is read only by Clean | `docs/CONTRACT.md:1697-1714`; `flows/src/clean.kama:955-962` |
| Audio tools (`audio` type declared; no manifest emits it) | planned | `docs/CONTRACT.md:186`; `docs/ROADMAP.md:744-746` |
| Postgres catalogue, store by UUIDv7, primitives registry, anchors, bundles | planned ("Nothing here is built yet") | `docs/CONTRACT.md:1716-1741` |
| Remote runners, `s3://`, versioned tools, graph view | planned | `docs/CONTRACT.md:1743-1747`; `docs/ROADMAP.md:752-775` |

## 2. Architecture

**Workspace** (`kama_workspace.json`, 8 projects; `README.md:26-42`). Line counts are each project's `src/`.

| Project | Kind | Lines | Depends on | Role |
|---|---|---|---|---|
| `jsonvalue` | lib | 999 | none | untyped JSON tree with dotted paths; writes byte-identical to Python's `json.dump(indent=2)` |
| `http` | lib | 1,729 | none | HTTP/1.1 server on one poll loop (ranges, SSE, keep-alive) and a blocking client |
| `jobs` | lib | 421 | none | one child process tree in its own session; line streaming; group cancel |
| `flows` | lib | 18,501 | jsonvalue, jobs, http | the engine (`flows/README.md:1-7`) |
| `webnet` | lib | 263 | none (wasm only) | browser `fetch` and `EventSource` for kama (CF-4) |
| `render` | lib | 6,072 | none | WebGPU glTF viewer; modules `gpu gltf camera pass view` (`render/kama.json`) |
| `forge` | exe | 3,983 | jsonvalue, http, jobs, flows | CLI and server (`forge/kama.json`) |
| `forgeui` | exe (WASM) | 22,504 | `@kama/ui ^0.6.0` (registry), webnet, jsonvalue, render | the page (`forgeui/kama.json`) |

Alongside them: about 17k lines of Python under `tools/`, plus the `vision`, `aitk` and `blender` runtime setups and
forge's own ComfyUI nodes (`docs/CONTRACT.md:161-168`).

**Server.** `forge serve [--port 8191] [--project P]` runs one single-threaded poll loop
(`forge/src/serve.kama:24-27`). It:

- serves the page, the JSON API over the project, the project's files and an SSE stream;
- reloads the project on every request, "so what the CLI or a hand edit changed is always what the page sees";
- runs **one job at a time**, as a `forge run` child process (`forge/src/runner.kama` header).
- applies a guard (`serve.kama:157-161`):
  - the Host header must be `127.0.0.1:<port>` or `localhost:<port>`;
  - every non-GET request needs `X-Forge: 1`;
  - a write to the subject being run is refused with 409.

**Page.** A kama program built to WASM on `@kama/ui`: the DOM on the web, RmlUi natively later
(`forgeui/README.md:1-5`). It talks to forge only through the JSON API and the event stream.

- It reaches the browser through four seams (`net_*`, `files_*`, `media_*`, `host_*`), each a web/native pair gated by
  `@compileFor(ARCH_WASM32)`. The native halves compile and say "not yet" (`forgeui/README.md:225-227`).
- It is HTML/CSS with no framework and no build step. The rule is browser technology first: Web Audio and WebGPU
  before any library (`CLAUDE.md:11-12`).

**Job runner.**

- `jobs::Job` starts argv under `setsid`, with stdout and stderr merged into one pipe drained without blocking. Cancel
  sends SIGTERM to the process group, then SIGKILL after a grace period (`jobs/README.md:13-36`).
- Every `forge run` (from the CLI or the page) writes `out/.runs/<uuidv7>.json` while it runs and `out/.runs/last.json`
  when it ends (`docs/CONTRACT.md:1317-1330`). `serve` polls these every second and pushes SSE `runs` events
  (`docs/CONTRACT.md:1332-1338`).
- One GPU lock per machine (`~/.cache/forge/gpu.json`) lets only one GPU step run at a time (`docs/CONTRACT.md:124-133`).
- **Services** (ComfyUI) are data in `forge.json`: url, ready path, start command, plus `free`, `interrupt` and
  `stats`. forge starts a service when a step needs it and never stops one (`docs/CONTRACT.md:134-160`).

**Tool manifests** (`tools/<id>.json`; `docs/CONTRACT.md` § Tool manifests, `:311-420`) declare `id`, `label`,
`phases`; `models` (each with licence and `commercial` level); typed `inputs`/`outputs`; typed `fields` (text, number
with min/max/step, select, seed, size, prompt, tags, frames, upload, lora, item, checkpoint); `rows` (a table, steps run
per row); and `steps` (`run` argv with placeholders `{out}` `{emit}` `{with.x}` `{row.x}` `{in.port}`, `runtime`,
`needs` such as services or `{"gpu":{"vram":N}}`, `outputs`, `emits`, `explicit`, `uses`). Rules: the engine never special-cases a tool by name (`docs/CONTRACT.md:14-15`). A project's tools with the same id
win over forge's built-in ones (`flows/README.md:22`).

**Flows** (`subjects/<id>/flow.json`; `docs/CONTRACT.md` § Flow files, `:1076-1100`).

- A flow is `{name, kind, words, seed, entries, out, tags, tried}`. Each entry is `{tool, phase, slot?, in, with,
  name?}`.
- Wires are `<entry>.<port>`. A `file:<path>` wire reads a file directly. A cross-subject wire
  `@<subject>.<entry>.<port>` reads what that subject last made (`docs/ROADMAP.md:43-45`; `flows/src/published.kama`).
- **Kinds** (`kinds/<kind>.json`) declare phases, then slots, then the tools that may fill each slot and the gates on
  it. Two entries in one slot form an A/B; `use` decides it, removing the losers in one undoable write
  (`docs/CONTRACT.md:1456-1500`; example `kinds/worn.json`).

**Data model.**

- Every choice is written to the flow file, and the page and the CLI are one code path (`docs/CONTRACT.md:16-17`).
- Writes are **dotted-key** sets and unsets (`forge set … entries.clips.with.seed 4`), through jsonvalue's `setPath`.
  Writes to `kind`, `next` and `tried`, and writes under a missing entry, are refused (`flows/README.md:179-186`).
- Subject ids are UUIDv7, claimed by one `mkdir` so two writers never share an id. Names are display-only, never in a
  key or a path (`docs/CONTRACT.md:66-73`; `flows/README.md:188-196`).
- Row ids are UUIDv7. Entry ids are counter ids scoped to the flow (`docs/ROADMAP.md:777-782`).

**Storage layout** (`docs/CONTRACT.md:47-64`):

```
forge.json, tools/, kinds/, prompts/, presets/      project config and overrides of forge's built-ins
subjects/<id>/flow.json, subjects/<id>/inputs/      the data; uploads
out/<id>/<entry>/…, out/<id>/logs/<entry>/<step>.log
out/<id>/{build,files,same,sums,inputs,times,failed}.json   per-subject state (§ Steps, keys and state)
out/<id>/<entry>.removed.json, out/.removed/<id>/    removal records (Undo)
out/.runs/, out/.services/<name>.log, out/.digests.json
```

## 3. Interfaces another program could use

**CLI** (`forge/src/main.kama:7-75`, also printed by `usage()` at `:567`). Every command takes `--project P`, and most
take `--json`. Commands by group:

- **Discovery:** `tools`, `kinds`, `library <name>`, `subjects`, `loras`, `presets`
- **Subjects:** `new <kind> [--name]`, `rm-subject`
- **Making:** `status <subject>`, `run <subject> [--step|--entry|--phase]`, `runs`, `cancel`, `services`,
  `start-service`, `log <subject> <step>`
- **Editing the flow:** `set`/`unset <path> <json>`, `add`, `fill <slot> <tool> [--preset]`, `rows-from`, `move`, `rm`,
  `add-row`/`move-row`/`rm-row`, `use`, `like`, `preset`, `rm-preset`, `regen`, `pick`
- **Items:** `keep`, `drop`, `tag`
- **Inputs:** `upload`, `inputs`, `remove-input`, `words`, `slots`
- **Housekeeping:** `clean [--yes [--earlier]]`, `removals`, `undo`

`status` exits 2 when the flow cannot be planned (`flows/README.md:50`).

**HTTP** (`forge/src/serve.kama:26-155`, the authoritative list; `docs/NEXT.md:3065`):

- Reads: `GET /api/project`, `/api/prompts`, `/api/presets`, `/api/loras`, `/api/library/<name>`,
  `/api/subject/<id>` (returns `{flow, status, wiring, inputs, words, slots, removals, items, stamps}`),
  `/api/clean`, `/api/removals`, `/api/runs`, `/api/services`, `/api/log/<id>/<step>`, `/files/<path>` (with ranges).
- Writes: `POST /api/subjects`; `POST /api/subject/<id>/{set, regen, pick, add, fill, rows-from, use, like, preset,
  move, rm, add-row, move-row, rm-row, item, upload, remove-input}`; `POST /api/run`, `/api/cancel`, `/api/undo`,
  `/api/clean`, `/api/services/<name>/start`; CRUD on prompts and presets.
- Uploads are chunked (4 MiB) with offset and token (`flows/README.md:238`; KAMA_GAPS CF-13).
- `GET /api/events` is SSE with events `hello`, `job`, `run`, `step`, `progress` `{name, done, of, unit, secs, left}`,
  `line` `{step, text}`, `runs` and `services` (`serve.kama:145-150`).

**File formats and schemas** (all JSON, documented only in prose in `docs/CONTRACT.md`): `forge.json` with runtimes,
gpu, services, destinations, viewers (`:84-104`); tool manifest (`:311-420`); flow (`:1076-1100`); prompt asset
`{name, text, note}` (`:1220-1224`); preset (`:1254`); kind (`:1456-1468`); run record (`:1320-1326`); removal
records (§ Undo); gate `report` `{pass, bars, items?, sheet?}` (`:205-218`).

**Port types** (`docs/CONTRACT.md:170-188`): `image`, `images`, `clip`, `views`, `skeleton` (OpenPose 18 + hands 21 +
face 70, in forge's own convention), `rig` (camera set, Pixal3D convention), `mesh`, `dataset`, `lora`, `prompt`,
`audio`, `likeness`, `report`.

**Output formats:** PNG; MP4 plus frames (`clip`); **GLB**, checked strictly (binary glTF 2.0, one embedded buffer,
triangles, embedded PNG textures, no required extensions; frame `rig` normalised or `metres` "for an engine";
`docs/CONTRACT.md:232-262`; `tools/forge_glb.py` is the one GLB reader/writer); LoRA `.safetensors` with sha256;
WAV/OGG audio (declared only). KTX2 is named for the-mallow-man's unbuilt adapter (`docs/CONTRACT.md:23-24,1704-1708`).

**Ids and naming:** subjects and rows UUIDv7; entries readable counter ids; items `[entry, row?, item]` joined with
`/`; step ids `<entry>/<step name>`; cross-subject `@<id>.<entry>.<port>`; prompt and preset ids are name slugs
(`docs/CONTRACT.md:296-305,1357`; `flows/README.md:250`).

**Stability:** nothing is versioned (every package `0.1.0`); no JSON output carries a schema or version field
*(inferred: none found in `flows/src`, `forge/src`)*; "versioned tools" is under § Not yet (`docs/CONTRACT.md:1746`).
`docs/CONTRACT.md` calls itself "the contract between the engine, the page and the tools" (`:8-10`) and is the one
maintained interface document; the HTTP reference is a source comment.

## 4. Project database, wiki and AI coordination

**What exists, all file-based:**

- **Source of truth.** One `flow.json` per subject. Every edit is a dotted-key write, so the page, the CLI and any
  other client share one write path (`docs/CONTRACT.md:16-17`; `flows/README.md:179`).
- **Content-addressed build state.** A step key is the sha256 of the tool id, the step name, the resolved command line
  (with each input's producing key), the script's bytes, the runtime, and the modules it uses. `inputs.json` records
  what each key was hashed from, so a stale step can say *why* ("`{with.count}` changed (was "3")")
  (`docs/CONTRACT.md:1342-1367`).
- **Undoable removals.** Every removal leaves a record holding everything needed to restore it. Nothing is deleted
  except by Clean (`docs/CONTRACT.md:1379-1420,1422`).
- **Runs** are recorded while they run, and the last run to end is kept (`out/.runs/`).
- **Seed history** is kept in `tried` (`docs/CONTRACT.md:1376`).
- **Licence gating.** Each manifest lists every model with its licence and a `commercial` level. Anything below
  `permissive` is refused (`docs/CONTRACT.md:27-31`; `docs/MODELS.md:8-12`).

**What does not exist:**

- No edit history or log of who changed what, and no actor or owner field in flows *(inferred: none found)*.
- No locking between concurrent editors beyond the "being run" 409 and `mkdir` claims.
- No wiki or notes per subject; a kind's and a slot's `description` are the only prose in the data.
- No agent API.
- History today is the game repo's git, since the forge project lives there (`docs/CONTRACT.md:43-46`)
  *(inferred)*.

**Planned** (`docs/CONTRACT.md:1716-1741`; design session `docs/NEXT.md:2271-2290`): a Postgres catalogue
(`@kama/postgres`) of assets, types, composition, **owners**, sha256 and URIs; a store at
`<store>/<uuidv7 date>/<uuidv7>.<ext>` outside the game repo; kinds declaring composition, with primitives as a
registry of kama types (text, image, svg, audio, video, data with a kama schema, mesh…); anchors `{id, name, on,
offset}` and "mappings" (a footstep to a material's sounds) as "data the adapter and the engine interpret"; hosted mode
with sessions in Valkey; bundles keyed to a range of game commits; and a provenance sidecar `<file>.json` (tool, step
key, model files with sha256, licence, seed, filled prompts) written at publish (`:1699-1700`).

**How AI sessions coordinate on forge** (process, not product):

- `CLAUDE.md` sets the rules: read CONTRACT and ROADMAP first; "Ask before" GPU-hours, game windows, commits and pushes
  (`:20`); narrow subagent briefs (`:34`).
- `docs/NEXT.md` is a dated handoff journal. It has "Start here" sections, the owner's verbatim reactions ("His look"),
  a "Waiting on Matt" list (`:2937`), "Where things are" (`:3053`) and "Rules that bite" (`:4357`).
- `docs/KAMA_GAPS.md` holds upstream gaps under permanent `CF-<n>` ids.
- `docs/ROADMAP.md` carries the cross-project order "for whoever triages them (kyoten's sessions too)" (`:16`).

**Candidate uses for kyoten** (options, not recommendations):

- (a) Adopt forge's patterns for kyoten's game-project database: data as JSON files keyed by UUIDv7 with display names
  apart, one write path shared by UI, CLI and agents, content keys with recorded causes, and removal records instead of
  deletes.
- (b) Treat each forge project as one *asset* subsystem inside a kyoten project. kyoten's database would hold
  references (`@<subject>.<entry>.<port>`, or published files plus their sidecars) and would not mirror forge's state.
- (c) Wait for forge's catalogue and point kyoten at the same Postgres. It is unbuilt; its schema and ownership model
  are open.

**What kyoten would have to add either way** *(inferred)*: actor attribution, an edit history, a cross-system wiki,
and coordination between agents.

## 5. Human-visibility patterns

These are the patterns kyoten could reuse or mirror:

- **Live jobs.** Every run is visible whichever client started it (SSE `runs`; a job bar and a runner pill with
  service state and VRAM: `docs/CONTRACT.md:1332-1338`; `docs/ROADMAP.md:536`). The log streams line by line, folded to
  its newest line until opened, a `\r` progress bar kept as one line; `progress` carries done/of/unit/left
  (`forgeui/README.md:7`; `serve.kama:145-150`).
- **State on every step:** ok, ready, stale (with the cause), missing, blocked (which input), failed (why) and explicit
  (with its last duration) (`docs/CONTRACT.md:1368-1373`). Long steps ask before they start, giving the last run's time
  (`:32-35`).
- **Measured gates.** A gate's report fails its step. The page draws the bars missed, worst first, a per-item mark on
  tiles, and a `sheet` grid (for example checkpoints × prompts) (`docs/CONTRACT.md:205-218`).
- **A/B lanes.** Candidates in one slot are shown side by side, and "Use this" is one undoable decision
  (`docs/CONTRACT.md:35-40`; `forgeui/README.md:8-11`).
- **Undo everywhere.** A notice after each removal, Ctrl+Z, Removed lists, and Restore in Clean
  (`forgeui/README.md:7`).
- **Addressable UI.** Hash routes such as `#/subject/<id>/<phase>/<entry>`, and every reference is a link
  (`forgeui/README.md:229-245`).
- **Previews.** Images at full size; a `clip` with a frame picker; a GLB in the `render` overlay (Lit, Clay,
  BaseColour, Normals; over 32 MiB waits for "Open"; `docs/CONTRACT.md:1709-1712`). `render`'s `measure()` reads back
  coverage and mean colour so a headless check proves what was drawn (`render/README.md:32-34`).
- **Human guides** written against the page: `docs/GUIDE_LORA.md`, `docs/GUIDE_DESIGN.md`.
- **For a DAW-like audio tool**, `docs/MODELS.md:177-206` already surveys "Music by Claude (an LLM with a DAW)": Claude
  writes a score (MIDI-like JSON, Csound or SuperCollider) rendered headlessly by FluidSynth or Csound; Ardour 9.5's MCP
  surface is an *optional live view*, "never the render path"; licence verdicts per synth and soundbank.

## 6. Reusable kama packages and patterns

| Package | Maturity (evidence) | Fit for kyoten | Fate per forge's docs |
|---|---|---|---|
| `jsonvalue` | 0.1.0; round-trips 45/48 real files byte-identically; linear key lookup; depth ≤1000 (`jsonvalue/README.md:72-87`) | dotted paths and a Python-identical writer are its distinct features | overlaps std `JsonValue`, landed in kama 0.9.662 as KR-110 (`kama/lib/std/serialization/text/json/json.kama:717`); forge still lists KM-40 as worked-around (`docs/KAMA_GAPS.md:29`) |
| `http` | 0.1.0; one poll loop, SSE, ranges, a 64 MiB body cap, no streamed body (CF-13); blocking client (`http/README.md:3-11,149`) | localhost tools servers | to be replaced by `@kama/http` (KR-173), "seeded" in `../kama-http` (`docs/KAMA_GAPS.md:42`); that checkout is absent from this machine |
| `webnet` | 0.1.0; wasm-only `fetch` and `EventSource` in a polling model (`webnet/README.md:1-20`) | any kama web UI talking to a server | to be replaced by `@kama/http` (CF-4) |
| `jobs` | 0.1.0; **POSIX only, tested on Linux; needs util-linux `setsid`; "Windows is not supported"** (`jobs/README.md:5,112`) | an external-tool runner, but not on Windows or macOS | KM-42 still open upstream |
| `flows` | 18.5k lines; `flowscheck` covers 110 cases (`flows/README.md:260-283`) | forge's engine; not designed as a general library *(inferred)* | n/a |
| `render` | web leg built; native leg, headless renders, a window, skinned meshes and splats planned; checks prove pixels in headless Firefox (`render/README.md:110-126`) | explicitly "shaped as a game engine's render package would be", "another reference point for kyoten" | its `wgpugen` reads both wgpu-native's and Dawn's `webgpu.h` (CF-21) |
| `@kama/ui` | registry package 0.6.0 (`forgeui/kama.lock`) | kyoten's UI per forge's note (`docs/ROADMAP.md:729-730`) | no native GPU canvas (CF-22), no `getAttribute` (CF-23) |

**Versioning and publishing.** forge's own packages are **path dependencies only** (`"path": "../jsonvalue"`) and are
not published (`flows/kama.json`, `forge/kama.json`). The only registry dependency is `@kama/ui`, via
`registry.kama-lang.org` and pinned in `kama.lock`. The kama toolchain is pinned in `.kama-version:4` (`0.9.765`),
using a sibling `../kama` checkout (`README.md:48`).

**Patterns worth copying:** seams as `@compileFor` file pairs (`forgeui/README.md:225`); a check program per library
(`README.md:44`); a pinned runtime per external tool (Blender 5.2.2 on one thread, so a make repeats byte for byte) and
sha256-pinned model files (`README.md:82-106`).

## 7. KAMA_GAPS entries relevant to an engine

From `cosmic-forge/docs/KAMA_GAPS.md` (`:40-52`; next id CF-24):

- **CF-4** (worked-around): no browser `fetch`/`EventSource` in std. The answer is `@kama/http`.
- **CF-5** (open): no native WebSocket server or client. Needed for remote runners and any live editor link.
- **CF-6** (open): no native WebTransport (needs HTTP/3, QUIC, TLS 1.3).
- **CF-8** (open): no native file dialog. The web half is in `@kama/ui` 0.4.0.
- **CF-9** (open): no `<video>`/`<audio>` element natively in `@kama/ui` (RmlUi).
- **CF-13** (worked-around): no streamed request body on a kama HTTP server.
- **CF-19** (worked-around): no std reader of fixed-width little/big-endian integers from bytes. GLB headers need it.
- **CF-20** (worked-around): `"webgpu": true` does not link on the web without `emSettings.DEFAULT_TO_CXX`.
- **CF-21** (open): no WebGPU bindings in std (removed in 0.9.652). Each project generates its own; `@kama/gpu` is
  planned.
- **CF-22** (open): `@kama/ui` has no GPU canvas element natively. "Open: package (@kama/ui, or kyoten's window)".
- **CF-23** (worked-around): `@kama/ui` cannot read an element's attribute.
- Inherited, still listed: KM-42 (no child in its own session or group: why `jobs` is POSIX-only), KM-49 to KM-56
  (language bugs and gaps) (`:27-36`).

## 8. Integration options for kyoten

**Observed facts:**

- **forge is engine-neutral by rule.** Each engine gets an **adapter, which is a set of forge tools and only that**:
  axes and scale, skeleton naming and the rig contract, texture formats, LODs, collision, names and folders. Godot,
  Unity, Unreal and **kyoten (Matt's engine in kama) come later** (`docs/CONTRACT.md:23-24,1704-1708`;
  `docs/ROADMAP.md:776`).
- **A game owns its forge project.** forge.json, subjects, prompts, its own tools and its adapter live "in that game's
  repo", passed with `--project` (`docs/CONTRACT.md:43-46`). Project tools and kinds override forge's built-in ones by
  id (`docs/CONTRACT.md:1458-1460`). In practice the measured projects live in `the-mallow-man/out/forge-*/project`
  (`docs/NEXT.md:195,3082`).
- **Destinations** (`file://` now, `s3://` later) receive a `publish` step's copies. That step is explicit, and
  anything leaving the machine is confirmed every time (`docs/CONTRACT.md:1701-1703`). None of this is built.
- **Viewers.** A native viewer is "an external program declared in forge.json with the types it shows (this game's
  look-dev first, kyoten's later)". "Preview in game" is an adapter's publish to a scratch destination plus its viewer
  (`docs/CONTRACT.md:1709-1714`). Not built.
- **kyoten is named as the best integration once it exists.** "forge stays general (any engine, through adapters) and
  integrates with kyoten best once it exists (a live preview; forge as its asset pipeline)" (`docs/ROADMAP.md:722-724`).
  Its model gate and mesh-guided controls are to "render through kyoten instead of ComfyUI's ray caster: one renderer
  previewing and measuring" (`:731-733`).
- **The `render` package is a hand-off point.** "the-mallow-man's renderer ported and shaped as kyoten's render package
  would be, which kyoten may take or learn from" (`docs/ROADMAP.md:27-31`; `docs/NEXT.md:3876-3880`).
- **Native windows go through HTTP.** A native forge window talks to forge over HTTP and SSE via `@kama/http` 0.2
  (`docs/ROADMAP.md:736`).
- **Ordering constraint.** The-mallow-man's launch comes first across projects. kyoten "grows on its own track" and
  porting games to it is post-launch (`docs/ROADMAP.md:16-34`).
- **Platform constraint.** forge is built and run on Linux (`x86_64-linux-gnu` paths, systemd ComfyUI, `setsid`;
  `README.md:55`; `docs/NEXT.md:3070-3076`). `jobs`, and therefore `forge run`, does not support Windows
  (`jobs/README.md:112`).

**Candidate options** (labelled as options; each with what the evidence says about it):

| # | Option | Supported by | Costs and unknowns |
|---|---|---|---|
| A | **kyoten drives forge as an external process.** It calls the CLI (`--json`) or HTTP API and follows SSE for jobs, so its agents see the same state a human sees. | One write path (`CONTRACT.md:16-17`); a full API (`serve.kama:26-155`); runs visible from any client (`:1317-1338`) | No schema versioning; localhost-only guard plus `X-Forge`; one job at a time; no actor attribution |
| B | **The kyoten project contains a forge project** (`<game>/forge/`), with kyoten-specific kinds, tools and presets as project overrides. | `CONTRACT.md:43-46,1458-1460`; matches how the-mallow-man is set up | forge project ids (UUIDv7 subjects) must be referenced from kyoten's database; files in two formats in one repo |
| C | **A kyoten adapter as forge tools** writes engine-ready assets (and later provenance sidecars) into kyoten's asset folders through a `file://` destination. | `CONTRACT.md:1701-1708`; `ROADMAP.md:776` | Publish, provenance and adapters are all unbuilt. kyoten would define the target contract (axes, rig, texture formats, LODs, names) |
| D | **kyoten as forge's viewer and measurer.** kyoten's renderer (seeded from `render`) serves as forge's native viewer and headless gate renderer. | `ROADMAP.md:720-736`; `CONTRACT.md:1709-1714` | Needs `render`'s native leg (slice 3) and CF-21/CF-22 answers |
| E | **kyoten depends on forge's kama packages directly.** | `render` was designed for this; the others are 0.1.0 path dependencies | `http` and `webnet` are to be replaced by `@kama/http`; `jsonvalue` overlaps std `JsonValue`; `jobs` is not on Windows; nothing is published |
| F | **A shared catalogue.** kyoten's project database and forge's planned Postgres catalogue are one store. | `CONTRACT.md:1732-1741` (composition, anchors, mappings "the engine interprets", bundles per commit range) | Unbuilt; ownership of the schema is undecided between forge and kyoten |

**Questions the design session may need to settle** *(inferred from the gaps above)*:

- Who owns the asset composition, anchor and mapping schema: forge's catalogue or kyoten's database?
- Is kyoten's adapter target contract the first adapter forge builds, or second after the-mallow-man's?
- Does kyoten want forge's dotted-key, file-per-entity model for its own database?
- Will forge's `jobs` gain Windows support, or does kyoten run forge only on the Linux box?
