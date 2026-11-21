# Input: devices into a game's actions

**Status:** draft, four questions for the first slice's step 8 (KYR-54). These are questions, not decisions. What the
peers and the owner's games do is [../research/input.md](../research/input.md).

## What is already decided

- **Actions are code records and bindings are content** (components § Decided, question 7, choice 4, 2026-11-05): the
  generator writes one field per declared action into a game's `Actions`, so a typo is a compile error, and bindings
  are records of their own, a default per device, rebound in the developer's and the player's layers.
- **Actions belong to a player** (components § Decided, revised 2026-11-06): an entity's `Actions` names the player
  that drives it, and the Input phase fills it each step. The engine's defaults gain one player, bound to the local
  keyboard and the first gamepad.
- **The kinds** (components § Decided, 2026-11-08): `Digital`, `Analog`, `Vector2`, `Vector3`, `Pose` and `Text`, named
  for the value a processor reads. Step 5 built `Digital`.
- **Input across several owed steps is split by timestamp, and edges wait for a step that consumes them**
  (frame-phases § Decided, 2026-11-04). Presentation reads, such as camera look, take the newest sample each frame. On
  the web a gamepad is polled once a frame.
- **What is recorded is each player's actions after the binding** (replay-and-determinism § Decided, question 2), never
  device events, so a rebind or a player's dead zone cannot move the world hash. Typed text is an event with its
  payload at the next hand-off.
- **`@kama/window`'s WIN-4** (the owner, 2026-11-12): dead zones, drift and response curves are the bindings', per
  player; the package reports a pad's values untouched, with what identifies a pad (`PadInfo`). A returning pad goes to
  the disconnected player, the console pattern (its decision 4).
- **The owner's direction for the row** (KYR-54, 2026-11-06 and 2026-11-07): players as numbered slots with a budget,
  each with its sources; steps that reshape a value and recognize input over time ("adapter" to be renamed, since kama
  has `type adapter`); input contexts with a priority; only Input writes actions.

## The questions for step 8

Laid out from the code at the forty-fourth session's readying (2026-11-21), and asked in full in the chat that day.
Contexts, more local players joining, rebinding in a game's own UI, and swipes, pinches and shakes (which need touch,
WIN-11, and a pad's sensors, WIN-22) are KYR-54's later parts.

1. **Where an input's time comes from.**
   - *Example:* a game with a 120 Hz physics processor on a 60 Hz display owes two steps a frame. A player presses
     Space just after a frame. Split by time, as decided, the press lands in the first of the next frame's two steps;
     with no time it lands in the second, 8.3 ms later, and a press and release inside one frame land in one step.
   - *The problem:* `@kama/window`'s events carry no time. On the web the DOM's `timeStamp` is on the clock kama's
     `Instant` reads there (`performance.now()`, kama's `include/kama_time.h`). Natively GLFW gives none and calls back
     inside `glfwPollEvents`, so a key's best time is the pump's; SDL stamps a GameInput pad's button with its reading's
     time, and an XInput pad with the poll's ([../research/input.md](../research/input.md)). Unity stamps every event
     and splits by it; Godot, Bevy and Steam Input have no times.
   - **(A) `@kama/window` gives each event its time** on kama's monotonic clock, the best its backend has: a package
     row, `pollEvent` handing the event with its time, which breaks its callers (kyoten, `@kama/graphics`' examples and
     tests, the package's own). kyoten splits by it: each owed step takes the events in its window, the frame's last
     owed step everything up to the pump, and a frame that owes none keeps its events for the next step. On the web each
     key, pointer and pad sample has its own time at once; natively a key's is the pump's until a backend gives more
     (WIN-19's high-rate input).
   - **(B) kyoten stamps each event at its own pump:** every event of a frame goes to its last owed step, on every
     platform, and the decided split stays unbuilt. A stopgap until (A).
   - *Recommended:* (A).
2. **The bindings record's shape.**
   - *Example:* "faster" on ArrowUp or W; "move" on WASD and the left stick with a dead zone; "dash" on a double tap of
     Space.
   - *The problem:* today's `BindingRecord` holds one control name per device, so it can say none of these.
   - **(A) The decided keying, action then device, with a device's entry a control, a list of controls, or an object:**

     ```json
     { "bindings": {
         "faster": { "keyboard": ["ArrowUp", "KeyW"], "gamepad": "RightShoulder" },
         "move":   { "keyboard": { "up": "KeyW", "down": "KeyS", "left": "KeyA", "right": "KeyD" },
                     "gamepad":  { "x": "LeftX", "y": "LeftY", "filters": [ { "radialDeadZone": 0.2 } ] } },
         "dash":   { "keyboard": { "control": "Space", "gestures": [ { "multiTap": 2 } ] } } } }
     ```

     Controls are `@kama/window`'s names (its `LeftStick` is the stick's click, so a stick is its two axes). A layer
     replaces one device's entry by its key, as every record merges (RFC 7396), so a player rebinding the keyboard
     leaves the pad's alone, as FFD's and the-mallow-man's two columns do.
   - **(B) Unity's:** a list of bindings per action, each a control path with its steps as strings, a composite a
     marked entry followed by its parts. A list merges whole, so a player's layer would rewrite every binding of an
     action to change one; Unity keeps overrides apart, by binding, for that reason.
   - **(C) Unreal's:** contexts listing key to action, with no composite type: WASD as four mappings with Negate and
     Swizzle modifiers.
   - *Recommended:* (A).
3. **The words for a binding's steps,** in place of "adapter".
   - *The problem:* the peers' pairs collide with kyoten's words. Unity's and leafwing's "processor" is kyoten's
     function the scheduler runs, and Unreal's "trigger" names a pad's control (`RightTrigger`).
   - **(A) A filter reshapes a value each step** (a dead zone, a scale, a curve, a threshold), **and a gesture
     recognizes a pattern over time** (a hold, a tap, a double tap, a chord, a sequence), the owner's own word. A
     binding lists its `filters`, then its `gestures`, in the order both peers apply theirs.
   - **(B) Modifier and interaction,** Unreal's first word and Unity's second.
   - *Recommended:* (A).
4. **Which pads drive player 1** while a game has one player.
   - *Example:* two pads on the desk; the player picks up the one in the second slot.
   - *The problem:* the decided default binds player 1 to "the first gamepad", and read literally the second pad does
     nothing.
   - **(A) Every pad drives player 1, with the keyboard and the mouse,** until a game has a second player, whose
     joining is KYR-54's later part. leafwing's default ("input from any connected gamepad will be used") and Godot's
     device `-1`. Two pads pressing one action combine: held if either holds it, the larger value of an axis.
   - **(B) The pad in the lowest slot only,** as FFD and the-mallow-man read "the first mapped pad".
   - **(C) The first pad pressed,** kept until it disconnects.
   - *Recommended:* (A), which changes the decided wording "the first gamepad".

## Decided

Nothing yet.
