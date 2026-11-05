# The project database and wiki

**Status:** draft for the design spike; its build is KYR-24. Five decisions are recorded, the latest closing question
11 (layers) on 2026-11-05; the rest are questions.

## What the vision asks

- kyoten **generates games by maintaining an AI-coordinated database and wiki of the game project.**
- **Several agents** design and coordinate across systems through it, and **the game project stays consistent.**
- **Humans see the full process** and can tune along the way.
- **Several agents, developing concurrently on separate machines, with one consistent game direction** (the owner,
  2026-11-01). **The game wiki, one per project, is what coordinates them**, and the owner sees it as unique and
  important to kyoten's success. Separate machines bear on where it lives (question 2: a repository every machine
  clones, or a service every machine reaches) and on how agents coordinate (question 6).

This is what makes kyoten AI-driven rather than an engine with an assistant attached. It is the design with the
least prior art in the peers, and the one most worth getting right before code.

## What already exists

- **cosmic-forge** keeps its inputs as JSON keyed by id and edits them one dotted key at a time; it has jobs,
  provenance and a web page that shows them live. See [../research/cosmic-forge.md](../research/cosmic-forge.md)
  for what of that kyoten could share (id scheme, provenance, the page).
- **The peers coordinate agents through documents**: ROADMAP + DETAIL with permanent ids, `WORKING.md`, `NEXT.md`,
  `KAMA_GAPS.md`. See [../research/peer-games.md](../research/peer-games.md) § process. That is a wiki in all but
  name, written by hand.
- **kama gives typed data for free:** `@generate(Serializable/Deserializable)`, strict decoding, merge into a held
  value, and an untyped `JsonValue`. See [../research/kama-for-engines.md](../research/kama-for-engines.md).
- **Overrides layer the same way in most engines** ([../research/component-models.md](../research/component-models.md)
  § Summary): per property, the most specific layer wins, and a field a layer does not mention is inherited (Unity's
  prefab variants, Godot's instances, flecs's `IsA`, Bevy's BSN patches). That is kama serde's `mergeJsonBuffer` rule
  and the priority stacks in *Decided*. Unreal, which infers an override from a value that differs from the default,
  is the outlier, and UEFN overrides per component rather than per field.

## The questions

1. **What is a record?** Candidates: an entity or prefab definition, a component's tuning, an asset reference, a
   level, a timeline, a design note, a decision, a task. Is all of that one database, or several with shared ids?
2. **Where does it live?** Plain text in the game's repo (JSON or markdown, with git as history, diff and review),
   an embedded database (SQLite) exported to text for review, or a service. What does each mean for merging two
   agents' work, and for a human reading a diff?
3. **Database and wiki: one source or two?** Is the wiki generated from the records (one truth, always current),
   or written prose that links to records by id?
4. **Who defines the schema?** The engine ships the core schemas (transform, mesh, sound, timeline…) and a game
   extends them, presumably typed through kama serde so a record and the component that reads it cannot drift.
   How does a game add a record type?
5. **What does "consistent" guarantee?** Referential integrity (every id referenced exists), schema validity, and
   cross-system invariants (a level's spawn points are on navigable ground). Which are checked when, and who is
   told when one breaks?
6. **How do agents coordinate?** Concurrently, on separate machines (above). Roles (a design agent, an audio
   agent…), claims or locks on records, change proposals and review, conflict resolution, and an event log of who
   changed what and why (provenance).
7. **What do humans see and do?** A live feed of changes, approve or reject, the audit trail, and tuning edits
   that flow back into the records exactly as an agent's would.
8. **How does the running game read it?** Directly in development, with hot reload, and from a baked, packed form
   when it ships? Where is that boundary?
9. **What interface do agents use?** Files plus `kama query`, a `kyoten` CLI (`kyoten db get/set/query`), an MCP
   server, an HTTP API shared with the human tools, a JSON schema export for tool use. One of these, or a layered
   set?
10. **How does it relate to cosmic-forge?** Shared ids and provenance for assets, and forge writing into the
    project database or kyoten reading forge's outputs.
11. **Layers, in detail.** *(Decided 2026-11-05 with components question 5, below.)* What is the priority order (the base game, DLC, patches, mods, a
    developer's local overrides), and does a higher layer override a whole record or single fields? How do consistency
    checks (question 5) judge a stack rather than one source? A replay must know which layers were loaded, since one id
    can resolve differently under another stack ([replay-and-determinism.md](replay-and-determinism.md)). And which of
    the record kinds in question 1 can be layered at all: a level and a tuning value, surely, but a design decision?

## Options worth comparing

- **Files in git, typed by kama serde.** Diffable and reviewable, no server. Merges are text merges, and concurrent
  agents need a coordination layer on top.
- **An embedded database with a text export.** Queries and transactions; review happens on the export, so two
  representations must agree.
- **Event-sourced:** an append-only log of changes, with records as its projection. Provenance and replay come
  free, which matches the engine's own replay model, at the cost of more machinery.
- **One store interface with several backends** (the owner, 2026-11-01: the "database" could literally be kama
  postgres, or "a generic abstract interface of sorts that can be fulfilled by a database or flat files"). The engine,
  the tools and the agents use one contract. Flat files in git fulfil it, and so does a server such as
  `@kama/postgres` (0.4.0 on the registry, pure kama over PostgreSQL's wire protocol, no libpq). It matches the
  no-lock-in rule ([networking.md](networking.md) § Decided): a project picks its backend, the platform could offer a
  hosted one as its easy option, and none is required. Which backend is the reference, and whether a wiki's prose and
  a database's rows can share one truth, are questions 2 and 3. Layers by priority (*Decided*) are this interface
  composed: a stack of stores, each answering for what it holds.

## Decided

- **2026-11-01, the owner: deferred past the first slice** when the spike was narrowed
  ([../SPIKE.md](../SPIKE.md#narrowed-2026-11-01)). It is taken up with KYR-24 and KYR-25 and proved in slice C
  (KYR-28). Meanwhile the spike keeps the component model ready for records (components.md question 5), so this design
  is not boxed in before it starts. *Its design came back into the spike later the same day (next entry); only the
  build stays deferred.*
- **2026-11-01, the owner, later the same day: the wiki's design is decided in the spike; its build stays after the
  first slice** (KYR-24, proved in slice C, KYR-28). The reason: a game that starts after slice B would otherwise be
  built before its wiki exists, and the lookup abstraction (below) shapes how game code reads its data. Questions 1–6, 8
  and 11 join the spike. Question 7 waits for KYR-26, 9 for KYR-25 and 10 for KYR-29.
- **2026-11-01, the owner: query support and MCP are built into kyoten** ([ai-first-api.md](ai-first-api.md) §
  Decided). That answers question 9 in part: the project database is reached through them, and whether a CLI, an HTTP
  API or a schema export layers on top stays open.
- **2026-11-01, the owner: a game's lookups go through an abstraction, and sources stack by priority.** A higher layer
  overrides a lower one, which is what serves content on disk against DLC, and similar cases. Nothing reads a source
  directly. This bears on question 8 (the running game reads the stack, whatever backs each layer) and fits the store
  interface below, with a stack of them composed by priority. The details are question 11.
- **2026-11-05, the owner: question 11, decided with [components.md](components.md) question 5.** "Part B 4. Yes
  recommended... 5. It doesn't need to be hard coded... 6. sounds reasonable... 7. This seems to make sense to me so
  far 8. Yes this sounds good so far too". The words used: a **source** is anything that satisfies the record-source
  contract (this entry's 2026-11-01 "sources"). A **content layer** is a named slot in the order, holding any number of
  sources. The **stack** is the resolved order of every source. *Proposed names*, since "layer" already names the
  engine's layers and "store" a world's component stores.
  - **Choice 4: a layer changes fields, not whole records.**
    - **A patch names only what it changes,** by RFC 7396, which kama's `mergeJsonBuffer` implements. A map keyed by
      id merges per key, `null` removes an entry, and a plain list is replaced whole. Anything a layer must reach
      individually is keyed by a stable id: prefabs, and the entities placed in a zone.
    - **A prefab variant** resolves as its base's resolved value plus its own patches, so a later layer's change to the
      base reaches every field the variant never changed, as in Unity's prefab variants.
    - **Explicit operations** cover what a merge cannot: removing an entity (`null`), moving a prefab to another
      archetype the build has, and replacing a record whole.
    - **The failure this avoids** is Bethesda's "rule of one": *"the last-loaded plugin's version overrides all
      others"*, so two mods changing different fields of one record collide
      ([LOOT](https://loot.github.io/docs/help/introduction-to-load-orders/)).
    - **What it costs:** a mod adding one entry to a plain list must restate the list, so whatever mods are expected
      to extend, such as a loot table, is a map keyed by id.
  - **Choice 5: the order is data, not code.** The owner: "It doesn't need to be hard coded. It woudl be based on
    'database' priority. Your order is right though but there is no reason a game couldn't have 4 sets of DLC for
    example. Those 'layers' could be the default named layers for example and you can add priority asset 'databases'
    to each layer."
    - **The default content layers,** lowest first: engine, game, DLC, patch (with live tuning), mod, local. A game's
      records may name its own, and the stack gives each a priority.
    - **Each content layer holds any number of sources, each with a priority within it.** Four DLCs are four sources in
      the DLC layer. A source also states what it must sit above, as LOOT's rule has it: *"If one plugin changes a
      record added by another plugin, the former must load after the latter"*.
    - **The stack resolves to one order,** deterministically. Within one priority, deeper dependencies come first and
      then names in natural order, as Factorio orders its mods
      ([data lifecycle](https://lua-api.factorio.com/latest/auxiliary/data-lifecycle.html)). A cycle is refused, and a
      player orders mods within the constraints. The local layer never ships, and a release build refuses it.
    - **A source is whatever satisfies the contract:** files in git, a baked pack, a database (`@kama/postgres`), or, in
      the owner's words, "URIs for dynamic data updates? This is typically restricted on many consoles and such but
      possible on web, etc." So whether a remote source is allowed is a platform's capability
      ([target-platforms.md](target-platforms.md) question 3), never an assumption of the engine.
  - **Choice 6: a layer holds what the running game reads.** That covers prefab values, zones and their entities,
    singletons' starting values, the tuning of systems and engine modules, and budgets. A data layer adds only what
    the build already has code for (components question 5, choice 3), and a check names anything that needs a build.
    The wiki's prose, decisions and tasks are not layered; git versions them.
    - **Mods with code are roadmapped** (KYR-60). The owner: "I would assume that probably is mostly driven by kama
      scripting language when it lands. in that case code is content." kama's 2.0 plans *"dual-mode: compiled +
      scripting/REPL"* (kama KR-35). A mod's script would then be a source in the mod layer, hashed into the stack like
      its data.
  - **Choice 7: checks run on each source, then on the stack.**
    - **Each source alone, strictly:** a field no type declares, or a wrong type, is an error in that source, and
      nothing is written (probed in components question 5).
    - **The resolved stack:** references, rules that span records (question 5), and archetypes the build has.
    - **An error names the topmost source that set the bad value,** found from the patches by the tools.
    - **A source records what it was made against.** When a lower source later changes a field this one overrides, the
      check warns, and the override still wins, as Unity and Godot keep overrides
      ([../research/component-models.md](../research/component-models.md) § 5.5).
  - **Choice 8: the stack is part of the history.**
    - **Its identity is in every save, replay and match:** each source's id, version and content hash, in order. A
      replay under another stack is refused, and peers compare stacks at matchmaking, as they compare budgets.
    - **A recording carries any source that is not published,** such as a developer's local one, so a bug report
      replays on another machine.
    - **A source that changes while the game runs** (hot reload, live tuning, a remote update) applies at a step
      boundary as a recorded input, as a zone's arrival does (components question 4). Native hot reload of records
      needs a file watcher, which kama filed the same day as KR-330.
  - **Left to later questions:**
    - **question 2:** which sources the reference implementation ships;
    - **question 5:** the cross-system rules a stack is checked against;
    - **question 8:** where the bake boundary sits, and how a baked pack keeps its patches' provenance;
    - **[replay-and-determinism.md](replay-and-determinism.md) question 3:** how the stack's identity is written in the
      log.
