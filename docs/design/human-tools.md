# Human visibility and tuning tools

**Status:** draft, deferred past the first slice to KYR-26 and KYR-27. These are questions, not decisions.

## What the vision asks

- **Humans have visibility into the full process**, and **human tuning tools along the way.**
- Named so far: **audio tools like a DAW** ([audio.md](audio.md)) and **timeline and cinematic tools**
  ([timeline.md](timeline.md)).
- Web first: **HTML/CSS** is the UI technology the browser already does best.
- **AI first, then humans who edit too** (the owner, 2026-11-02): "We will develop AI first and human tools start as
  visibility into the process… but obviously it will be most powerful to allow humans to edit as well as AI so humans
  can tweak." The tool surface lives in `editor/` ([architecture.md](architecture.md) question 7).
- **Tooling works for AI up front and is visible to humans** (the owner, 2026-11-03): "The first consumers of kyoten
  are AI. So the tooling needs to work well for AI up front and be visible to humans and UX will need to be something
  we do our best with as we build out any sort of tools." See [ai-first-api.md](ai-first-api.md) § Decided
  (2026-11-01).
- **cosmic-forge is a reference for tools, not for UX** (the owner, 2026-11-03): "The tools are good to reference but
  the UX of cosmic forge is NOT great for humans yet. Perhaps the LLM CLI stuff... but not the UX so much yet."
- **Web-first tools in kama, the window onto the workflow** (the owner, 2026-11-04): the tools "are a little less
  important up front but will become the window into the workflow and eventually more human intervention can be added
  as well. We will do web first tools with kama much like I'm doing with cosmic-forge" ([../VISION.md](../VISION.md)).

## What already exists

- Tuning files with live reload, debug overlays, record/replay viewers and test harnesses in the peers: see
  [../research/peer-games.md](../research/peer-games.md) § human tools.
- cosmic-forge's page: a web UI over a local HTTP server, with job logs streamed live (server-sent events). See
  [../research/cosmic-forge.md](../research/cosmic-forge.md) § human visibility. Its tools and its CLI are the
  references, not its UX (the owner, above).

## The questions

1. **One tool surface or many?** A single editor (a web app the engine serves) with panels for each system, or
   separate tools that share a protocol. Which comes first?
2. **How does it run on native?** The same HTML/CSS UI in a browser pointed at a local server the native game
   runs, an embedded webview, or a native UI. Web first suggests the first. What does that cost on native?
3. **What can a human see live?** Candidates: the project database's change feed (agents' work as it happens),
   entities and their components, per-phase and per-component timings at each update rate, the input recording,
   network traffic.
4. **What can a human change, and where does it go?** A tuning change writes a project-database record, exactly
   as an agent's would ([project-database.md](project-database.md)), so the human and the AI share one history.
   Is that the rule?
   - *Noted 2026-11-06, the owner:* "The same sort of 'adapter' abstraction will be used for specifying editor gui
     control types and such as well so a float value can be decorated as a knob, slider, etc." Input's adapters map a
     device's control to an action (KYR-54), and an editor control maps a field to a widget the same way.
     - **Prior art:** Godot 4.7's `@export_range` shows a float as a slider, with `exp`, a unit `suffix:m`, and
       `radians_as_degrees`, which "stores radians but displays and edits degrees"
       ([exports](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html)).
     - **One difference:** an editor control works both ways, showing the value and editing it, so its adapter
       converts back as well.
     - **Where the hint lives:** in the component's record, as a requirement does (components question 8), because
       kama refuses an attribute it does not know.
     - **A game's own UI** binds a settings slider to a value by the same means.
5. **Record and replay as a tool:** scrub a recorded session, step frame by frame, and compare two runs. How much
   of that comes for free from the Input phase's recording ([replay-and-determinism.md](replay-and-determinism.md))?
6. **Profiling:** what is measured per phase, per component, per rate, and how is it shown?
7. **In-game versus out-of-game:** which tools overlay the running game, and which run beside it?
8. **Access and safety:** a dev server that can edit the project must not ship in a release build. How is that
   enforced?

## Decided

- **2026-11-01, the owner: deferred past the first slice** when the spike was narrowed
  ([../SPIKE.md](../SPIKE.md#narrowed-2026-11-01)). It is taken up with KYR-26 (the tool surface) and KYR-27 (replay as
  a tool). The DAW and the timeline tools are KYR-35 and KYR-36.
