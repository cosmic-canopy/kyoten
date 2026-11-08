# The project database and wiki

**Status:** draft for the design spike; its build is KYR-24. Questions 1–6, 8 and 11 are decided (11 on 2026-11-05, the
rest on 2026-11-07, a first version that building games will revise); 7 waits for KYR-26, 9 for KYR-25 and 10 for
KYR-29. On 2026-11-07 a content layer was named in full a **content database priority level**, and a source's field
changes a **merge patch**.

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

1. **What is a record?** *(Decided 2026-11-07, below.)* Candidates: an entity or prefab definition, a component's
   tuning, an asset reference, a level, a timeline, a design note, a decision, a task. Is all of that one database, or
   several with shared ids?
2. **Where does it live?** *(Decided 2026-11-07, below.)* Plain text in the game's repo (JSON or markdown, with git as
   history, diff and review), an embedded database (SQLite) exported to text for review, or a service. What does each
   mean for merging two agents' work, and for a human reading a diff?
   - *Noted 2026-11-06:* a scene is what a designer opens ([components.md](components.md) § Decided, scenes, zones
     and layers), but it may be stored as a folder of records per zone. Unreal stores one file per actor, so "you do
     not need to check out the Level file from source control to make changes to the Actors in the world"
     ([World Partition](https://dev.epicgames.com/documentation/en-us/unreal-engine/world-partition-in-unreal-engine)),
     and streaming reads one zone without the rest.
3. **Database and wiki: one source or two?** *(Decided 2026-11-07, below.)* Is the wiki generated from the records (one
   truth, always current), or written prose that links to records by id?
4. **Who defines the schema?** *(Decided 2026-11-07, below.)* The engine ships the core schemas (transform, mesh, sound,
   timeline…) and a game extends them, presumably typed through kama serde so a record and the component that reads it
   cannot drift. How does a game add a record type?
5. **What does "consistent" guarantee?** *(Decided 2026-11-07, below.)* Referential integrity (every id referenced
   exists), schema validity, and cross-system invariants (a level's spawn points are on navigable ground). Which are
   checked when, and who is told when one breaks?
6. **How do agents coordinate?** *(Decided 2026-11-07, below.)* Concurrently, on separate machines (above). Roles (a
   design agent, an audio agent…), claims or locks on records, change proposals and review, conflict resolution, and an
   event log of who changed what and why (provenance).
   - *Noted 2026-11-06 at components question 8:* ids made on many machines without coordination may be UUIDv7s
     (RFC 9562), which kama ships as `std::uuid::Uuid.v7()`: time-ordered, so "Time-ordered monotonic UUIDs benefit
     from greater database-index locality". They are never an entity's handle, which must be deterministic.
7. **What do humans see and do?** A live feed of changes, approve or reject, the audit trail, and tuning edits
   that flow back into the records exactly as an agent's would.
8. **How does the running game read it?** *(Decided 2026-11-07, below.)* Directly in development, with hot reload, and
   from a baked, packed form when it ships? Where is that boundary?
9. **What interface do agents use?** Files plus `kama query`, a `kyoten` CLI (`kyoten db get/set/query`), an MCP
   server, an HTTP API shared with the human tools, a JSON schema export for tool use. One of these, or a layered
   set?
10. **How does it relate to cosmic-forge?** Shared ids and provenance for assets, and forge writing into the
    project database or kyoten reading forge's outputs.
    - *Noted 2026-11-06 at components question 8:* an asset's shared id is a candidate for UUIDv7, as question 6's
      note says; so are saves, replays, matches and mods.
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
- **2026-11-07, the owner: question 2, in part — the format and layout of records kept as files in git.** Decided at
  [components.md](components.md) question 8 part b, where the full entry is. "I will take your recommendation on both
  yes."
  - **Strict JSON, typed by kama serde,** with an optional `note` string on every record kind instead of comments, which
    kama's JSON reader refuses (KY-31).
  - **A record lives with what it describes:** records that describe code as `src/<module>/*.records.json` beside it,
    named by their folder as kama code is; content records (prefabs, scenes, budgets, bindings, the app) under
    `content/`. A scene is a folder with a file per zone, as this question's 2026-11-06 note proposed.
  - **Still open in question 2:** which backend is the reference, and how two agents' work on one record merges.
- **2026-11-07, the owner: question 11's words renamed,** at [components.md](components.md) question 8 part b, where the
  full entry is.
  - **A content layer keeps its name, and in full is a content database priority level.** The owner: "it is basically
    a content database priority level", and after "priority level" was proposed and taken: "Content Database
    Priority Level may be the fully qualified... even content layer actually sounds good for short now that I think
    about it. it gies context." The defaults, lowest first, are engine, game, DLC, content patch, mod and local.
  - **The content layer named "patch" is the content patch** ("priority level and content patch"), holding a game's patches, current and superseded, and live tuning.
  - **What a source says about a record is a merge patch** (RFC 7396's "JSON Merge Patch"), so a bare "patch" is a
    game's patch.
  - The entries above keep the words they were written in.
- **2026-11-07, the owner: questions 1–4, what a record is, the backend, the wiki and the schema.** "This all sounds
  good to me so far." With this, question 2 is decided in full. Questions 5, 6 and 8 are next.
  - **The evidence for question 2,** probed here with git 2.55 on Windows, in a scratch repository. One branch changed a
    prefab's `Turret.cooldown` and another its `Health.hp`, on neighbouring lines of one records file, and git's line
    merge reported *"CONFLICT (content)"*. A field-wise three-way JSON merge, set as git's merge driver for that file,
    merged the same branches cleanly, and reported a conflict when both changed `cooldown` to different values. git's
    gitattributes documentation: *"The definition of a merge driver is done in the `.git/config` file, not in the
    `gitattributes` file"*, so a driver is set up in each clone.
  1. **Question 1: one database with two halves, sharing one id space and one query surface.**
     - **Game data** is what the running game reads (question 11, choice 6): component values in prefabs and
       placements, scenes, zones, layers, budgets, bindings, the app, modules' code records, and UI documents. It is
       layered by the stack, typed by kama and checked.
     - **Project knowledge is the wiki:** the game's direction (its vision, pillars and style), design notes, decisions
       and tasks. The running game never reads it, it is not layered, and git versions it.
     - **One query or MCP call answers across both,** such as "which open tasks touch the tower prefab".
  2. **Question 1: a game's own data kinds.** Data that is neither a component nor a world component (a loot table,
     dialogue, quests) is a kama type the game lists in its module's records as a **data kind**. Its entries live under
     `content/`, keyed by id, and layer like any record. Processors read them read-only through the stack, by generated
     ids, so a mistyped id is a build error as a prefab's is. Prior art: Unreal's Data Tables and Unity's
     ScriptableObjects *(general knowledge, not checked)*. The spelling is KYR-24's.
  3. **Question 2: files in git are the reference backend, and the only one built first.** The store interface keeps
     room for `@kama/postgres` or a platform service, built when a project asks for one.
  4. **Question 2: two agents' changes to one record merge by field, not by line.**
     - **`kyoten merge`,** git's merge driver for `*.records.json`, merges three ways by key. Different fields never
       conflict, and one field changed two ways is a conflict named by its path. kyoten's setup registers it in each
       clone.
     - **`kyoten fmt`** writes records in one fixed key order and indentation, so a diff shows only what changed.
     - **The merged result is checked** (question 5), since two valid changes can merge into an invalid one: one agent
       deletes a prefab that another places.
     - **A hosting site's merge button runs no custom driver** *(from memory, not checked)*, so a conflict there is
       merged locally.
  5. **Question 3: one source, with two kinds of page.**
     - **Generated pages,** one per record, always current and never edited by hand: its resolved value and which
       source set each field, what refers to it, the code that reads it, and its recent changes.
     - **Written pages** (direction, notes, decisions, tasks) are Markdown under `wiki/`, each with an id and a few
       typed fields (kind, status, owner) that tools and agents query. A link from prose to a record is checked like
       any reference, so renaming a prefab breaks a link at check, not silently.
     - **Readable without kyoten:** plain Markdown in git reads on any host, and the human tools (KYR-26) serve it live
       beside the generated pages.
  6. **Question 4: kama types are the only schema.** The engine's record kinds are its kama types, and a game's
     components, world components and data kinds are its own. A record decodes strictly into its type (components
     question 5), so with no second schema language a record cannot drift from the code that reads it. A game adds a
     record kind by declaring a type (item 2).
  7. **Question 4: the generator exports a JSON Schema for every record kind,** so an editor completes and checks
     `*.records.json` as it is typed, and an agent's tool call gets the exact shape. kama has none (its std and docs
     searched, 2026-11-07), so kyoten's generator writes it from the types it already reads.
  8. **Question 4: a type changes by deprecating, then migrating.** A renamed or removed field is a check error in every
     record that uses it. kama's `@deprecated` on a field (*"read when present, never written"*, kama's `AGENTS.md`)
     keeps an old name readable for a time, and `kyoten migrate` rewrites the records in one commit, so mods made
     against an older version still load.
- **2026-11-07, the owner: questions 5, 6 and 8, consistency, coordination and how the running game reads.** Asked
  what it means in practice, the owner set its purpose: it is for games, *"a literal wiki of documentation,
  screenshots, etc. to describe gameplay systems and such to coordinate across agents"*; *"Humans always have the say in
  overridding?"*; and *"I don't want it to slow development... I am hoping it keeps things on track and allows multiple
  agent sto run in parallel on different features, etc."* Then, on items 1–14: "I think this all sounds good so far. We
  will know more during the actual game development cycle how well it works and what changes we need." So this is a
  first version, revised as games are built on it, slice C (KYR-28) first. Questions 7, 9 and 10 wait for their builds.
  - **The scope:** a game project's database and wiki, one per game. kyoten's own engine and tools are built as this
    repository is, with design docs, decisions and a roadmap written by hand; a game's wiki is that practice as tooling.
  1. **Question 5: three kinds of check, each naming the record and field.**
     - **Shape,** per source: a record decodes strictly into its kama type (question 11, choice 7).
     - **References,** over the resolved stack: every prefab, placed name, kama path, action, data-kind id and wiki
       link exists, every archetype is one the build has, and budgets fit.
     - **Rules** that span records, declared by a module ("a turret's target is a tower", "every spawn point stands on
       navigable ground"): a kama function over the resolved records, listed in its module's records, returning
       diagnostics. A rule that needs derived data (a nav mesh, physics) runs with its scene loaded headless.
  2. **Question 5: when they run.**
     - **On every write through kyoten's tools** (the CLI, MCP, the editor): shape and references. A failing write is
       refused, and nothing is written.
     - **`kyoten check`** runs all but the rules that need a loaded scene, which run in `kyoten test` beside the replay
       tests (KYR-13).
     - **CI checks the merged result every time,** since two valid changes can merge into an invalid one.
     - **On hot reload,** a source that fails its checks is not applied. The running game keeps its last good stack, and
       the tools show the error.
  3. **Question 5: who is told, and what blocks.** The change's author, agent or human, gets the topmost source that set
     the bad value, the field, the rule and the change that brought it. A break found only after a merge becomes a wiki
     task for the authors of both sides, and shows in the change feed (KYR-26). Errors block a merge and a release
     build; warnings, such as a stale override, do not.
  4. **Question 6: git is where agents meet.** Each agent works in its own clone or worktree, on a branch, on any
     machine, and its work lands by merging into the game's main line, as a human's does. No server is needed; a live
     service may come later through the store interface.
  5. **Question 6: tasks are wiki pages, and a claim is advisory.** A task has an id, a status, an owner and a scope:
     the modules, records or pages it expects to touch. An agent claims one by setting the owner and pushing, the peers'
     `WORKING.md` made data. A claim is never a lock, which a stopped agent would hold for ever: kyoten warns when two
     open claims overlap, and the field merge does the rest.
  6. **Question 6: provenance is in each commit's trailers:** the agent or human, its role, and the task or decision
     the change serves. git's history read through them is the event log, and a record's generated page shows its
     recent changes from it.
  7. **Question 6: roles are write scopes, optional per project.** A role names what its agents may change (modules,
     record kinds, `content/` paths, wiki sections), as GitHub's CODEOWNERS does *(general knowledge, not checked)*. A
     change outside its author's scope needs a human's approval, whose form is question 7's (KYR-26).
  8. **Question 6: one game direction.** Every agent reads the wiki's direction pages (vision, pillars, style) and its
     decisions before it works, and a change cites the task or decision it serves. An agent that would contradict a
     decision proposes a new one, and a human decides.
  9. **Question 8: the boundary is the one [components.md](components.md) drew** (question 5, choice 3). What needs a
     build (a type, an archetype, a processor) is compiled, and everything a record change can hot-reload is data, read
     through the stack. In development the stack reads files, and a change applies at a step boundary as a recorded
     input (question 11, choice 8), with item 2's last good stack.
  10. **Question 8: a shipped game reads a pack per source:** that source's merge patches, checked and joined into one
      file. A pack is a source like any other, so one stack reads files and packs, and DLC and mods still layer by
      field at load. Records stay JSON (components question 8 part b), minified and compressed; a binary encoding comes
      only if measured load times ask for it (KYR-24 measures).
  11. **Question 8: a pack keeps its provenance:** its source's id, version and hash (the stack's identity, question 11,
      choice 8) and the commit it was baked from. Per-field history stays in git, as debug symbols stay beside a
      binary, and an error in a player's stack still names its source and field. On the web a pack is one fetch, at a
      URL named by its hash, so a browser caches it until it changes. A release build reads packs, and mods where the
      platform allows them, and refuses the local layer.
  12. **Captures** (the owner's "screenshots"): a wiki's screenshots and clips live in the asset store, not in git, by
      the owner's rule that heavy assets never sit with the code (SPIKE's standing direction, 2026-11-05). Each keeps
      the recipe that took it: scene, build, stack, step and view. The simulation is deterministic, so the tools can
      tell a stale capture and retake it.
  13. **Humans override everything.** A human can override an agent's change, claim or decision, waive a failing check
      with a recorded reason, or change the rule. An agent never overrides a human's decision; it proposes a new one.
  14. **Light by default.** Roles and approvals are off until a project turns them on, a claim never blocks, and the
      slow checks run in CI, not while an agent works. The field merge is what lets agents build different features in
      parallel.
- **2026-11-08, the owner: how a running build reaches its content records in development** (the first slice's step
  5, question 3 of 7). "Sounds good to me so far."
  - **What was open:** question 8 decided that in development the stack reads files and a shipped game reads packs, but
    not how the files reach a running build, natively and on the web, nor where the engine's own default records live.
  - **The engine's default records live in `engine/content/`,** the engine's content layer, the lowest of the stack:
    the window, the camera, the light, the material, the scene's one zone and its `main` layer, and the default budget.
  - **The loader reads through a `RecordSource` contract,** the "source" of question 11, choice 5 (a source is
    whatever satisfies the contract). Its first implementation is a folder, read with `std::fs` and kama's strict JSON
    reader.
  - **Natively, in development,** the game reads its folders at the paths the generator resolved, written into the
    generated code, which is never committed.
  - **On wasm, the folders reach the program's virtual filesystem through kama's `preloadFiles`,** packed into one
    `.data` file that the page fetches once before `main`. It is an asset, so the A1 check's 150 KB of code does not
    count it. The engine's manifest declares its own folder, and a dependency's `preloadFiles` reaches every game.
  - **When a game ships, packs replace the folders** (question 8, item 10 above), each one a source like any other.
  - **Probed on kama `0.9.876+g7ce86d36`** (`.scratch/step5-content`): an engine package with `content/` and
    `"preloadFiles": ["content@/eng/content"]`, and a game with its own; `main` walks both folders in sorted order
    and reads every `*.records.json` with `JsonDeserializer.strict`.
    - **Natively, under node and in headless Edge 157** (served from localhost), the output was the same three lines:
      two records read, and a misspelt key refused as ``unknown field `app.titel` ``, named by its path.
    - **On wasm both folders arrived in one `game.data` of 140 bytes,** the engine's through its own manifest.
    - **Under node, emscripten looks for the `.data` file in the working directory,** not beside the script, so a
      test runs node from the build's folder. A browser resolves it beside the page.
  - **Considered:** the generator baking the content into the build as code. It needs no file system, but a record
    change would need a build, against question 8's boundary (what a record change can hot-reload is data), and the
    content would count as code on the web.
