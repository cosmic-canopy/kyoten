# Input: devices into a game's actions

**Status:** step 8's four questions are decided (2026-11-21), and its first part is built (2026-11-22, below):
`Digital` from a key, a mouse button or a pad's button to a processor, split by time. The second part's three questions
are decided and the part built (2026-11-23, below): every kind but `Text`, delta actions, an entry's parts, a pad read at
its time, the mouse's motion, each player's active scheme, and Output's newest sample. Question 4's lock-in was tried
with two real pads (2026-11-23). The third part, filters, is decided and built (2026-11-23, below): every filter the
peers offer that a device kyoten reads can drive, a default dead zone on every stick and trigger, its values in the
engine's `input` record, and a stick's directions as controls, with a press point and a lower release point. The fourth
part's three questions, gestures, are decided and the part built (2026-11-24, below): a `Digital`'s `progress`, a chord's
modifiers and a sequence's steps naming a control or an action, a chord masking its control's plain binding, and every
gesture the peers offer that a device kyoten reads can drive. The fifth part's four
questions, `Text`, are decided and the part built (2026-11-25, below):
- a `Text` action holds the text that entered;
- it is collected only while the game turns a player's text entry on, through Output's own `TextEntry`, which the
  world gathers after Output into `Requests`;
- the keyboard's other bindings are masked meanwhile, except the entries marked `"typing": true`;
- a held erase repeats at the player's own rate, `{ "repeat": { "system": true } }`.

The sixth part's four questions, the cursor, its views and devices letting go, are decided (2026-11-26, below):
- the engine turns the cursor through the view a binding names, each view writing its own `DrawnView`: a `Pose` the ray in
  the world, a `Vector2` the place in the view's own units;
- the game asks for the cursor's mode through Output's own `Cursor`, and the engine asks again while it still asks
  `Locked`;
- the game lets go of the pad lock through Output's own `PadLock`;
- a device letting go presses whatever action a binding names `"Lost"` or `"Unlocked"` on.

Its first three commits are built (2026-11-26, below): a `Pose` with its zone; the views, each its own `DrawnView`, a
game's declared `Views` and `Requests`' views; and the cursor through a view on a `Vector2` and a `Pose`.

What the peers and the owner's games do is [../research/input.md](../research/input.md).

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


- **2026-11-24, built: step 8's fourth part, gestures** (the forty-ninth session), in three commits on kyoten's pin,
  `0.9.1027+g25d97c29`, each gated by `tools/test.sh`.
  1. **Gestures on one control and `progress`** (kyoten `25c8a5b`):
     - a `Digital` entry's `hold`, `tap`, `longTap`, `multiTap`, `repeat`, `toggle` and `delay`, run in real time on the
       samples' clock;
     - the `input` record's `gestures` times, laid over part by part;
     - `Digital.progress`, through the hand-off, `PlayerActions` and the generated views.
  2. **Chords and sequences, masking, and a chord on a value action** (kyoten `664a965`).
  3. **`interruptible`** (kyoten `39e9236`).
  - **Found on the way, and changed test first in commit 1:** the driver handed the frame's last owed step `until` =
    int64's most ("everything"), which would have fired every gesture's deadline at once. It hands `now`, the pump's
    time, which every sample is at or before, since the loop reads it after the pump. So the decided "everything up to
    the pump" holds.
  - **A correction to what question 1 said it costs:** `Digital` is 8 bytes, where it was 3, since its three flags and
    a `float32` align to 4. The question said 4 bytes more.
  - **Settled by the decided rules, for the owner to object to:**
    - **A gesture reads the on and off of the one before it.** A `repeat`'s press again (no release between) counts
      as a press for a gesture that counts presses (a `toggle`, a `multiTap`), and passes through the others while
      they are on.
    - **`multiTap`:**
      - each tap is let go within its `tap` time;
      - the next press comes within its `gap`, both inclusive;
      - its last press may be held, and it lets go with it;
      - its progress is the presses counted of its count.
    - **`repeat` presses at most once in a long step, and never catches up.** After a step that passed several of its
      times, the next press is an interval after that step's end, as the-mallow-man's menus and Unity's UI do ("at
      most one press a frame"). A `limit` counts its first press.
    - **`delay`:**
      - one number moves the on and the off alike;
      - an off moved by less than its on comes at once after it, so a short tap stays a press for one step;
      - changes are kept in the order they came.
    - **`tap`, `longTap` and `hold` are inclusive at their time:** a release at exactly a tap's time is a tap, and a
      hold presses at exactly its time.
    - **Times are read in seconds and kept as nanoseconds, rounded to the nearest,** which shows only past nine
      decimals: 0.9999999996 seconds is 1,000,000,000.
    - **Every time is above 0 and at most 9,000,000,000 seconds,** about 285 years, which the clock counts; a `delay`'s
      may be 0.
    - **A chord turns on only when its control presses while every modifier is already held.**
      - A modifier pressed in the same instant counts.
      - An action a chord holds is settled before the actions that hold it, so one press of a key both read presses
        both.
    - **A sequence:**
      - a step out of order is passed over;
      - its first step pressed again starts it again;
      - one press moves it once, so `["Space"]` on Space is a double press;
      - the press that ends it starts no new one;
      - its progress is the steps come of its steps and its control.
    - **Masking is on a press's edge:** a key, a mouse button and a pad's button by its events. A pad control read by
      its travel, or a stick's direction, is not masked. A press masked stays masked until it lets go, though the
      chord lets go first.
    - **A value's chord gates a state as of each step's end,** and the mouse's motion as it moves, so the motion while
      the modifier was held counts after it lets go. It asks no "modifier first" of a value.
    - **`interruptible`:**
      - a hold's rival is open while its control is held;
      - a multi-tap's is open while it counts taps, so a press held past its tap time comes at once, held;
      - a rival is every `hold` and `multiTap` of another action's entry reading a control its own reads;
      - with none, it presses at once.
    - **Gestures do not change how the pad lock or the scheme reads a press.** A pad's press under a hold takes the lock
      and sets the scheme at once.
  - **Counts:**
    - the engine's tests went from 603 cases at the session's start to 814, natively and on wasm, debug and release;
    - the tool's went from 250 to 253;
    - fps and vr on the engine as before.
  - **Mutations:** 142 of 144 caught, the other two shown equivalent (kyoten's `.scratch/s49/mutate_c1.py` to
    `mutate_c3.py`).
    - **Commit 1, 75 of 77.**
      - Two more mutations hit code the batch showed dead, and that code went: a deadline finding its hold let go (a
        hold let go has no deadline), and an entry that is on reading 1 (its action is held, which reads 1 already).
      - Five were caught once their cases were sharpened: a hold's deadline kept past its release, the repeat's long
        step moved off its grid, a delay's start and end set apart, a delay before a double tap, and a time below a
        nanosecond. The first rounding case, 0.3 seconds, proved nothing: 0.3 × 1e9 is exactly 300,000,000 in doubles.
      - Two are equivalent:
        - deadlines at one instant firing in either order land in one step, where a press again inside a press's step
          is the same press;
        - gestures written as an object are refused by the reader's own `beginArray` in the same words at the same
          place, as the filters' were.
    - **Commit 2, 51 of 51.**
      - One was caught once a case held a chord on an action whose own chord lets go, which takes a second look.
      - Two were rewritten so kama compiles them: a dangling `else`, and a string moved on one path alone.
      - Three cases were added while the batch was planned: a step raised by a deadline, the order of a chord on an
        action reading the same key, and a sequence written `"masks": false`.
    - **Commit 3, 16 of 16.**
      - Two were caught once their cases were sharpened: its own entry's hold before it, and a decision looked at again
        in the same pass.
      - One was rewritten to compile, then caught once a case held a hold under way on another key.

  **Next, KYR-54's later parts, each asked when it comes:**
  - `Text`;
  - the cursor's position as a control;
  - the game letting go of the lock;
  - a player's settings reaching the filters and gestures;
  - a game's own filters and gestures;
  - how a higher layer merges an object entry.

- **2026-11-25, the owner, the fifth part's four questions** (`Text`), laid out from the code (the platform's pump, the
  binder, the tool's refusal, Output's write rule) and from what the peers and the owner's games do
  ([../research/input.md](../research/input.md) § Typed text), and asked in full at the fiftieth session's start. Each
  was answered "A (Recommended)".
  1. **(A): a `Text` action holds the text that entered in a run's window, as code points.**
     - *The problem:* a chat box, a typing game that scores each letter as it lands, a name on a high-score table. The
       tool refused a `Text` action, and the platform's pump dropped typed text.
     - **What entered:**
       - what a key typed, after the layout, Shift and dead keys;
       - an IME's committed word;
       - an on-screen keyboard's keys.

       It never holds a composition under way, and never an editing key.
     - **Editing keys are `Digital` actions:** erase on Backspace, submit on Enter, cancel on Escape. A processor adds
       what entered to the line it keeps: `input.chat.appendTo(text: ref line)`.
     - **Each processor sees each code point once,** on its first run at or after the step it lands in, as an edge.
     - SDL3, Unity, Godot and Bevy hand text so, and their editing keys are keys.
     - *Set aside:* (B) a finished line, which the binder edits and hands whole on Enter, as the-mallow-man sends chat.
       - It is a text field inside the input layer. A caret, a selection, an IME and a paste are a UI field's: RmlUi's
         natively, the page's own on the web.
       - A typing game could not score letters as they land.
       - How a UI field's line reaches the game is KYR-16's to design.
  2. **(A): typed text is collected only while the game turns the player's text entry on.**
     - *The problem:*
       - an IME left on in play swallows keys as it composes (winit: "during the preedit phase the window will NOT get
         [`KeyboardInput`] events"), so WASD stops;
       - on a Steam Deck with no keyboard, the player opens chat and has nothing to type with.
     - **Off, the `Text` action gets nothing.** On, the platform also turns on the window's text input: the IME, and an
       on-screen keyboard where no physical one is. Three sources agree:
       - SDL3's model, "Text input events are not received by default";
       - winit's IME, off by default, "useful for games";
       - Valve's Deck Verified, games must "automatically display an on-screen keyboard when requiring the user to input
         text".
     - **The window's half is `@kama/window`'s,** its WIN-5 widened to text input on and off. Until it is built, the
       window delivers text as now and only kyoten's gate applies, a stopgap named.
     - *Set aside:* (B) always collected (Unity, Godot), where no on-screen keyboard ever rises, and the IME is always on
       or never.
  3. **(A): the game turns text entry on through Output's own state.** This is an engine component, `TextEntry`, marked
     `"output": true`, which the platform reads after each frame.
     - *The problem:* the player presses T and the chat field opens. Nothing carried a request from a game back to the
       binder or the platform, and an Output processor could write nothing.
     - **An Output processor writes it:**
       - a UI field when it takes focus;
       - or the game's own Output processor, reading its simulation's state (entering a name).

       Bevy's text widget sets `Window.ime_enabled` on focus.
     - **Output's own state is built first,** as decided (web-and-native § Decided, question 3; REFERENCE: "its own
       state marked `"output": true`").
     - **The same path will carry** the game letting go of the pad lock, the cursor's mode and rumble, each asked when it
       comes.
     - *Set aside:*
       - (B) simulation state written in Update. A field's focus is UI-only state, which the decided rule keeps in Output,
         and it would round-trip through the simulation. Where the field sits on screen is Output's alone to know.
       - (C) a handle handed to Output processors (SDL's `SDL_StartTextInput` call), the first service a processor would
         be handed.
  4. **(A): while a player's text entry is on, their keyboard drives only their `Text` actions and the entries marked
     `"typing": true`.**
     - *The problem:* with `faster` on `KeyW`, a player who opens chat and types "wow" presses `faster` twice.
     - **An entry marked to type:** `"submit": { "keyboard": { "control": "Enter", "typing": true } }`.
     - **Turning entry on lets go of every masked keyboard action held,** as a focus change does, so a held W does not
       stick. The mouse and the pads are unchanged.
     - Unreal's UIOnly input mode is the same idea, and the-mallow-man steps its round with an idle input while a field
       is open. It is the first input context, which KYR-54's contexts later take in.
     - *Set aside:* (B) nothing masked, each game gating its own processors. That is the peers' default:
       - Unity's UI "will not consume input";
       - Godot sets an action's state before its GUI sees the key;
       - Bevy and leafwing read held keys whatever has focus.

       Every game would carry the "wow" bug until it handles it.

  **The fifth part, laid out, settled by the decided rules, for the owner to object to:**
  - **Code points,** as `@kama/window`'s `Text`, Unity's and Godot's are. A `Text` holds up to 64, about 260 bytes per
    `Text` action in each `Actions` row.
  - **No window overflows and nothing is lost:**
    - each step holds at most 64 divided by the steps the world keeps (at least a frame's most, 5);
    - the binder carries the rest, in order, to the steps after;
    - a paste of 500 code points lands within a second at 60 Hz.
  - **`"Text"` is kyoten's own control name,** as the mouse's `Motion` is: `"chat": { "keyboard": "Text" }`.
    - A `Text` action takes no other control, filter or gesture.
    - No other kind of action takes `"Text"`.
    - Each is refused at load, naming why.
  - **Text that arrives before the entry turned on is dropped,** so the T that opens the chat is not typed into it.
  - **A held erase repeats at the player's own rate.**
    - The pump hands the operating system's key repeats on, and `{ "repeat": { "system": true } }` presses again on
      each of them, as RmlUi's, Godot's and Bevy's fields take them.
    - The player's repeat rate is an accessibility setting.
    - A pad's button has no system repeat, so `system` is refused there.
  - **A composition under way is never in an action;** it is presentation's (WIN-5).
  - **Output sees the text since its last frame,** by steps, as a `Digital`'s edges.
  - **A replay keeps the hand-off as it is,** the text included.
  - **`TextEntry` is `{ player, on }` for now.** Its purpose (text, a number, an email, a password), its longest length,
    its lines and the field's box arrive with WIN-5, when a platform can use them.
  - **Output's own state, as decided:**
    - a component record says `"output": true`;
    - only an Output processor takes `ref` of one, and an Output processor takes `ref` of nothing else;
    - an Input, Update or Constraints processor reads none, refused naming why, since it changes with the frame rate;
    - it is never saved or hashed.

  **Its order, each its own commit:**
  1. Output's own state, and the engine's first component, `TextEntry`;
  2. the `Text` kind end to end, collected while text entry is on;
  3. typing masks the keyboard;
  4. the system's key repeat.

- **2026-11-25, built: step 8's fifth part, `Text`** (the fiftieth session), in four commits and two of what their
  mutations found, on kyoten's pin, `0.9.1027+g25d97c29`, each gated by `tools/test.sh`.
  1. **Output's own state, and the engine's first component, `TextEntry`** (kyoten `f9b1257`):
     - a component record's `"output": true` (`ComponentRecord.output()`), never saved, whatever its record says of
       `saved`;
     - only an Output processor takes `ref` of one, and an Output processor takes `ref` of nothing else; an Input,
       Update or Constraints processor taking one, `ref` or `const ref`, is refused, naming why;
     - `kyoten::frame::TextEntry { player, on }`, its record in the frame tier's records file;
     - the tool reads each dependency's records files for their component records, as it reads the game's: the
       engine's `TextEntry`, a dependency's requirements and world components; a dependency whose `kama.json` cannot
       be read, or whose records file does not read, is refused from the records alone, naming it.
  2. **The `Text` kind end to end, collected while text entry is on** (kyoten `3a3a02e`):
     - `kyoten::frame::Text`, up to 64 code points: `length()`, `at(index:)`, `chars()` to `foreach` over, and
       `appendTo(text:)`;
     - `SampleKind::Text`, the pump's `Event::Text` a sample at its time;
     - `ActionList.addText`, and `Handoff` and `PlayerActions` holding each step's text, a run's view joining its
       window's steps, oldest first; `PlayerActions::keptFor(window:)`;
     - the binder: `"keyboard": "Text"`, and every other device, control, filter and gesture on a `Text` action refused,
       as `Text` on any other kind is; player 1's text taken from the moment the entry turned on and dropped while it is
       off; a step handing no more than keeps every run of the steps kept within 64, the rest after it, in order;
     - `kyoten::frame::Requests`, `World.requests(into:)` after Output, `InputSource.textEntry(player:, on:, at:)` and
       `Platform.textEntry(player:, on:)`, which `Play` hands each change to at its frame's timestamp; the open
       platforms' a stopgap until `@kama/window`'s WIN-5;
     - the generator: the field and its two views, the world's `window` and `requests`, `pass_requests` over every
       family holding a `TextEntry`, and the binder made with the world's window.
  3. **Typing holds the keyboard back** (kyoten `92cc831`): an entry's `"typing": true`; while player 1's entry is on, a
     key drives only their `Text` actions and the entries marked so, a value's keys included, and the mouse and the
     pads drive as ever; turning it on lets go of every other key held, a marked key and a pad held then staying held;
     one held through it waits for its next press; a mouse's or a pad's entry marked `typing` refused.
  4. **The system's key repeat** (kyoten `12f7f01`): the pump hands a key's operating-system repeat on as `SampleKind::Repeat`,
     and `{ "repeat": { "system": true } }` presses again on each, held back while the player types like any key, and
     ignored by a timed `repeat`; with a `delay`, an `every` or a `limit` of its own, or on a pad or the mouse, it is
     refused.

  What the mutations found, each its own commit: a dependency's records file that does not read, and a redundant
  check on a text binding's object, removed (kyoten `43a690c`); spin's `tally` counting `note`, so a step's view of the
  wrong text action shows (kyoten `1bbfc7f`).
  - **Settled while building, for the owner to object to:**
    - **The requests' path is `Requests`,** gathered by the world after Output (`World.requests(into:)`) and handed on
      by `Play` as it changes: one contract call, where each later request (the lock's let-go, the cursor's mode,
      rumble) adds a field.
    - **A burst is spread by a sliding window:** a step hands at most 64 less what the steps kept before it handed, so
      an IME's word lands at once, and a paste of 100 code points comes in two steps, the second after the steps kept.
    - **A sample at the very moment the entry turns on is taken, and one at the moment it turns off is not:** the entry
      holds from its moment on.
    - **A dependency's component records are read** wherever the game's are (its world components, its requirements,
      Output's own state); its processors, groups and actions stay its own.
    - **The engine declares its first component of its own,** in the frame tier, read by the tool from the engine's
      records file as a dependency's.
  - **Counts:** the engine's tests 894 cases (814 at the session's start), the tool's 272 (253), natively and on
    wasm, debug and release; fps and vr as before.
  - **Mutations:** 88 of 92 caught, two shown equivalent, two dead checks removed (kyoten's `.scratch/s50/mutate_c1.py`,
    `mutate_c2.py`, `mutate_c34.py`):
    - **Commit 1, 17 of 17:** 5 on the engine and 12 on the tool. One was rewritten to compile (code after a bare
      `continue`), and one caught once its case was added (a dependency's records file that does not read).
    - **Commit 2, 44 of 46:**
      - one equivalent: a text sample taken with no text action bound reaches nothing, since every step drains the
        queue and hands to bound actions alone;
      - one showed the object check on a text binding redundant, since an object has no names, so it was removed;
      - one rewritten to compile (a smaller `Text` needs its `chars()` too);
      - two caught once their cases were sharpened: a text of one code point is not empty, and spin's `tally` reading
        `note`;
      - three while the batch was planned: a sample at the very moment the entry turns on and off, a second text
        action in spin, and the generated `run`'s binder window, read from its code since a headless run cannot show
        it.
    - **Commit 3, 16 of 17:**
      - one equivalent: letting keys go when the entry turns off too, since while it is on no unmarked key is on;
      - one caught once a case held a pad when the entry turns on;
      - three cases added while it was planned: `typing` twice, a marked key held across, a marked value's keys.
    - **Commit 4, 11 of 12:**
      - one showed a check dead, a key's kind in `entryReads`, since a key is always an edge's, so it was removed;
      - three caught once their cases were added: a timed `repeat` ignoring the system's repeats, and a system repeat
        chained into a `toggle`, after its release and under a chord on the toggled action.

  **Next, KYR-54's later parts, each asked when it comes:**
  - the cursor's position as a control;
  - the game letting go of the lock, through `Requests`;
  - `@kama/window`'s WIN-5, so the window's text input turns on and off, with the IME and an on-screen keyboard;
  - a player's settings reaching the filters and gestures;
  - a game's own filters and gestures;
  - how a higher layer merges an object entry.

- **2026-11-26, the owner, the sixth part's four questions** (the cursor, its views, and devices letting go), laid out
  from the code (the platform's pump, the binder's lock, `Requests`) and from what the peers and the owner's games do
  ([../research/input.md](../research/input.md) § The cursor, views and devices letting go), and asked in full at the
  fifty-first session's start. The owner asked back on three, which were answered and asked again; each was then
  answered "A (Recommended)".
  1. **(A), asked twice: the engine turns the cursor through the view the binding names.**
     - *The problem:* FFD aims where the mouse points, a strategy game clicks a unit, an action RPG clicks the ground to
       walk there. The pump dropped the cursor's place and kept its motion alone. And the simulation cannot see the
       camera the player saw: Output draws each entity interpolated between steps and relative to the camera's zone,
       and a shake or a smoothed follow is Output's alone, so an Input processor turning the cursor through the
       simulation's camera would miss by whatever Output added.
     - **First answer:** "I assume option 1 is the production answer and similar to the peers from research? The one
       thing I would say is that each "view" or "layer" or whatever we call it would have it's own translation. The 3D
       world vs 2D UI layers ( each could be different sizes, resolutions, etc ). Ultimately the update components can
       do extra work on the coordinates if needed as well."
     - **Answered:** it is the production answer, and it computes what every peer computes, the ray from the camera as
       drawn (Bevy's `viewport_to_world`, Unity's `ScreenPointToRay`), each per camera with its own rectangle (Bevy's
       `Viewport`, Unity's `pixelRect`, Godot's per-Viewport coordinates). The peers call it from per-frame code, which
       kyoten's simulation has none of, so the engine calls it and the hand-off records the result, as leafwing's
       twin-stick example does by hand.
     - **Asked again with each view's own translation:** "A (Recommended)".
       - Each view writes its own `View`, Output's own state, after each frame: which view, its rect in the window, its
         own size and units, and its camera, its pose and its projection kept apart as Bevy's are. kyoten's render
         module writes one for each camera from step 9, the UI one for each screen layer, and a game's own renderer or a
         test until then.
       - A binding names the view: `"aim": { "mouse": { "control": "Cursor", "view": "world" } }`. `"Cursor"` is
         kyoten's own name, as `Motion` and `Text` are.
       - On a `Pose` action, the ray through the view, in the world, as OpenXR's aim pose is ("A pose that allows
         applications to point in the world", −Z along the ray, +Y up), starting where it leaves the near plane. An XR
         controller's aim pose can later drive the same action, so a mouse pick and a laser pointer are one action.
       - On a `Vector2` action, the place in the view's own size and units, origin bottom-left, y up.
       - Each cursor sample is turned through the view on screen when it arrived, and the hand-off records the result,
         so a replay and a network peer read what the player aimed at, never a camera. Update processors may work on
         the coordinates further.
       - A `Pose` gains its zone, as every position has one (components § Decided, question 9), so `ZoneCoord` moves
         up to the frame tier.
     - *Set aside:*
       - (B) the window's place alone, the game's Input processor turning it through the simulation's camera, as
         Godot's tutorial does inside `_physics_process`: it misses by Output's interpolation and shake, and every game
         writes the camera's maths;
       - (C) the game's own Output processor turning it, its result handed back as the next steps' input (leafwing's
         shape): every aiming game writes the maths, and Output's state would carry input.
  2. **(A), asked twice: the game requests and releases the cursor's lock through Output's own
     `Cursor { player, mode }`, and the engine asks again while the game still asks `Locked`.**
     - *The problem:* an FPS looks with the mouse locked, and its pause menu shows the cursor. Nothing called
       `@kama/window`'s `setCursor`, and a window drops a lock by itself: on the web Escape and a tab switch, natively a
       focus loss. On the web a lock is granted only at a click.
     - **First answer:** "The main thing I want is that the game logic can release or request when needed as well. So
       this shoudl be something a game can also control."
     - **Answered:** the game requests and releases whenever it likes. An Update processor changes the game's own state
       (a menu open, a pause), and an Output processor writes the mode from it, as text entry turns on. The engine acts
       only while the game still asks `Locked` and the window dropped the lock by itself: the web locks again at the
       player's next click, natively when the window has the focus again. A game that wants a dropped lock to stay
       dropped hears it (question 4) and writes `Normal`. Under (B), a game that keeps writing `Locked` would never ask
       again, since only changes are handed on, and the FPS would lose its look after the first Escape.
     - **Asked again:** "A (Recommended)". The modes are `@kama/window`'s: `Normal`, `Hidden` and `Locked`. While the
       cursor is locked, `"Cursor"` reads the window's centre, so its ray is the camera's own, an FPS's aim. The
       mallow-man's round locks at a click so.
     - *Set aside:* (B) a lock the window drops stays dropped until the game turns `Locked` off and on.
  3. **(A): the game lets go of the pad lock through Output's own `PadLock { player, letGo }`.** "A (Recommended)".
     - *The problem:* a "press A to continue" screen, two pads on the desk, the player picking up the other one. Only a
       disconnect let go; question 4 (2026-11-21) decided that the game may, and left its API to now.
     - The step `letGo` turns on, the lock lets go, what the pad held is released, and the next pad pressed takes
       player 1, as after a disconnect. Staying on does nothing more, so `lock.letGo = onTitleScreen` lets go each time
       the screen opens, and left on by mistake it changes nothing.
     - *Set aside:*
       - (B) a seat held open, every pad's press taking player 1 while it is on (Xbox's engagement screen): left on in
         play, any pad takes over, the accident the lock prevents ("I don't want another pad taking input control
         accidentally");
       - (C) a call handed to Output processors (Unity's `InputUser.UnpairDevices`), the first service a processor
         would be handed, set aside for text entry too.
  4. **(A), asked twice: kyoten's own control names `"Lost"` and `"Unlocked"`, each a press for one step of whatever
     action the game binds them to.**
     - *The problem:* an FPS on the web pauses on Escape, but while the cursor is locked the browser takes Escape to
       give the lock back, and the page never sees it (`@kama/window`, measured), so `pause` never fires; a pad's
       batteries die mid-fight. Nothing reached the game. Xbox's XR-115 requires "Press A to continue" after a
       controller is removed, which the lock already gives, and lists pausing "when an active player's controller is
       removed" as its best practice.
     - **First answer:** "Is that a hard coded stop gap? what do others do?"
     - **Answered:** not a stopgap. The peers hand an event to the game's own code, which pauses: Unity's
       `PlayerInput.onDeviceLost`, Godot's `joy_connection_changed`, Bevy's `GamepadConnectionEvent`, Xbox's
       `XUserDeviceAssociationChangedCallback`, the web's `pointerlockchange`. kyoten's simulation hears the outside
       only through each step's hand-off, recorded so a replay and a network peer agree, so the event lands there, as a
       press of an action the game binds. The names are kyoten's own, as `Motion` and `Text` are, and later events join
       as more names (the window losing the focus, a pad joining for a second player).
     - **Asked again:** "A (Recommended)".
       - `"Lost"`, on a gamepad entry: the player's locked pad disconnected.
       - `"Unlocked"`, on a mouse entry: the cursor's lock was taken away by anything but the game.
       - `"pause": { "keyboard": "Escape", "gamepad": ["Start", "Lost"], "mouse": "Unlocked" }`: Update sees `pause`
         pressed, never a device, as the second part's answer keeps the abstraction at Input.
     - *Set aside:* (B) the event itself in the hand-off, which Input processors read and turn into the game's own state:
       closest to the peers' callbacks, but every game writes code for it, and processors read device facts; (C)
       nothing for now.

  **The sixth part, laid out, settled by the decided rules, for the owner to object to:**
  - **`View`, named `DrawnView` while building** (commit 2): kama takes any type spelled `View` for its own `type view`
    once std's is loaded, refusing it by `ref` everywhere (KY-69, filed), and a game's files would see kama's `View<T>`
    beside it. Which view, the player it is drawn for, its rect as a fraction of the window from the bottom left, its
    own size, its camera's zone, position and rotation, and `viewFromClip`, the inverse of its projection
    (`std::math::Mat4`). Reversed depth, as `@kama/graphics` draws (near 1, far 0, far possibly infinite), so the ray
    starts at clip depth 1 and its direction is taken toward a depth a hair above 0, as Bevy's is. A 2D screen layer is
    a camera at rest with an orthographic `viewFromClip` onto its own units. Before any `View`, a cursor `Pose` reads
    `Pose.identity()` and a `Vector2` reads 0.
  - **A view's name** is the game's, declared in its records as an action is, so a binding naming no view is refused at
    load, naming it; a `type value` holds no `string`, so `View` carries the view by number. Its exact record is
    settled while building and reported.
  - **`"Cursor"`** takes no other control, filter or gesture on its action and no `delta`, refused at load naming why,
    as `"Text"` is. Outside its view's rect it is still computed, so an aim past the box still aims.
  - **The pump** turns a mouse move's place into −1 to 1 of the window, by the window's logical size at the event, and
    hands `PointerLock` on as a sample, so the binder knows the lock whoever took it.
  - **`Requests`** gains each view, and each player's cursor mode and let-go; `Play` hands each change on at its frame's
    timestamp, to the input source (the views, the mode, the let-go) and the platform (the mode), as text entry.
  - **`"Lost"` and `"Unlocked"`** never move the active scheme, and take no filter or gesture; `"Unlocked"` presses only
    for a lock the game did not release.

  **Its order, each its own commit:**
  1. `ZoneCoord` up to the frame tier, and a `Pose` with its zone;
  2. the views: the engine's `DrawnView`, a game's declared views, `Requests`' views;
  3. the cursor: its place and the lock's samples from the pump, `"Cursor"` through a view on a `Vector2` and a
     `Pose`, the centre while locked;
  4. the cursor's mode: the engine's `Cursor`, the platform's `setCursor`, asking again;
  5. the lock's let-go: the engine's `PadLock`;
  6. the notices: `"Lost"` and `"Unlocked"`.

  **Found while laying it out, for a later part:** kyoten moves a player's active scheme to `KeyboardMouse` on any mouse
  motion (`engine/src/input/binder.kama` 842-843), and a Steam Deck's gyro arrives as mouse motion, so a pad player
  aiming by gyro would change scheme every frame. The-mallow-man's device latch never changes on mouse motion for that
  reason (`play/src/binds.kama` 536-545).

- **2026-11-26, built: step 8's sixth part, its first three commits** (the fifty-first session), and one of what their
  mutations found, on kyoten's pin, `0.9.1027+g25d97c29`, each gated by `tools/test.sh`.
  1. **`ZoneCoord` up to the frame tier, and a `Pose` with its zone** (kyoten `7dadfb5`): `kyoten::frame::ZoneCoord`, the
     world module importing it; `Pose { zone, position, orientation }`, at the origin zone's centre at rest.
  2. **The views** (kyoten `12be3e6`):
     - `kyoten::frame::DrawnView`, Output's own state: `player`, `view`, `at` and `span` (its rect, as fractions of the
       window from its bottom-left corner), `size`, its camera's `zone`, `position` and `rotation`, and `viewFromClip`;
       `sameAs` compares every field;
     - a module's records declare the game's views (`"views"`), refused when two modules declare one, when one is no
       lowerCamel identifier, or when it is named like a member `Views` has itself; the generated `Views` numbers them
       in the order of their names (`Views::world`), and `GameWorld::viewCount` counts them;
     - `pass_requests` gathers each `DrawnView` naming a player of the world's and a view; `Requests` holds one for each
       player and view, a later one replacing the earlier; `Play` hands each view new or drawn otherwise to the input
       source at its frame's timestamp (`InputSource.drawn(view:, at:)`).
  3. **The cursor** (kyoten `98fe1d7`):
     - `SampleKind::Cursor`, the place of a mouse event, −1 to 1 across the window and up it; `SampleKind::Lock`, the
       window holding the cursor locked or letting it go, whoever asked;
     - the pump places a move, a press, a release and an entry by the window's logical size as of that event: the size
       the last pump left (`pumpInto(…, size:)`), each queued `Resize` moving it, the window's own read when it holds
       none; a window with no area places nothing;
     - an entry's `"view"`; the binder's `"Cursor"` with its `"view"` on a `Vector2` and on a `Pose`, the first device
       that binds one; `Binder.make(…, views:)`, which the generated `run` hands `GameWorld::viewNames()`.

  What commit 2's mutations found (kyoten `3e7ea6d`): no placed cube's view named a player and no view yet (`bigCube`'s
  did, and spin's scene places none), so `pass_requests`' guard on it was held by nothing; the `quick` placement's view
  now names one.
  - **Settled while building, for the owner to object to:**
    - **The component is `DrawnView`, not `View`.** kama takes any type spelled `View` for its own `type view` once std's
      is loaded, refusing it by `ref` (KY-69, filed), and a game's files would see kama's `View<T>` beside it.
    - **A game's views are declared in its code records and numbered by name,** since a `type value` holds no `string`:
      game code writes `v.view = Views::world`, and a prefab names its view by number (`"DrawnView": { "player": 1,
      "view": 1 }`). A view naming no view yet (-1), or no player of the world's, is gathered by no one.
    - **Each step turns the cursor through the view as drawn by the step's end,** and Output through the view as last
      drawn, so a camera that turns under a still or locked cursor turns its ray, as an FPS's centre aim needs. A drawing
      a later one replaced by a step's end is forgotten, and one drawn ahead of the steps waits for them.
    - **While the window holds the cursor locked, its place is the window's centre;** let go, it is back where it was
      locked (the web holds the place still, GLFW restores it) until it moves.
    - **A cursor sample makes the keyboard and mouse player 1's active scheme,** as the mouse's motion does.
    - **A view drawn with no area, or not drawn, leaves the action at rest,** and another player's view of the same name
      turns nothing for player 1.
    - **A `Vector2`'s place runs from its view's bottom-left corner, y up,** in the view's own units, and past the
      view's rect it is still computed.
    - **The ray turns −Z onto its direction by the shortest arc, then by the camera's rotation,** so its roll is the
      camera's.
  - **Counts:** the engine's tests 961 cases (894 at the session's start), the tool's 287 (272), natively and on wasm,
    debug and release; fps and vr as before.
  - **Mutations:** kyoten's `.scratch/s51/mutate_c2.py`, `mutate_c3.py`.
    - **Commit 1, 1 of 1.**
    - **Commit 2, 38 of 38:**
      - one caught only once spin's scene placed a view naming no view yet (the fix above);
      - one, a game with no actions given no `Views`, caught by the tool's whole suite, which the batch had cut to spin
        and the refusals;
      - two by an out-of-bounds trap, after their own cases had failed by name;
      - while the batch was planned, each rotation part alone, and spin reshaped so each guard of `pass_requests` traps
        a run when it goes (a view naming no player, one past the world's players).
    - **Commit 3, 57 of 57:**
      - three by a test's binder refusing its bindings, naming why (a view read as a part, the views' names not kept,
        a `Vector2`'s cursor bound as values);
      - while the batch was planned: a `"Cursor"` object with no view, a pump holding no size, a window with no area,
        and views drawn ahead of the steps; the pump reading the window's size when it holds none replaced `openOn`
        recording it, which nothing could hold.

- **2026-11-26, built: step 8's sixth part, its last three commits** (the fifty-second session), on kyoten's pin,
  `0.9.1027+g25d97c29`, each gated by `tools/test.sh`.
  4. **The cursor's mode** (kyoten `ef6f85a`):
     - `kyoten::frame::Cursor { player, mode }`, Output's own state, and kyoten's own `CursorMode` (`Normal`, `Hidden`,
       `Locked`), read by its case names;
     - `Requests` holds each player's mode, and `pass_requests` asks each `Cursor` naming a player of the world's;
     - `Platform.cursor(player:, mode:)`, which `Play` calls as a player's mode changes. The open platforms set player
       1's on the window and keep it, and ask again for a lock the window dropped by itself while the game still asks
       `Locked`, by the rule each is made with (`CursorAsk`): the web's at once, on `PointerLock(false)`; a native
       desktop's on `Focus(true)`, which the pump now reads.
  5. **The lock's let-go** (kyoten `79a8df8`): `kyoten::frame::PadLock { player, letGo }`, Output's own state;
     `Requests`' let-go; `InputSource.padLock(player:, letGo:, at:)`, which `Play` calls at the frame's timestamp as it
     changes; and the binder letting go each time player 1's turns on, as a disconnect does, through one function both
     call.
  6. **The notices** (kyoten `75a23f8`):
     - `InputSource.cursor(player:, mode:, at:)`, which `Play` calls beside the platform's, and the binder keeping player
       1's mode by time;
     - `"Lost"` on a gamepad entry and `"Unlocked"` on a mouse entry, each pressing the actions bound to it for one step
       at its moment, moving no scheme;
     - refused at load, naming why and the way out: on another device, on a value action, in an entry with a filter, a
       threshold or a gesture, held by a chord or a sequence.
  - **Settled while building, for the owner to object to:**
    - **When several `Cursor`s name one player, the strongest ask wins,** `Locked` over `Hidden` over `Normal`, which
      asks nothing, as `TextEntry` off does, so a component left at its default cannot block a lock. Any `PadLock`
      asking lets go.
    - **The engine asks again on the web at once,** when the browser lets go, so the click that gives the page back its
      focus also locks it, since a browser grants a lock only at a click. **Natively it asks again when the focus comes
      back,** since only a focus loss drops a lock there. Only player 1's mode reaches the window, whose keyboard and
      mouse are theirs.
    - **The game's let-go puts player 1 back on the keyboard and the mouse,** as a disconnect does, through the same
      release, after any gesture whose time passed before it.
    - **`"Unlocked"` is judged by the mode as of the lock's let-go.** The game's own release is stamped after its mode
      change on every leg: `@kama/window` stamps a call's events at the call, and the browser's `pointerlockchange`
      follows `exitPointerLock`. A lock let go that was not held presses nothing.
    - **`"Lost"` presses anew** an action its pad's own button held when it disconnected, after the release.
    - **An entry naming a notice takes no filter, threshold or gesture,** even for its other controls, and a notice is
      never a chord's modifier or a sequence's step: the refusal says to bind it on an action of its own.
    - **A `Cursor` record names its mode by case name,** and a prefab naming none takes the default's through the
      loader, as every component does; a direct read of a record with no `mode` is refused ("missing field").
  - **Counts:** the engine's tests 1037 cases (961 at the session's start), the tool's 311 (287), natively and on wasm,
    debug and release; fps and vr as before.
  - **Mutations:** kyoten's `.scratch/s52/mutate_c4.py`, `mutate_c5.py`, `mutate_c6.py`, each in a worktree of its own.
    - **Commit 4, 33 of 33,** the web platform's rule on wasm under node.
    - **Commit 5, 19 of 19,** one, the let-go not advancing its gestures first, once a case held a pad's hold whose time
      passed before the let-go, in a frame that owed no step.
    - **Commit 6, 27 of 27,** two by a test's binder refusing its bindings, naming why. While the batch was planned:
      `Lost` and `Unlocked` bound to two actions, and the locked pad disconnecting while it held its action's button.

  **Step 8 is built.** KYR-54's later parts are each asked when they come: `@kama/window`'s WIN-5 turning the window's
  text input on and off; a player's settings reaching the filters and gestures; a game's own filters and gestures; how a
  higher layer merges an object entry; contexts, more local players and rebinding in a game's own UI; touch (WIN-11)
  and a pad's sensors (WIN-22); rumble, through `Requests`; and the gyro's scheme, found while laying out the sixth part.
