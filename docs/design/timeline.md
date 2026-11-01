# Timeline and cinematic tools

**Status:** draft for the design spike. These are questions, not decisions.

## What the vision asks

- **Timeline and cinematic tools** for humans, as part of the tuning tools along the way.

## The questions

1. **What does a timeline drive?** Component properties over time (keyframes and curves), events (play a sound, start a
   state), cameras (cinematic shots), animation clips. Is it a general "animate any component field" tool, or a
   set of specific track types?
2. **How does it play at runtime?** As a component the Update phase advances at its own rate, deterministic so a
   replay reproduces it ([replay-and-determinism.md](replay-and-determinism.md))? How does it blend with gameplay
   control (a cutscene taking the camera, then handing it back)?
3. **One clock with the DAW?** Do audio and timeline share a transport (play, scrub, loop), so a cinematic is cut to
   its music ([audio.md](audio.md))?
4. **Authoring by AI and by humans.** A timeline is a project-database record ([project-database.md](project-database.md)):
   an agent can write one, and a human adjusts its keys. What makes a timeline easy for an agent to write
   correctly (a declarative format, named tracks, validation)?
5. **Scrubbing a running game:** preview a timeline in the live game, at any point, without a restart?
6. **In the first slice, or later?**

## Decided

*(nothing yet — filled in during the walk-through)*
