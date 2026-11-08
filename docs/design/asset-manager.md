# The asset manager: delivering a game's built assets

**Status:** draft, split out of KYR-29 on 2026-11-08 as KYR-66. These are questions, not decisions. The name is a
working one, and question 1 asks it.

## What the vision asks

- **The owner, 2026-11-08:** the asset manager is "something that kyoten games can use to deliver final asset bundles",
  while cosmic-forge handles most of the raw content creation.
- **Heavy assets are never stored with the code** (the owner, 2026-11-05, [../SPIKE.md](../SPIKE.md) § Standing
  direction): "I just want to make sure we don't store all of the heavy stuff with the code." Three things are kept
  apart:
  - **code and records,** light text in git;
  - **source assets,** authored through cosmic-forge, in whatever store a team uses (git LFS, Perforce, a custom
    store);
  - **built runtime assets,** "produced by asset builds, hosted, and downloaded to developer machines and players by a
    delivery tool". Code and a built asset set must agree on the contract that reads them, "so the delivery tool
    fetches the asset build that matches the code".
- **cosmic-forge stays the general-purpose content-creation component;** kyoten uses it and does not duplicate it
  ([../VISION.md](../VISION.md)).
- **A platform to build, deploy and sell games and content,** "something like Steam or the Unity asset store", which
  kyoten hosts ([../VISION.md](../VISION.md)). It is a separate product, the easy button and never a lock-in
  ([marketplace.md](marketplace.md) § Decided).

## What already exists

**In kyoten, decided:**

- **Records reach a running game through the stack** ([project-database.md](project-database.md) § Decided).
  - In development the loader reads folders through a `RecordSource`: from disk natively, and on wasm from the one
    `.data` file kama's `preloadFiles` packs them into (2026-11-08).
  - A shipped game reads **a pack per source**: its merge patches joined into one JSON file, carrying its source's id,
    version and hash and the commit it was baked from. "On the web a pack is one fetch, at a URL named by its hash, so
    a browser caches it until it changes" (question 8, items 10 and 11, 2026-11-07).
  - **A pack holds records, not heavy assets.**
- **The stack's identity is in every save, replay and match:** each source's id, version and content hash, in order
  (project-database question 11, choice 8).
  - A replay does not record asset contents, as "fixed by the stack's identity"
    ([replay-and-determinism.md](replay-and-determinism.md), question 2).
  - That holds only if a record pins the asset it names (question 4 below).
- **At run time an asset is kind-3 data:** "shared read-only data", a mesh, a clip, a navmesh, held in "an asset store
  loaded with the zone and unchanged while it runs", with the component holding a `Handle`
  ([components.md](components.md) § Decided, question 2's four kinds).
- **Captures** (a wiki's screenshots and clips) live "in the asset store, not in git", each with the recipe that
  retakes it (project-database question 8, item 12).
- **The web's code budget leaves assets out** (150 KB of code for the hello cube), and "assets get a budget of their
  own", rendering question 6 and KYR-10's ([web-and-native.md](web-and-native.md) § Decided).
- **A remote source is a platform capability:** "URIs for dynamic data updates … typically restricted on many consoles
  … but possible on web" ([target-platforms.md](target-platforms.md), question 3).

**Proposed, never settled:** "a record refers to an asset by id and content hash, never by embedding it" (SPIKE's
standing direction, 2026-11-05).
- It was sent to content-pipeline question 1, project-database questions 2 and 8, and examples question 4.
- Project-database questions 2 and 8 were decided on 2026-11-07 without it.
- An asset's id is a candidate for UUIDv7, as forge's ids are ([components.md](components.md) § Decided, question 8
  part a, choice 3; [project-database.md](project-database.md) question 10).

**In cosmic-forge, planned and unbuilt** ([../research/cosmic-forge.md](../research/cosmic-forge.md) § 4,
*Planned*):
- a Postgres catalogue of assets with "sha256 and URIs";
- a store at `<store>/<uuidv7 date>/<uuidv7>.<ext>` "outside the game repo";
- "bundles keyed to a range of game commits", which is the code-to-asset match the standing direction asks for;
- a provenance sidecar written at publish;
- destinations, "`file://` now, `s3://` later", each copy leaving the machine "confirmed every time".

**In kama:**
- **The package registry** is "a working example of hosting and publishing *code* packages": an index in git on
  Cloudflare Pages, tarballs in an R2 bucket, integrity hashes and signed publishing ([marketplace.md](marketplace.md)).
- **`preloadFiles` and `embedFiles`** bundle files into a wasm build. Fetching assets on demand is kyoten's to build
  ([../research/kama-for-engines.md](../research/kama-for-engines.md)).

**In the peers** ([../research/harvest.md](../research/harvest.md)):
- **FFD** keeps assets beside the executable natively and embeds them on the web. Its tools make a self-contained
  bundle per OS, and its Windows bundle is 55 MB, 31 MB of it a speech model ([../research/web-baseline.md](../research/web-baseline.md)).
- **the-mallow-man** reads external `.ktx2` textures, RGBA8 and BC7 only. BC7 is a desktop format, so the web and a
  Quest would want Basis or ASTC *(inferred there)*.

**Words already in use that a name must not collide with:**
- **"bundle"** already means six things: KYR-10's "bundled on the web", KYR-21's "bundles for Steam", marketplace
  question 2's "project-database bundle", version-manager question 1's "one versioned bundle", forge's "bundles keyed
  to a range of game commits", and the owner's "final asset bundles".
- **"Pack"** is decided as a record source baked for shipping (REFERENCE's vocabulary). Marketplace question 1 also
  says "content packs (assets, characters, audio)".
- **"Asset store"** means the runtime store of kind-3 data (components) and the place outside git where captures live
  (project-database).

## The questions

1. **The name.**
   - The owner said "asset manager"; the SPIKE and KYR-29 say "delivery tool".
   - In Unreal, the Asset Manager is a runtime object that loads and tracks primary assets *(general knowledge, not
     checked)*, so "asset manager" may read as the runtime loader rather than the delivery side.
   - Whatever it is called, should "bundle" (and "pack", and "asset store") each get one meaning in REFERENCE's
     vocabulary at the same time?
2. **Whom it serves.** The standing direction names developer machines and players. Is it one tool for:
   - a developer fetching the asset build that matches a checkout;
   - CI building and publishing asset builds;
   - a player's install, download and patch;

   or is it two halves, a developer tool and a runtime delivery module, sharing one format?
3. **What a bundle is.**
   - **Its unit:** a game version, a scene or zone (streaming, KYR-61), a platform, or a content layer (game, DLC, mod).
   - **Its relation to a pack:** is a bundle the heavy half of a pack, shipped and identified together, or separate
     with its own identity?
4. **How a record names an asset.** The open proposal is "by id and content hash":
   - **The id:** forge's UUIDv7, or a name a record already uses?
   - **Where the hash lives:** in each record, or in a manifest the stack's identity covers? This decides whether
     replays and saves pin asset contents as the replay doc assumes.
5. **Matching code and assets.** How a checkout finds the asset build that matches it:
   - forge's "bundles keyed to a range of game commits";
   - a contract version (a record schema, an asset format's version);
   - or a lock file in the game's repository naming the asset build by hash, as `kama.lock` names packages.
6. **Hosting.** Where built assets live, and who hosts them:
   - any static host or bucket (R2, S3), self-hosted, with the kyoten platform as the easy button and never a lock-in;
   - content-addressed URLs a browser caches by hash, as a pack's are;
   - a store's own delivery (Steam's depots, a console's patching, the Meta Horizon Store) where a platform requires
     it.
7. **Per-platform builds.** One source asset may need several built forms (BC7 on desktop; Basis or ASTC on the web
   and Quest). Is there a bundle per platform, chosen at download, or a format chosen at load?
8. **The web.**
   - One `preloadFiles` `.data` fetch before `main`, or fetched on demand as zones stream (KYR-61)?
   - Kept where between visits (the HTTP cache, the Cache API, OPFS)?
   - Against which asset budget (rendering question 6)?
   - Every served file needs CORP for the threaded build ([web-and-native.md](web-and-native.md) § Decided).
9. **Native installs and updates.**
   - Assets shipped with the build (KYR-21's bundles), or downloaded at first run?
   - Patched by delta?
   - How DLC and mods bring theirs?
10. **Integrity and trust.**
    - Verifying a content hash at load.
    - Signing a published bundle, as kama's registry signs packages.
    - What a remote source may do on each platform (the capability above).
11. **The boundary with cosmic-forge** (with content-pipeline questions 1 and 2).
    - forge plans a catalogue, a store, bundles and publish destinations. Does forge publish into the asset manager's
      store, or is the asset manager forge's publish step seen from the game?
    - Which side makes the runtime forms (KTX2 compression, glTF optimization)?
12. **What a game's repository holds.**
    - The lock or manifest of question 5, and a `kyoten` command that fetches and verifies (beside `kyoten generate`).
    - Whether a fresh clone fetches assets before it builds, as it generates code first (KY-28).
    - Whether captures share the store.

## Decided

*(nothing yet)*
