# Networking: netcode in the frame, and the hosted game backend

**Status:** draft. One decision is recorded: kyoten ships a backend server anyone can host, and the platform is the easy option for hosting it, never a lock-in. The engine's netcode is KYR-18; the server is KYR-45.

## What the vision asks

- In the frame: **network receive is Input** (recorded, so a session can be replayed) and **network send is
  Output**. Each system updates at the frequency that makes sense for it.
- **A networking backend that works for games, hosted by kyoten** as part of the developer platform
  ([marketplace.md](marketplace.md)). Refined the same day: the platform is the easy option, never a lock-in, and
  kyoten likely ships a backend server anyone can host (*Decided*).
- Web first: the browser's own transports.

## What already exists

- **The peers' netcode and backend:** transports (WebRTC data channels, UDP, a relay behind a TLS terminator), Steam
  networking, determinism and replay. See [../research/peer-games.md](../research/peer-games.md) § platform split and
  § determinism.
- **kama's transports:** TCP/UDP/Unix sockets and `Poller` natively; `std::net::web` has WebSocket, WebTransport and
  WebRTC on wasm. See [../research/kama-for-engines.md](../research/kama-for-engines.md) § web.
- **kama's fibers (KR-3) are a server model built for this:** one isolate per core, a fiber per connection,
  blocking-shaped code with no async colouring, measured against tokio and Go. Steps 1–6 shipped; Windows completion
  I/O and the job pool are still to come. See the fibers addendum in the kama research.

## The questions

### In the engine

1. **The replication model, or models.** Deterministic lockstep or rollback (inputs are the only thing sent, which
   suits the recorded Input phase), state replication with interpolation (a server owns the truth), or both as
   patterns a game picks? What does the engine provide, and what is the game's?
2. **Rates.** At what rate does the network Input receive and the Output send, relative to the simulation's rate?
   Is that per game, per component, or per channel?
3. **Transports behind one interface.** WebRTC data channels and WebTransport on the web; UDP (and the same
   protocols) natively. Which is the first, and is reliability and ordering per channel?
4. **The recording.** A network receive is an input like a key press, so a replay needs no network. Is that the rule
   ([replay-and-determinism.md](replay-and-determinism.md))?

### The hosted backend

5. **What does the backend do?** Candidates: relay and NAT traversal (TURN), matchmaking, lobbies, sessions,
   authoritative game servers that run the same kyoten simulation headless, presence, leaderboards, cloud saves.
   Which are first?
6. **Is it written in kama?** The fiber server model is kama's answer for many connections. Does the backend run
   kyoten's own simulation for authoritative servers, so the server code and the game code are one?
7. **Hosting.** Where it runs, how it scales per game, and how a developer deploys a game's server side
   ([marketplace.md](marketplace.md)). Is it multi-tenant from the start?
8. **Accounts and identity**, shared with the marketplace: one identity for players and developers?
9. **Security:** authentication of sessions, anti-cheat stance (authoritative state versus trusted clients), rate
   limits, abuse.

## Decided

- **2026-11-01, the owner: the platform is the "easy button" for networking, never a lock-in.** Self-hosting a
  backend for kyoten is fine, and kyoten will likely ship a backend server of its own. The platform's offerings are
  meant to be fair and easy to use, which is why a developer may choose it to host for them, and no developer should
  feel locked in.
  - **What it settles:** the backend *server* is kyoten's, open like the engine, and anyone may host it (KYR-45).
    *Hosting* it for developers is the platform product's ([marketplace.md](marketplace.md)). The netcode in the engine
    is questions 1–4 (KYR-18).
  - **What it asks of the design:** a game reaches its backend the same way whoever runs it, so moving between
    self-hosting and the platform is a change of deployment, not of code. How that is done is for questions 5–9, with
    KYR-45 and KYR-44.
  - *This corrects a reading recorded earlier the same day, which had moved the whole backend (questions 5–9) to the
    platform product.*
