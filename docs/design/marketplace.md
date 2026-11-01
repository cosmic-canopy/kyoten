# The developer platform: build, deploy and sell

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **A platform for developers to build, deploy and sell games and content**, something like Steam or the Unity
  asset store. **kyoten hosts the marketplace.**
- **A hosted networking backend for games** ([networking.md](networking.md)).
- Web first: a game is a web page before it is anything else, so deploying one can be as short as publishing a URL.

## What already exists

- **kama's package registry** (`registry.kama-lang.org`): an index in git deployed to Cloudflare Pages, tarballs
  in an R2 bucket, integrity hashes, signed publishing, metadata and a search catalogue. It is a working example of
  hosting and publishing *code* packages. See [../research/kama-for-engines.md](../research/kama-for-engines.md) §
  packages.
- **cosmic-forge** produces the content a marketplace would sell (meshes, textures, characters) and has a planned,
  unbuilt publish step to destinations by URI. See [../research/cosmic-forge.md](../research/cosmic-forge.md).
- The peers ship to Steam (depots, notarized Mac builds) and know its requirements. See
  [../research/peer-games.md](../research/peer-games.md).

## The questions

1. **What is sold?** Games (played on the web, or downloaded native builds), content packs (assets, characters,
   audio), engine extensions (components, tools), templates. Which first?
2. **What is a "package" here?** A kama package on the registry is code. Is a content pack a project-database
   bundle ([project-database.md](project-database.md)), a forge output, or something new? Does one manifest format
   cover games, content and code?
3. **Deploy.** A web game hosted by kyoten at a URL, with the static-hosting shape the registry already uses? Native
   builds distributed through the platform, signed (kama's own signing question, KR-135, applies to games too)?
   The game's server side on the hosted backend?
4. **The developer loop.** From the editor ([human-tools.md](human-tools.md)): build, preview, publish, update. Can
   an agent publish, and what does a human approve?
5. **Selling.** Payments, revenue share, licensing of content (what a buyer may do with an asset), refunds, tax.
   Which of these does kyoten build, and which does it buy from a provider?
6. **Players.** Accounts, libraries, cloud saves, social features: shared with the networking backend's identity?
7. **Trust and safety.** Review of uploads, malware scanning of native builds, content moderation, takedowns.
8. **When?** The platform matters to the engine's design now (what a game package *is*), even if it is built
   later. What must the engine decide early so the platform can follow without a break?

## Decided

*(nothing yet — filled in during the walk-through)*
