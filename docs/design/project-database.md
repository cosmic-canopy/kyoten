# The project database and wiki

**Status:** draft for the design spike; its build is KYR-24. Four decisions are recorded; the rest are questions.

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
11. **Layers, in detail** (see *Decided*). What is the priority order (the base game, DLC, patches, mods, a
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
