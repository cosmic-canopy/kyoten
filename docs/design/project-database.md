# The project database and wiki

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- kyoten **generates games by maintaining an AI-coordinated database and wiki of the game project.**
- **Several agents** design and coordinate across systems through it, and **the game project stays consistent.**
- **Humans see the full process** and can tune along the way.

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
6. **How do agents coordinate?** Roles (a design agent, an audio agent…), claims or locks on records, change
   proposals and review, conflict resolution, and an event log of who changed what and why (provenance).
7. **What do humans see and do?** A live feed of changes, approve or reject, the audit trail, and tuning edits
   that flow back into the records exactly as an agent's would.
8. **How does the running game read it?** Directly in development, with hot reload, and from a baked, packed form
   when it ships? Where is that boundary?
9. **What interface do agents use?** Files plus `kama query`, a `kyoten` CLI (`kyoten db get/set/query`), an MCP
   server, an HTTP API shared with the human tools, a JSON schema export for tool use. One of these, or a layered
   set?
10. **How does it relate to cosmic-forge?** Shared ids and provenance for assets, and forge writing into the
    project database or kyoten reading forge's outputs.

## Options worth comparing

- **Files in git, typed by kama serde.** Diffable and reviewable, no server. Merges are text merges, and concurrent
  agents need a coordination layer on top.
- **An embedded database with a text export.** Queries and transactions; review happens on the export, so two
  representations must agree.
- **Event-sourced:** an append-only log of changes, with records as its projection. Provenance and replay come
  free, which matches the engine's own replay model, at the cost of more machinery.

## Decided

*(nothing yet — filled in during the walk-through)*
