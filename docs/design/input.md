# Input: devices into a game's actions

**Status:** step 8's four questions are decided (2026-11-21), and its first part is built (2026-11-22, below):
`Digital` from a key, a mouse button or a pad's button to a processor, split by time. The second part's three questions
are decided (2026-11-23, below): a player's active scheme and delta actions, a `Vector2`'s y up, and a pad reading's
time. Question 4's lock-in was tried with two real pads (2026-11-23). What the peers and the owner's games do is
[../research/input.md](../research/input.md).

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

- **2026-11-21, the owner, step 8's questions, asked in full at the forty-fourth session's readying:**
  1. **(A): `@kama/window` gives each event its time** on kama's monotonic clock, the best its backend has, and kyoten
     splits by it: each owed step takes the events in its window, the frame's last owed step everything up to the pump,
     and a frame that owes none keeps its events for the next step. "A recommended." The package's row is WIN-26, and
     the control names' WIN-25, both built in the forty-fifth session (kama-window `642d116`, `663689e` and `fedfc75`).
  2. **(A): action, then device, a device's entry a control, a list of controls, or an object with its parts, its
     `filters` and its `gestures`.** The owner: "I think A sounds good so far. We need actions to be abstract from the
     control method and we need to be able to specify filters and such." So far: the shape is held to that as step 8
     builds it, and a change the build finds is asked.
  3. **(A): a filter reshapes a value each step, and a gesture recognizes a pattern over time;** a binding lists its
     filters, then its gestures. "Adapter" is retired. The owner: "I'm good with A... I wasn't married to the "adapter"
     term I just needed something to describe it."
  4. **A pad locks in to player 1: the first pad pressed.** Asked twice. First the owner set aside every pad at once:
     "I think we need to try this out. I don't want another pad taking input control accidentally so it seems like you
     need to lock in at some point... or at the least let the game lock in at some point." Asked again with three
     shapes, the owner chose (A), "Yes A sounds good so far":
     - while a pad is locked, another pad does nothing for player 1;
     - the lock lets go when that pad disconnects, and the next pad pressed takes it (WIN-4's decision 4, the console
       pattern);
     - a game may let go of the lock itself (a "press a button to continue" screen), and the next press locks again;
     - the keyboard and the mouse drive player 1 throughout, and a game writes nothing to have this.

     Set aside: (B) every pad until the game locks in, which leaves every pad live in a game that never does; (C) only
     the game letting go, which strands a player whose pad dies. It changes the decided wording "the first gamepad"
     (components § Decided, 2026-11-06). "So far": the owner tries it with two pads once it is built, in a short block
     at the start of the session after.

- **2026-11-22, built: step 8's first part, `Digital` end to end** (the forty-sixth session), in two commits on kyoten's
  pin, `0.9.1027+g25d97c29`, each gated by `tools/test.sh`. The later parts, each its own commit: `Analog`,
  `Vector2` and `Vector3` (`Pose` built, bound by nothing), the object entries' parts and a pad's axes, a mouse's
  motion and Output's newest sample; filters; gestures; `Text`; and the game letting go of the lock, whose API is asked
  when it comes up.
  - **The frame tier** (`kyoten::frame`, fenced): `Digital` moved there from `kyoten::input`, since a game's generated
    `Actions` is fenced and holds one per action; `Sample`, one input from a device (a key by its USB HID usage id, a
    mouse button by the W3C's `button`, a pad's button by the standard gamepad's index, its value and its time on the
    frame timestamp's base, or a pad's connection); `Handoff`, one step's action values for every player in the
    generated order; `PlayerActions`, the world's record of them across steps; `Clock.stepEnd(i:)`, where each owed step
    ends on the timestamps' base, scaled, capped and paused alike; and the `InputSource` contract.
  - **The driver:** `World.input(time:, handoff:)`; `step` handed its hand-off; `frame` hands each owed step the input
    that arrived by its end on the clock and the frame's last owed step everything up to the pump, and a frame that
    owes none asks for none, so it keeps its input for the next step.
  - **The binder** (`kyoten::input`, tier `Module`, outside the fence, naming `kyoten::frame` and `kyoten::records`
    alone of the engine): `Binder.make(players:, digitalActions:, bindings:)` reads each device's entry (a control's
    name or a list of them) by `@kama/window`'s own reader, so a misspelling is refused at load with every name listed,
    and refuses a binding naming no action and an object entry until its part, every refusal at once.
  - **Settled by the decided rules, for the owner to object to:**
    - one action on several controls is held while any is, its edges on the combined state, so a key's repeat or a
      second key presses nothing;
    - a press and its release inside one step show the press, held, that step and the release the next; a release and
      a press inside one step show both, held;
    - each processor sees an edge once, on its first run at or after the step it lands in, whatever its rate: the
      passes write each row's `Actions` from its player's record before each processor that reads them, a processor
      at a rate seeing every step since its last run and Output every step since its last frame;
    - a control is on at `@kama/window`'s `Gamepad::PressedAt` of its travel, for every device;
    - **a pad takes player 1's lock with a button pressed, never a stick alone**, any button, bound or not, so a
      drifting or knocked stick cannot take player 1; the lock goes when that pad disconnects, what it held released at
      that moment, and the next pad pressed takes it;
    - an entity naming no player (0) or a player past the world's sees every action off;
    - under `--fixed-fps`, whose timestamps are made up, a tick's samples are taken at its own timestamp, so they land
      in its last owed step.
  - **The bindings across layers:** each content layer's binding of an action replaces each device's entry it names
    and keeps the others, as a record merges (`BindingRecord.takeEntriesFrom`); one layer binding an action in two
    files is refused, naming both.
  - **The platform:** `Platform.pumped(into:)` hands in the window's input as samples; the open platforms make them
    from `@kama/window`'s events (`pumpInto`), each at its event's time on `now()`'s base, a key's repeat and a touch or
    pen contact none (touch is WIN-11's); the loop (`Play<W, P, S>`) hands its source each tick's samples, and
    `play(world:, platform:, input:, …)` takes the source.
  - **The generator:** `Actions` imports `Digital` from `kyoten::frame` and gains `viewFrom`, the generator's own; the
    world holds `players` (1, the engine's default), `digitalActions` and the players' record, which `pass_input` takes
    each step's hand-off into; the generated `run` builds the binder from the merged bindings, a refusal printed and
    the run ending with 1. The `spin` fixture's own `main` drives two cubes by hand, one naming no player and one
    player 1, whose `faster` each step's hand-off holds.
  - **Found by the spin fixture's 30 Hz `tally`, and fixed in the first commit:** `PlayerActions` held "no edge yet"
    as step -1, which a slower run's first window (the steps after -2 up to 0) contains, so it saw a press that never
    was; "no edge" is int64's least value.
  - **Counts:** the engine's tests 334 cases (218 at the session's start), the tool's 234 (229), natively and on wasm,
    debug and release; fps and vr on the engine as before.
  - **Mutations:** 40 of 40 on the first commit (`Handoff`, `PlayerActions` and its sentinel, the step ends, the
    binder, the entry reader), 2 caught by the out-of-bounds trap their guards prevent; 24 of 24 on the second (the
    driver, the loop, the open platforms' pump, the bindings across layers, the generator's hand-off, views and
    windows, and the run's binder: that last one rewritten so the game it generates compiles, since its first form's
    did not and so proved nothing).

- **2026-11-23, the owner, the second part's three questions,** laid out from the code (the binder, the samples, the
  hand-off, the generator and `@kama/window`'s pads) and asked in full at the forty-seventh session's start:
  1. **How a game takes devices that mean different things: (A), each player's active scheme, and `delta` where the
     binder can convert.**
     - **Asked first as "look" on the mouse and a stick:** the mouse's motion is a distance moved and the stick's value
       a position held, so `yaw += look.x * speed` turns differently on each.
     - **The owner asked back with FFD's aim**, where the mouse's position is an aim point and the stick a direction
       held: "It seems like the game may need to be able to switch control schema based on input device type?
       relative vs absolute etc?" FFD does so in `game/src/game.kama`'s `buildLocalFrame` with a device latch,
       `padIsSpeaking`, added after a play session found "the facing of the player would change when I let go of the
       stick".
     - **Asked again, the owner chose (A) in this shape:** "Basically what I figure we should do is have the input type
       part of the binding as well and that "input" phase logic can be activated based on input type. So logic can be
       different based on mouse vs game pad. I assume the abstraction can stop at input phase? the update phase
       shouldn't need to know what input phase is abstracting?"
     - **A scheme is a binding's device kind:** the keyboard's and the mouse's entries are `KeyboardMouse`, a pad's
       `Gamepad`; touch and XR add theirs when they come.
     - **Each player has an active scheme,** that of the device that last drove them, a stick counting only past a
       threshold, so drift cannot switch it. Each step's hand-off carries it, so a replay runs the same logic.
     - **An Input-phase processor may name a scheme** in its record (`"scheme": "Gamepad"`), and runs only over the rows
       whose player's active scheme it is. It turns the device-shaped actions into the game's own components (an aim
       direction), which Update reads.
     - **The scheme is no value a processor reads,** and the tool refuses one on an Update or Constraints processor, so
       the abstraction stops at Input, as the owner asked. An Output processor may name one, for a prompt (settled, to
       report).
     - **An action's record may say `"delta": true`** where the binder can convert one device's input into another's
       units. Its value is a distance moved: each step the motion that landed in it, and a slower run or Output
       everything since its last. A stick or keys bound to it count their value times the step's seconds, and the
       mouse's motion bound to an action that is no delta is refused at load. So look is one action, and a processor
       writes `yaw += look.x` on every device.
     - **Left for its own part, and asked there:** the cursor's position as a control. FFD turns it into a world point
       against the camera the player sees, smoothed in presentation, which an Input-phase processor inside the
       simulation cannot read.
     - **Set aside:** (B) one action whose value names its source's mode, so every reader must handle every mode; (C)
       separate actions with no scheme, the game guessing the device from which moved, which is FFD's first form and its
       facing bug.
     - **What the peers have, checked 2026-11-23:**
       - Unity's `PlayerInput` matches bindings to control schemes, names the "currently active control scheme"
         (`currentControlScheme`), raises an event "when the controls used by the player change", and switches scheme
         by itself while one player plays (`neverAutoSwitchControlSchemes`, false by default, turned off with more than
         one) ([PlayerInput](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/PlayerInput.html));
       - Steam Input tags an analog action's data with `eMode`, "the type of data coming from this action", the mode its
         configuration gave it ([ISteamInput](https://partner.steamgames.com/doc/api/ISteamInput));
       - Unreal's Common Input Subsystem has an `OnInputMethodChanged` delegate (Lyra's
         [input settings](https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine)).
  2. **(A): a `Vector2`'s y is up, on every device.** The `up` part gives +1. A stick's Y, which the W3C's standard
     gamepad reports "negative up/positive down" ([remapping](https://w3c.github.io/gamepad/#remapping)), is turned over
     wherever it is bound. The mouse moving up the screen gives +1. XInput's sticks are up positive ("Positive values
     signify up or to the right", `XINPUT_GAMEPAD`), and kyoten's world is Y up. A player's inverted look is an `invert`
     filter. The owner: "I think A is probably best?"
  3. **(A): `@kama/window` gives a pad's reading its time, `padAt(slot:)`,** the time its button events carry (its
     WIN-28), and kyoten makes each stick's and trigger's sample at it. So a button and a stick from one reading land in
     one step, as question 1 decided. The owner: "I assume option 1 is the production answer?" It is; kyoten stamping
     the sticks at the pump was the stopgap. Natively a reading's time stays the pump's until WIN-19.

  **The second part, laid out, each its own commit:**
  1. the kinds and the hand-off (`Analog`, `Vector2`, `Vector3`, `Pose` bound by nothing, and `delta`);
  2. the binder's devices: an object entry's parts, a pad's axes and triggers, the mouse's motion;
  3. the active scheme;
  4. Output's newest sample.

  Then filters, gestures, `Text`, the cursor's position, and the game letting go of the lock.
