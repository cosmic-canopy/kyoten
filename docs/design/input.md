# Input: devices into a game's actions

**Status:** step 8's four questions are decided (2026-11-21), and its first part is built (2026-11-22, below):
`Digital` from a key, a mouse button or a pad's button to a processor, split by time. The second part's three questions
are decided and the part built (2026-11-23, below): every kind but `Text`, delta actions, an entry's parts, a pad read at
its time, the mouse's motion, each player's active scheme, and Output's newest sample. Question 4's lock-in was tried
with two real pads (2026-11-23). The third part, filters, is decided and built (2026-11-23, below): every filter the
peers offer that a device kyoten reads can drive, a default dead zone on every stick and trigger, its values in the
engine's `input` record, and a stick's directions as controls, with a press point and a lower release point. The fourth
part's three questions, gestures, are decided (2026-11-24, below): a `Digital`'s `progress`, a chord's modifiers and a
sequence's steps naming a control or an action, and a chord masking its control's plain binding. What the peers and the
owner's games do is [../research/input.md](../research/input.md).

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
     at the start of the session after. **Tried and kept** (2026-11-23, below): "It sounds like the lock worked from
     what you described."

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

- **2026-11-23, tried: player 1's pad lock with two real pads** (the forty-seventh session's start, the owner's hands-on
  block; `.scratch/s46/locktry/`, its log in `.scratch/s47/locktry.log`). Both pads connected (slots 0 and 1); the
  first pressed, slot 1's, took player 1, and its South drove `faster` held, pressed, then released; while it was locked
  the log shows no change from the other pad; unplugged, the lock let go ("no pad"); the other pad's next button took
  it. That pad's press left `faster` off: it was a Switch-style pad, whose A is East by place, a button `faster` is not
  bound to (South or RightShoulder). The owner, asked at the session's end: "it was a switch style controller. It
  sounds like the lock worked from what you described." Question 4 is kept as decided, no longer "so far".

- **2026-11-23, built: step 8's second part** (the forty-seventh session), in four commits on kyoten's pin,
  `0.9.1027+g25d97c29`, each gated by `tools/test.sh`, on `@kama/window`'s WIN-28 (kama-window `54184ab`).
  1. **Every action kind but `Text`, and the delta** (kyoten `2a8078b`): the frame tier's `ActionList`, a game's actions
     by kind, and `Pose`; `Handoff` and `PlayerActions` hold every kind, a state as of a run's last step and a delta
     summed over its window; the tool reads every kind but `Text` and the action record's `delta`; the generator writes
     each kind's field, its view and the world's `actions()`.
  2. **The binder's devices** (kyoten `b81d9ad`): an object entry's parts, a pad's travel and axes read at `padAt`,
     the mouse's motion, up positive, a state's most actuated entry and a delta's sum, a held control counting the
     step's seconds in a delta.
  3. **The active scheme** (kyoten `e301223`): `Scheme` in each step's hand-off, the binder's rule, a processor
     record's `scheme`, refused outside Input and Output and on a processor reading no `Actions`, and the generated
     gate.
  4. **Output's newest sample** (kyoten `7258551`): `InputSource.newest(seconds:)` and `World.output(time:,
     newest:)`; Output reads each value as of the newest sample and each delta since its last frame, a digital's edges
     by steps; in a frame that owes no step the samples are applied early and still land in the next step.
  - **Settled by the decided rules, for the owner to object to:**
    - a `Vector2` or `Vector3` action needs `std::math` in the game's `generated` module's `importsOnly` (kama has no
      re-export), and the tool refuses it naming the line to add;
    - the record keeps the widest window a processor reading actions runs over, and at least a frame's most steps; a
      wider window sums the newest steps kept;
    - the mouse's motion is kyoten's own names, `Motion`, `MotionX`, `MotionY`; scroll waits, since lines and pixels
      do not convert;
    - a part on several controls reads the most actuated, and a state its most actuated entry (Unity's default, Godot's
      strongest); keys make a direction no longer than 1 (Unity's DigitalNormalized, Godot's `get_vector`); a delta sums
      its entries, a held control counting the base step's seconds in a step and the frame's for Output; the mouse's
      motion bound to a state, mixed with controls held, or as a key's part is refused; a stick stays raw until filters;
    - a pad's travel and axes are samples apart from its buttons' edges, which stay the events', so a press and its
      release between two pumps are both kept; neither takes the lock;
    - the scheme's rule: a key, a mouse button or the mouse moved is `KeyboardMouse`; the locked pad's button, a trigger
      past `PressedAt` or a stick past half its travel is `Gamepad`; the locked pad gone, `KeyboardMouse`; a row naming
      no player runs no gated processor;
    - Output's `Digital` stays by steps, so its `held` and its edges agree;
    - `Pose` is bound by nothing until XR (KYR-34).
  - **Counts:** the engine's tests 478 cases (334 at the session's start), the tool's 247 (234), natively and on
    wasm, debug and release; fps and vr as before. `@kama/window` 334, 221 under node, 341 in Edge and Firefox, 352
    through the driver (313, 204, 318 and 329), with WIN-28.
  - **Mutations:** 99 of 101 caught, the other two shown equivalent (kyoten's `.scratch/s47/mutate_c1.py` to
    `mutate_c4.py`): commit 1, 25 of 26 on the engine and 7 of 8 on the tool (a delta's window clamped to the steps kept
    only shortens the loop, since a slot counts only while it holds the step asked for; the schedule gives every Output
    processor rate 0, so the window's check of its phase only restates it); commit 2, 37 of 37; commit 3, 14 of 14 and
    5 of 5; commit 4, 9 of 9 and 2 of 2. Three test lists were sharpened by mutations first: counts that differ between
    kinds, a 10 Hz run whose window is wider than a frame's, and schemes held for unequal steps. WIN-28, 9 of 9.

- **2026-11-23, the owner, the third part's two questions** (filters), laid out from the code (the binder, the bindings
  record, the samples, `@kama/window`'s pads and pointer) and from what the peers and the owner's games do
  ([../research/input.md](../research/input.md) § Filters), and asked in full at the forty-eighth session's start:
  1. **(A): a stick or a trigger with no dead zone written gets one, its values in the engine's `input` record.**
     - *The problem:* `"move": { "gamepad": { "x": "LeftX", "y": "LeftY" } }` on a worn pad resting at (0.06, -0.04)
       hands `move` a small value every step; the character creeps, and a processor never sees zero.
     - **Every stick an entry reads gets a scaled dead zone,** radial where the entry reads both axes of one stick,
       per axis where it reads one, and **every trigger's travel one too.** An entry's own `deadZone` filter replaces
       it for that entry, and `{ "deadZone": 0 }` reads the stick raw.
     - **The values are content:** a new engine record, `input`, in `engine/content/`, which a game's content lays its
       own over field by field as it does `app`, and a player's layer later (the-mallow-man's dead zone slider, one
       value for every action). Sticks from 0.125 to 0.925, Unity's, the one engine default on every stick, its upper
       end taking in a stick that never reaches 1; triggers from 30/255, `@kama/window`'s press point, so a trigger's
       value starts where its button presses.
     - *Set aside:* (B) raw unless written (Unreal's and leafwing's opt-in modifiers), where a game that forgets one
       drifts.
  2. **(A): a stick's directions are controls, and a value made a button has a press point and a lower release
     point.**
     - *The problem:* `"menuUp": { "keyboard": "ArrowUp", "gamepad": "DpadUp" }` cannot add the stick, since a
       `Digital` takes a pad button's name alone; and one point both ways chatters, a thumb resting near it pressing
       and releasing on each reading.
     - **Eight names:** `LeftStickUp`, `LeftStickDown`, `LeftStickLeft`, `LeftStickRight` and the right stick's four
       (Unreal's names, Unity's synthetic controls), kyoten's own as the mouse's `Motion` is, each its axis's half
       toward it, 0 to 1, after the stick's dead zone, usable wherever a control is: a `Digital`, an `Analog`'s part, a
       `Vector2`'s or `Vector3`'s key-style part. `"gamepad": ["DpadUp", "LeftStickUp"]`.
     - **Hysteresis wherever the binder makes a button from a value:** it presses at one point and lets go at a lower
       one, a stick's direction at 0.5 and 0.375 by default (Unity's, its release three quarters of its press), in
       the `input` record, and per entry by `{ "threshold": { "press": 0.6, "release": 0.4 } }`, a bare number
       releasing at three quarters of it. The-mallow-man's menus press at 0.55 and let go below 0.35.
     - **A trigger bound to a `Digital` with no threshold keeps `@kama/window`'s events,** at 30/255 both ways as now,
       so a press and its release between two readings are both kept.
     - *Set aside:* (B) the names with one point both ways (Godot, Unreal, leafwing), which chatters at it; (C) no
       names, an object entry reading an axis and a sign (Godot's shape), whose sign is easy to get wrong with Y turned
       over and which cannot be an `Analog`'s part.

  **The third part, laid out, settled by the decided rules, for the owner to object to:**
  - **Filters are a list on a device's entry, applied in the order written** (Unity's, Unreal's and leafwing's lists),
    after the entry's parts make its value and before a delta's seconds. Each is an object of one key, its value a
    number or an object of parameters. The decided example's `radialDeadZone` is written `deadZone` with a `shape`.
  - **Built:** every filter the peers offer that a device kyoten reads can drive: `deadZone` (`lower`, `upper`; `shape`
    radial or axial; `scaled`, false for Unreal's UnscaledRadial and leafwing's exclusion), `scale` (one factor, or
    per axis), `invert` (every axis, or those named), `curve` (an exponent per axis, `sign(v)·|v|^e`, Unreal's and
    the-mallow-man's; or `points`, piecewise linear, Unreal's user curve), `clamp`, `remap` (a range onto another:
    Unity's Normalize, and the owner's "a `Digital` as a float from X to Y"), `normalize` (unit length), `digital`
    (leafwing's: each axis to -1, 0 or 1), `smooth` (Unreal's Smooth, by a time in seconds, the steps' state and
    Output's kept apart) and `threshold` (question 2).
  - **Not built, by reason:** Unreal's SwizzleAxis and ToWorldSpace (an entry's parts already name any axis for x, y or
    z); ScaleByDeltaTime (a delta does it); FOVScaling (it reads the camera, which only Output can).
  - **On the mouse's motion only `scale`, `invert` and `smooth`:** a dead zone or a curve on a distance moved changes
    with the step's length, so the rest are refused at load, naming why.
  - **Look's units are the game's:** each device's `scale` converts (the-mallow-man's 0.0008 radians per count, 3.2 a
    second at a full push). The mouse moves in raw counts only while its cursor is `Locked`.
  - **A misspelt filter or parameter is refused with every name listed,** in `ControlEntry`'s reader, so at load and
    by the `kyoten` tool at build, which reads content through the engine's `ContentFile`.
  - **Later parts, each asked when it comes:** a player's settings reaching the filters (Lyra's modifiers read the
    player's saved settings; Unity overrides a binding's processors), a game's own filters (every peer has custom
    ones), how a higher layer merges an object entry (replaced whole today), gestures, `Text`, the cursor's position,
    and the game letting go of the lock.

  **Its order, each its own commit:** the value filters; the default dead zones and the `input` record; the stick's
  directions and thresholds.

- **2026-11-23, built: step 8's third part, filters** (the forty-eighth session), in three commits on kyoten's pin,
  `0.9.1027+g25d97c29`, each gated by `tools/test.sh`.
  1. **The value filters** (kyoten `8503d9a`): `ControlEntry` reads an entry's `filters`, each filter's parameters by a
     derived record read strictly, so a misspelt filter, parameter or shape is refused with every name listed and
     where (`filters[0].deadZone.lowr`), at load and by the `kyoten` tool at build; the binder applies them in the order
     written, after the entry's parts and before a delta's seconds, on a step's hand-off and on Output's newest, and
     refuses a value out of its range at load, naming the action.
  2. **The default dead zones and the `input` record** (kyoten `dd8e4dc`): `InputRecord` in
     `engine/content/input.records.json`, sticks from 0.125 to 0.925 and triggers from 30/255, laid over part by part;
     `Binder.make(…, input:)`, holding the record's values to their ranges; the generated `run` passing
     `content.input()`; one input record a content layer.
  3. **A stick's directions and the press points** (kyoten `ba93279`): the eight names; a `Digital`'s object entry, its
     controls under `control` and one `threshold`; a value made a button pressing at one point and letting go at a
     lower one; the record's `stickThreshold`, 0.5 and 0.375.
  - **Settled by the decided rules, for the owner to object to:**
    - each filter acts on the axes its action has, the others held at 0, so a `remap` on a `Vector2` leaves its z at 0;
      a curve's points are level past their ends;
    - `smooth` keeps a state per path, the steps' and Output's, and smooths the mouse's motion as a speed, so how far it
      moves is kept whatever the frame's length; an Output frame of no time passes the motion through;
    - among the buttons' travel the default dead zone is the triggers' alone, as decided; a pair is an entry whose x and
      y read one stick's two axes, either way about, while a stick's directions as x and y each take the default on
      their own axis;
    - a part no `input` layer names takes the filter's own default (a dead zone's upper end 1, radial, scaled; a press
      point 0.5, its release three quarters of it), and a record naming no dead zone reads raw. A `null` removes
      nothing, since the reader cannot tell it from a part left out, so a game turns the stick's default off with
      `{ "lower": 0, "upper": 1 }`, or an entry with its own `deadZone`;
    - a press point is measured after the default dead zone, a stick's direction's and a thresholded trigger's alike,
      as Unity's synthetic stick directions and the-mallow-man's menus measure theirs;
    - a trigger with a threshold reads its travel, so a press and its release between two readings are not seen, where
      the window's events keep them; a trigger with none keeps the events;
    - a `threshold` is refused on a value action's entry, on a key's or a mouse button's, and twice on one entry; a
      stick's direction as a button with no press point anywhere is refused rather than given one the content never
      names.
  - **Counts:** the engine's tests 603 cases (478 at the session's start), the tool's 250 (247), natively and on wasm,
    debug and release; fps and vr as before.
  - **Mutations:** 131 of 133 caught, the other two shown equivalent (kyoten's `.scratch/s48/mutate_c1.py` to
    `mutate_c3.py`):
    - commit 1, 67 of 69. A refused filter's entry kept is equivalent, since any refusal returns the error before the
      binder is used; so is `filters` written as an object passing the binder's own check, since the reader's
      `beginArray` refuses it in the same words at the same place. Two were caught once their cases were sharpened: a
      stick past a dead zone's upper end but short of 1, and a dead zone on a delta's stick, where a scale alone reads
      the same before or after the seconds;
    - commit 2, 23 of 23 on the engine and 3 of 3 on the tool: the generated call, the second record, and commit 1's
      misspelt filter refused at build;
    - commit 3, 38 of 38: two once the right stick's cases pushed the left stick the other way, and one rewritten so
      kama compiles it.

- **2026-11-24, the owner, the fourth part's three questions** (gestures), laid out from the code (the binder, the
  bindings record, the samples, `@kama/window`'s events) and from what the peers and the owner's games do
  ([../research/input.md](../research/input.md) § Gestures), and asked in full at the forty-ninth session's start. Each
  was answered "A (Recommended)".
  1. **(A): a `Digital` carries its gesture's progress, `progress`, from 0 to 1.**
     - *The problem:* `"skip": { "gamepad": { "control": "South", "gestures": [ { "hold": 1.0 } ] } }` skips a
       cutscene on `skip.pressed`, and the cutscene draws a ring filling while South is held. A `Digital` said held,
       pressed and released, and nothing of how far the hold had come.
     - **`progress` is how far the gesture under way has come:**
       - a hold's or a long tap's time, a multi-tap's taps, a sequence's steps;
       - 1 while the action is on, and 0 while it is off.
     - **It is in each step's hand-off, and so in the recorded log:**
       - a replay draws the same ring;
       - a player's longer hold moves the ring with it.
     - Unity's `GetTimeoutCompletionPercentage()` and Unreal's `GetElapsedTime()` are the same idea.
     - *Set aside:*
       - (B) the progress as an `Analog` bound to the same control with the same gesture: two bindings that must agree;
       - (C) none: a game times `held` itself, as the-mallow-man's chores do, and the time then lives in the content
         and the code alike.
  2. **(A): a chord's modifiers and a sequence's steps name a control or another action.**
     - *The problem:* Ctrl+S saves, and LB+South on the pad; the-mallow-man's restart is R while the action SPRINT is
       held (`game/src/roundplay.kama` 706-707). The peers split: Unity, leafwing, Steam and FFD name controls, and
       Unreal's chord and combo name actions.
     - **A control** may be any of the scheme's devices':
       - a mouse entry's chord may name a key (Ctrl+click);
       - kyoten's own `Shift`, `Control`, `Alt` and `Meta` each mean either side;
       - several controls named must all be held.
     - **An action**, `{ "action": "sprint" }`, is held as its own bindings hold it, on any device, so rebinding it
       moves every chord that names it. A cycle of actions naming each other is refused at load.
     - **A sequence's steps** take either form too: `{ "sequence": { "steps": ["DpadDown", "DpadRight"], "within":
       0.25 } }`, followed by the entry's own control.
     - *Set aside:*
       - (B) controls only, where a rebound modifier must be found in every chord;
       - (C) actions only, where every modifier must be declared as an action.
  3. **(A): a chord masks its control's plain binding, by default.**
     - *The problem:* with `save` on Ctrl+S and `moveBack` on S, if `moveBack` sees S, saving nudges the character back.
     - **While a chord's modifiers are held, a press of its control goes to the chord alone.**
       - Every other binding of that control on the scheme that lacks those modifiers sees nothing of it, a value's
         key part included. A sequence's last press is masked alike.
       - FFD's bare D-pad fires only when no bumper or gate is held (`game/src/game.kama` 2928-2934).
       - Unreal's ChordBlocker is "automatically instantiated to block mappings that are masked by a … chord".
       - leafwing's default is `PrioritizeLongest`.
     - **The modifiers are pressed first.** A control already held keeps what it pressed, so S held and then Ctrl
       keeps moving back and saves nothing.
     - **The modifier's own bindings keep firing:** a crouch on Ctrl stays on. This is Steam's rule ("Other bindings
       for the chorded button will continue to fire"), where leafwing's drops them.
     - **`"masks": false`** on a chord lets both fire.
     - *Set aside:*
       - (B) no masking, Unity's default: its input consumption shipped on in 1.4 and was "temporarily moved here as an
         opt-in feature, while it's issues are investigated" (`InputSettings.cs` 781, 1.11.2);
       - (C) masking opt-in.

  **The fourth part, laid out, settled by the decided rules, for the owner to object to:**
  - **Gestures are a list on a device's entry, applied in the order written, after its filters.**
    - Each reads the on and off of the one before it, and the first reads the entry's controls, after any `threshold`.
    - Each is an object of one key, its value a number or an object of parameters.
    - A misspelt gesture or parameter is refused with every name listed, at load and by the `kyoten` tool at build.
    - A number out of its range is refused at load, naming the action.
  - **Built, every gesture the peers offer that a device kyoten reads can drive:**
    - `hold`: on once held for its time, until let go (Unity's Hold, Unreal's Hold, Steam's Long Press);
    - `tap`: a press for one step when let go within its time;
    - `longTap`: a press for one step when let go after its time (Unity's SlowTap, which it shows as "Long Tap";
      Unreal's HoldAndRelease);
    - `multiTap`: `{ "multiTap": 2 }`, or with its `count`, `tap` and `gap`.
      - It is on at the last press and held until let go: Steam's Double Press ("If held on the second press, it will
        remain pressed"), and what Unity's own TODOs ask for ("perform on final press", "stays performed … until the
        button is released").
      - Unity's pulse on the last release is `[multiTap, tap]`.
    - `repeat`: on with its input, then pressed again, with no release, after its `delay` and every `every`, up to an
      optional `limit` (Unreal's Pulse, Steam's Turbo, the-mallow-man's menus);
    - `toggle`: each press of its input turns the action on, and the next turns it off (Steam's Toggle);
    - `delay`: its input's on and off moved later by `start` and `end` (Steam's Fire Start and End Delay);
    - `chord` and `sequence`, by questions 2 and 3. A sequence's steps come in order, each within `within` of the one
      before it, and the entry's own control comes last;
    - `interruptible`, Steam's Interruptable, opt-in: the plain press waits while another action's `hold` or
      `multiTap` on the same control could still fire, and never fires if that one does.
  - **Not built, by reason:**
    - Unity's Press, Unreal's Down, Pressed and Released, and Steam's Start and Release Press: a `Digital` already
      carries `held`, `pressed` and `released`;
    - Unreal's one-shot Hold: a reader reads `pressed`;
    - Steam's Turbo flicker: `repeat` gives the same presses;
    - Steam's Cycle Binding: an entry binds one action;
    - Steam's Haptics: they are output, a later pad row's.
  - **Gestures run in real time,** on the samples' clock, unscaled and unpaused, as Unity's event times and Unreal's
    timed triggers (not dilated by default) do. A deadline lands in the step whose end passes it.
  - **Their default times are in the engine's `input` record,** laid over by a game's layer and later a player's (a
    longer window for a player who needs one). They are Unity's set, as the dead zones were:
    - `hold` 0.4, `tap` 0.2 and `longTap` 0.5;
    - `gap` 0.75, which is also a sequence step's `within`;
    - `repeat` 0.5, then every 0.1.

    The-mallow-man's menus repeat at 0.40 and 0.12.
  - **Gestures leave the pad lock and the scheme alone:** a press takes the lock and sets the scheme, whatever its
    gestures make of it.
  - **On a value action, `chord` alone,** which gates the value while its modifiers are held (a camera orbiting while
    the right mouse button is held, Alt and a drag). The others are refused there, since only a `Digital` has a press.
  - **A modifier or a step that names an action** is evaluated before the actions that name it.

  **Its order, each its own commit:**
  1. gestures on one control and `progress`;
  2. chords and sequences, masking, and a chord on a value action;
  3. `interruptible`.

  **Next, KYR-54's later parts, each asked when it comes:**
  - `Text`;
  - the cursor's position as a control;
  - the game letting go of the lock;
  - a player's settings reaching the filters and gestures (Lyra's settings-driven modifiers, Unity's binding
    overrides);
  - a game's own filters and gestures;
  - how a higher layer merges an object entry.
