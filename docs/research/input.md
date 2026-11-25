# Input: how the peers and the owner's games turn devices into a game's actions

Gathered 2026-11-21, at the forty-fourth session's readying, for [design/input.md](../design/input.md) and the first
slice's step 8 (KYR-54). Two research passes read the peer engines' documentation and source, and FFD's and
the-mallow-man's code. **Claims a question rests on were re-checked against their source and are marked [checked];**
the rest are the pass's own, marked [pass], with the page each came from.

## Summary

| | Event times, and input across fixed steps | Shaping a value, and recognizing input over time | Contexts and overlapping bindings |
|---|---|---|---|
| Unity Input System 1.19 | Every event keeps its time; in "Process Events in Fixed Update" mode "input events are processed in groups according to whether their timestamp falls within the current fixed time step" [checked] | processors (dead zones, scale, invert, normalize, clamp), binding's then action's, feed interactions (Press, Hold, Tap, SlowTap, MultiTap) [pass] | action maps on or off, no priority; shortcut consumption off by default [pass] |
| Unreal Enhanced Input | evaluated per tick; no split across fixed steps found [pass] | modifiers (DeadZone, Scalar, Negate, Swizzle, curves, Smooth…), mapping's then action's, feed triggers (Down, Pressed, Released, Hold, HoldAndRelease, Tap, Pulse, Chord, Combo) [pass] | mapping contexts with a priority, a higher one consuming its keys; a chord blocks the plain key [pass] |
| Godot 4 | no time on an event; a press is seen by exactly one physics tick, the next [checked] | a dead zone per action; no taps or holds [pass] | no contexts; events propagate until handled [pass] |
| Bevy 0.20 and leafwing 0.22 | no time on an event; Bevy's issue #6183, input missed or doubled under a fixed step, is open; leafwing samples once a frame for the fixed steps [pass] | processors per input (dead zones, sensitivity, invert, bounds) [pass] | a clash strategy, the longest chord first by default [pass] |
| Steam Input | no times found; polled states or change callbacks [pass] | activators in Steam's configurator (Regular, Double, Long, Start, Release, Chorded) [pass] | one action set per controller, layers on top [pass] |
| SDL3 | every event has a time in nanoseconds [pass] | none: a dead zone is the application's [pass] | none |
| OpenXR 1.1 | a boolean action's `lastChangeTime`; edges against the previous sync [pass] | the runtime turns a value into a boolean by a threshold with hysteresis [pass] | an action set's priority suppresses a lower set's bindings of the same source [pass] |

## Event times and fixed steps

- **Unity** splits by timestamp and waits for a step to finish: "Partially elapsed fixed time step periods like this
  aren't processed until the frame after they have fully elapsed" [checked]
  ([timing-optimize-fixed-update](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/timing-optimize-fixed-update.html)).
  Read in the wrong update mode, `WasPressedThisFrame` misses an edge or reports it twice [pass]
  ([timing-missed-duplicate-events](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/timing-missed-duplicate-events.html)).
- **Godot** stamps a press for the next physics tick: "As input may come in part way through a physics tick, the
  earliest we can react to it is the next physics tick", then `pressed_physics_frame = get_physics_frames() + 1`, and
  `is_action_just_pressed` compares it with the physics frame during a tick [checked]
  ([core/input/input.cpp](https://github.com/godotengine/godot/blob/master/core/input/input.cpp), master, read
  2026-11-21). A press and release within one frame still counts as just pressed [pass].
- **Bevy's** issue #6183, "Inputs can be missed (or duplicated) when using a fixed time step", opened 2022-10-06, is
  open [pass] ([#6183](https://github.com/bevyengine/bevy/issues/6183)). Its example accumulates input before the
  fixed loop and clears it only on a frame where a fixed step ran [pass].
- **SDL3** stamps every event, `SDL_GetTicksNS()` [pass]. In the SDL that `@kama/window` vendors (3.4.18), a
  GameInput pad's button event carries its reading's own time (`SDL_gameinputjoystick.cpp:592`), but only the
  current reading is read at each update (`:939`), and an XInput pad is stamped when it is polled
  (`SDL_xinputjoystick.c:336`) [checked, in `../kama-window/third_party/sdl/`].

## Bindings as data

- **Unity**'s `.inputactions` JSON: a binding is a control path (`<Keyboard>/w`, `<Gamepad>/rightTrigger`) with
  processors and interactions as strings; a composite is a marked entry followed by its parts (`1DAxis`'s `negative`
  and `positive`, `2DVector`'s `up`, `down`, `left`, `right`). A player's rebinding is an override stored apart from
  the file, by binding [pass] ([ActionBindings](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/ActionBindings.html)).
- **Unreal**: a mapping context lists key to action with modifiers and triggers; four keys become one 2D action
  through Negate and Swizzle modifiers, with no composite type [pass]
  ([Enhanced Input](https://dev.epicgames.com/documentation/en-us/unreal-engine/enhanced-input-in-unreal-engine)).
- **Godot**: `project.godot`'s `[input]` section, serialized events per action, a dead zone per action [pass].
- **Names:** keys are physical everywhere (Unity's `A` "is always the key to the right of the Caps Lock key"; Godot's
  `physical_keycode`; Bevy's `KeyCode`; SDL's scancode), and a pad's face buttons are named by place (Unity's
  `buttonSouth`, SDL's `SDL_GAMEPAD_BUTTON_SOUTH`, Bevy's `GamepadButton::South`, Unreal's `Gamepad_FaceButton_Bottom`)
  [pass]. `@kama/window` already names both so: a key by the DOM's `KeyboardEvent.code`, a face button by its place.

## Players and devices

- **leafwing**: an input map with no pad of its own reads every pad: "If this is [`None`], input from any connected
  gamepad will be used" [checked] ([src/input_map.rs](https://github.com/Leafwing-Studios/leafwing-input-manager/blob/main/src/input_map.rs)).
- **Godot**: an action matches one device or all of them (`-1`) [pass].
- **Unity**: `PlayerInputManager` joins a player when a button is pressed on an unpaired device, with a maximum count;
  a lost device is paired again when it returns [pass]
  ([PlayerInputManager](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.19/manual/PlayerInputManager.html)).
- **Steam Input**'s handle follows a controller across a reconnect, and SDL's joystick id never does [pass].

## Text, poses and look

- **Typed text is kept apart from actions** in Unity, Godot, Bevy, SDL and Steam; OpenXR's action types are boolean,
  float, vector2, pose and vibration [pass]. § Typed text, below, has the fuller survey.
- **A pose** is an OpenXR action space, located at whatever time the program asks, predicted when it is ahead [pass].
- **Camera look per frame:** Bevy's fixed-timestep example rotates the camera every frame, since doing it in the fixed
  steps "would sometimes not register player input"; Godot recommends applying mouse motion to the camera directly
  rather than in `_physics_process` [pass].

## The owner's games (read in their trees, 2026-11-21)

Both games' input code is FFD's, forked into the-mallow-man (`engine/src/input/`, and TMM's `play/src/binds.kama`
from FFD's `sim/src/input.kama`).
- **No event carries a time** in either, and neither splits a frame's input across ticks.
- **A bind table in code, two columns per action** (keyboard or mouse, and the pad), rebound by the player: FFD refuses
  a clash and writes `bind.key.<ACTION>` lines; the-mallow-man swaps the two actions and writes only the binds that
  differ from the defaults, in JSON.
- **Edges:** FFD hands every owed tick the same frame of levels and re-derives presses inside the simulation with
  latches; the-mallow-man latches each press until a tick takes it, then hands it to the first tick only, which is
  frame-phases' "edges wait for a step that consumes them".
- **Recorded:** FFD's replay and lockstep carry each tick's `InputFrame`, the actions after binding (24 bytes); the
  mallow-man's network carries a quantized `PlayerInput` with its press bits. A rebind never reaches the world hash.
- **Pads:** one pad, the first mapped; FFD's dead zone fixed at 0.25 per axis; the-mallow-man's radial dead zone,
  trigger threshold and look curve set by the player.
- **Look:** the-mallow-man adds mouse motion, stick and keys each frame and hands the resulting yaw and pitch to each
  tick.
- **Local multiplayer:** neither has it.

## Filters (gathered 2026-11-23, the forty-eighth session)

For the third part of step 8 ([design/input.md](../design/input.md) § Decided, 2026-11-23). Three passes read the
peers' documentation and source and the owner's games; the defaults the two decisions rest on were re-checked in the
source by hand and are marked [checked].

- **Unity Input System 1.11.2**
  ([source](https://github.com/Unity-Technologies/InputSystem/tree/1.11.2/Packages/com.unity.inputsystem/InputSystem)):
  - Every pad stick carries a scaled radial dead zone at the control, so every binding to it gets one:
    `processors = "stickDeadzone"` on `leftStick` and `rightStick` (`Devices/Gamepad.cs` lines 140 and 150), its
    bounds `m_DefaultDeadzoneMin = 0.125f` and `m_DefaultDeadzoneMax = 0.925f` (`InputSettings.cs` 767 and 768); the
    triggers carry none (161, 170) [checked]. The formula rescales min..max to 0..1 on the vector's length
    (`StickDeadzoneProcessor.cs`) [checked]; `axisDeadzone` is the same on one axis, and a parameter of 0 means "the
    default", so 0 cannot be set [pass].
  - A press point with hysteresis on actions: `m_DefaultButtonPressPoint = 0.5f`, `m_ButtonReleaseThreshold = 0.75f`
    (773, 774), the release at `pressPoint * …ReleaseThreshold` (`Actions/InputActionState.cs` 1588) [checked]. A
    control's own `isPressed` has none [pass].
  - `leftStick/up`, `down`, `left` and `right` are synthetic controls, the clamped half of an axis
    (`clampMin=0,clampMax=1` and its mirror, `Controls/StickControl.cs` 71 to 106) [checked].
  - Its processors: Clamp, Invert, InvertVector2/3, Normalize, NormalizeVector2/3, Scale, ScaleVector2/3,
    AxisDeadzone, StickDeadzone; a part binding's, then the composite's, then the action's, each list left to right; a
    player's change is a binding override (`overrideProcessors`), saved as JSON overrides [pass]
    ([Processors](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Processors.html)).
- **Godot 4.7**: an action's dead zone is 0.2 by default, 0.5 for the `ui_*` actions (`core/input/input_map.h`,
  `DEFAULT_DEADZONE = 0.2f`, `DEFAULT_TOGGLE_DEADZONE = 0.5f`) [checked], 0.5 before 4.4 (PR #97281) [pass]. It is
  both the press point and the start of the rescale (`get_action_strength`), `get_vector`'s dead zone is radial and
  rescaled, and there is no hysteresis, sensitivity, invert or curve [pass].
- **Unreal Enhanced Input**: DeadZone (Axial, Radial, UnscaledRadial; lower and upper, rescaled between), Scalar,
  Negate, SwizzleAxis, ResponseCurveExponential, ResponseCurveUser, Smooth, SmoothDelta, FOVScaling,
  ScaleByDeltaTime and ToWorldSpace; a mapping's modifiers, then the action's, in array order [pass]
  ([Python API](https://dev.epicgames.com/documentation/en-us/unreal-engine/python-api/class/InputAction)). The
  defaults could not be read: Epic's headers are not public. Lyra's modifiers read the player's saved settings (dead
  zones, sensitivity presets, inversion) [pass] ([Lyra input settings](https://dev.epicgames.com/documentation/en-us/unreal-engine/lyra-input-settings-in-unreal-engine)).
  A stick's direction is a key (`Gamepad_LeftStick_Up`), pressed past XInput's dead zone with no hysteresis, as UE4's
  source quoted by a blog shows [pass].
- **leafwing-input-manager 0.22 and Bevy**: Digital, Inverted, Sensitivity, ValueBounds, Exclusion (unscaled),
  DeadZone (scaled), their circular forms and Custom, none applied by default ("No processing is applied to raw data
  from the gamepad"); `GamepadControlDirection::LEFT_UP` and its siblings with a threshold and no hysteresis. Bevy
  underneath: ±0.05 per axis, and buttons pressed at 0.75 and released at 0.65 [pass].
- **Steam Input**: a player sets a stick's dead zone (its shape, inner and outer), an anti-dead zone, a response curve
  (Linear, Aggressive, Relaxed, Wide, Extra Wide, Custom), sensitivity and invert per axis; Valve's advice to a game:
  "make the deadzone, acceleration, and sensitivity of the joystick configurable" [pass]
  ([getting started](https://partner.steamgames.com/doc/features/steam_controller/getting_started_for_devs)).
- **The reference on stick dead zones**, Josh Sutphin's "Doing Thumbstick Dead Zones Right" (2013): axial snaps to the
  cardinals, radial jumps from 0 to the dead zone's edge, and the scaled radial
  `normalized * ((magnitude - deadzone) / (1 - deadzone))` is smooth [pass]
  ([post](https://joshsutphin.com/blog/doing-thumbstick-dead-zones-right.html)). Ryan Juckett's INVERSUS adds an outer
  zone past which the magnitude is 1 [pass].
- **The owner's games** (read in their trees): FFD's dead zone is 0.25 per axis, rescaled past it, also its triggers'
  threshold (`engine/src/input/state.kama` 72, 398 to 431), and no sensitivity, invert or curve. The-mallow-man's sticks
  take a scaled radial dead zone, 0.2 by default, and its triggers 0.15, each the player's (0.05 to 0.4 and 0.05 to
  0.6); its look curve is `sign(v)·|v|^2` per axis on the look stick; its rates 0.0008 radians per mouse count, 3.2
  and 2.2 a second at a full push, with the player's mouse and stick multipliers and invert Y, one settings file per
  machine. Its menus press a stick's direction at 0.55 and let it go below 0.35, then repeat. Neither smooths.
- **`@kama/window`**: a pointer's motion is in logical pixels, and raw counts while the cursor is `Locked` (GLFW's raw
  motion where supported, Pointer Lock's `unadjustedMovement` with a fallback); a pad's button is pressed at 30/255
  both ways, with no hysteresis; consecutive moves of a pointer are joined, their motion summed (its SPEC).

## Gestures (gathered 2026-11-24, the forty-ninth session)

For the fourth part of step 8 ([design/input.md](../design/input.md) § Decided, 2026-11-24). Three passes read the
peers' source and documentation and the owner's games. The claims the three questions rest on were re-checked by hand,
in source where it is public, and are marked [checked].

- **Unity Input System 1.11.2**
  ([source](https://github.com/Unity-Technologies/InputSystem/tree/1.11.2/Packages/com.unity.inputsystem/InputSystem)):
  - **Its defaults, in `InputSettings.cs` 773 to 781** [checked]:
    - a tap 0.2 and a slow tap 0.5;
    - a hold 0.4;
    - a multi-tap's gap `m_MultiTapDelayTime = 0.75f`.
  - **Its five interactions** (`Actions/Interactions/`) [pass, except where marked]:
    - **Press:** press only, release only, or both.
    - **Hold:** started at the press and performed when its time passes while held; it stays performed until released
      (`PerformedAndStayPerformed`, `HoldInteraction.cs` 63, 84) [checked].
    - **Tap:** performed at a release within its time, and cancelled once the time passes while held.
    - **SlowTap:** shown as "Long Tap" (`SlowTapInteraction.cs` 19) [checked], and performed at a release after its
      time.
    - **MultiTap:** each tap released within `tapTime`, the next pressed within `tapDelay`; it performs on the last
      release. Its own TODOs ask for "perform on final press rather than on release", and that it "stays performed
      when the tap count is reached until the button is released" (`MultiTapInteraction.cs` 10 to 15) [checked].
  - **Several interactions on a binding:** they are checked in order, the first to start drives the action until it
    performs or cancels, and an action's interactions are appended to each binding's [pass]
    ([Interactions](https://docs.unity3d.com/Packages/com.unity.inputsystem@1.11/manual/Interactions.html)).
  - **What a reader sees:**
    - `IsPressed`, `WasPressedThisFrame` and `WasReleasedThisFrame` read the raw press, whatever the interaction
      [pass];
    - `WasPerformedThisFrame` reads the interaction [pass];
    - `GetTimeoutCompletionPercentage()` gives a hold's progress, 0 to 1 (`Actions/InputAction.cs` 1508) [checked].
  - **Interactions run on value actions too,** on a control's magnitude (a stick's Hold) [pass].
  - **Chords are composites:** `OneModifier` and `TwoModifiers`.
    - **Consumption is off** (`m_ShortcutKeysConsumeInputs = false`, "This is the shortcut support from v1.4.
      Temporarily moved here as an opt-in feature, while it's issues are investigated", `InputSettings.cs` 781)
      [checked].
    - So by default Shift+B fires B's binding too, and the modifier need not be pressed first; the composites hold to
      that order only when consumption is on [pass].
  - **UI navigation repeats** in `InputSystemUIInputModule`: the first move at once, the next after
    `m_MoveRepeatDelay = 0.5f`, then every `m_MoveRepeatRate = 0.1f` (829, 834) [checked]. It has no repeat interaction
    and no sequence [pass].
  - **A timeout runs from the press event's time,** checked at each update: timed by events, not game time [pass].
- **Unreal Enhanced Input** (Epic's C++ is not public. Descriptions are from Epic's Python and C++ API pages; defaults
  are from a third-party quote of `InputTriggers.h` [pass]):
  - **Its triggers:**
    - Down, Pressed and Released;
    - Hold: `HoldTimeThreshold` 1.0, `bIsOneShot` false, triggered every tick once held past it;
    - HoldAndRelease: 0.5, at a release after it;
    - Tap: `TapReleaseTimeThreshold` 0.2;
    - Pulse: `Interval` 1.0, `bTriggerOnStart` true, `TriggerLimit` 0 for none, with no initial delay apart from its
      interval;
    - ChordAction: "the action that must be triggering for this trigger's action to trigger", which names an action;
    - Combo: steps of actions in order, each within `TimeToPressKey`;
    - RepeatedTap: a double tap, in 5.6 and later.
  - **How triggers combine on a mapping:** any explicit, all implicit, and a blocker overrides.
  - **ChordBlocker** is "Automatically instantiated to block mappings that are masked by a UInputTriggerChordAction
    chord from firing whilst the chording key is active" [pass, Epic's C++ API page]. The forums report that it fails
    with several mappings of one action [pass].
  - **Reading a hold:** `FInputActionInstance::GetElapsedTime()` and `GetTriggeredTime()`.
  - **Timed triggers ignore time dilation by default** (`bAffectedByTimeDilation`, false) [pass].
- **leafwing-input-manager 0.22**
  ([source](https://github.com/Leafwing-Studios/leafwing-input-manager/tree/v0.22)):
  - **Chords:** `ButtonlikeChord` is pressed while all its inputs are, in any order [pass].
  - **Clashes:** inputs clash when "the Buttonlike components of one user input is a strict subset of the other", and
    the default strategy is `PrioritizeLongest`, "Only press the action that corresponds to the longest chord"
    (`src/clashing_inputs.rs` 17 to 40) [checked]. So the shorter action is dropped while the longer is held, the
    modifier's own action included [pass].
  - **No hold, tap, double tap or sequence;** a `timing` feature reports how long an action has been held [pass].
  - **Bevy's `bevy_input` has no button gestures,** only the operating system's touch gestures [pass].
- **Steam Input** ([activators](https://partner.steamgames.com/doc/features/steam_controller/activators)) [checked]:
  - **Double Press** "requires a quick double tap of the input to activate. If held on the second press, it will
    remain pressed. Any interruptable activators on the same button will not fire if a double press is fired, and will
    be paused until the double press time has passed."
  - **Long Press:** "interruptable activators on the same button will not fire if a long press is fired, and will be
    paused until the button is released while under the long press time."
  - **Chorded Press** is "Like the regular press, but additionally, a specific button must be held down at the same
    time that the regular activation input is pressed. Other bindings for the chorded button will continue to fire."
  - **The other press types** are Regular, Start Press and Release Press.
  - **Every activator's settings:** Toggle, Fire Start and End Delay, Haptics and Cycle Binding; Turbo with its repeat
    rate on some. Most defaults are not documented [pass].
- **The owner's games** (read in their trees):
  - **FFD:**
    - **Chords are modal holds:** a bumper or a gate held masks the bare D-pad, which fires only "when no bumper or
      gate is held" (`game/src/game.kama` 2928-2934) [checked].
    - **Its other patterns over time:** a 3-second hold of the lighter, timed in the simulation; tool swaps and
      accusations toggled on a press.
    - **Its menus do not repeat.**
  - **The-mallow-man:**
    - **Its restart is a chord on an action:** R pressed while the action SPRINT is held
      (`game/src/roundplay.kama` 706-707) [checked].
    - **Its pad menus repeat:** pressed at 0.55, let go below 0.35, the first press at once, then 0.40 and every 0.12
      (`ui/src/nav.kama` 12-24 at `2e1988b^`, the last copy in its tree before it moved to `@kama/ui`) [checked]. Its
      keyboard menus use the operating system's key repeat.
    - **Its radio cursor** repeats at `wireRepeatS = 0.35` and `wireRepeatEveryS = 0.15` (`sim/src/round/tuning.kama`
      376-377) [checked].
    - **Its holds, charges and timing windows are the simulation's own timers,** chosen by what is near, not by how
      long a button is held.
  - **Neither game has** a double tap, a combo or a hold-to-confirm screen.
- **`@kama/window`:**
  - **A key's down carries `repeat`,** the window's own reading, and kyoten's pump drops a repeat
    (`engine/src/platform/open.kama` 148-149).
  - **A pad's buttons do not repeat,** and a pointer has no click count.
  - **A modifier is a key like any other** (HID 224 to 231), and the `mods` bits on an event go unread by kyoten.

## Typed text (gathered 2026-11-25, the fiftieth session)

For [design/input.md](../design/input.md)'s fifth part, `Text`. Three passes: the peers in their source at the commits
named, the owner's games in their trees (the-mallow-man `70fe7ef`, FFD `77a2604`), and kyoten's own code.

- **SDL3** ([`a01f519`](https://github.com/libsdl-org/SDL/tree/a01f51916eb3a3989b0bcbc2e2dbcbc724515414), after 3.4.20):
  - **Off until the program asks:** "Text input events are not received by default", and `SDL_StartTextInput(window)`
    "On some platforms … shows the screen keyboard and/or activates an IME, which can prevent some key press events from
    being passed through" (`include/SDL3/SDL_keyboard.h` 360-385) [checked].
    - `SDL_StartTextInputWithProperties` takes the field's type (text, name, email, username, a password, a number), its
      capitalization, autocorrect, multiline and maximum length.
    - `SDL_SetTextInputArea` places the IME's window beside the field [pass].
  - **Text is committed text only:** one `SDL_EVENT_TEXT_INPUT` per delivery, UTF-8, which may hold several code points.
    - An event that starts with a control character is not posted ("Don't post text events for unprintable characters",
      `src/events/SDL_keyboard.c` 736-751) [checked], so Backspace, Enter and Tab are keys.
    - A composition is `SDL_EVENT_TEXT_EDITING`.
    - SDL2's 32-byte text event is gone [pass].
  - **The screen keyboard** shows by default only "if there is no physical keyboard attached"
    (`SDL_HINT_ENABLE_SCREEN_KEYBOARD`, `"auto"`). On X11 under Steam's Big Picture, SDL opens Steam's floating keyboard
    through `steam://open/keyboard` (`src/video/x11/SDL_x11keyboard.c` 922-962) [pass].
- **Unity Input System 1.20.2**
  ([`062d225`](https://github.com/Unity-Technologies/InputSystem/tree/062d225450794a2575389058c36f362bd04f1196)):
  - **Text is its own stream:** `Keyboard.onTextInput(char)`, a UTF-16 unit, so a code point past the BMP calls it
    twice. "Text input does not fit the control-based input model well and thus is represented as its own form of input"
    (`Runtime/Events/TextEvent.cs`) [pass].
  - **It is always delivered.** Only the IME is switched (`SetIMEEnabled`: "Typically, this is not desirable while
    playing a game") [pass]. A composition is `onIMECompositionChange`.
  - **A field does not stop actions:** "The UI will not consume input such that it will not also trigger in-game
    actions" (`Documentation~/KnownLimitations.md` 20) [checked].
- **Godot 4.8-beta**
  ([`25d0522`](https://github.com/godotengine/godot/tree/25d0522345fb8b58cc469b6760dd73c04b0f0186)):
  - **Text is a key event's `unicode`,** one code point, 0 below 0x20 and for 0x7F (`core/os/keyboard.cpp`,
    `fix_unicode`) [pass]. An action carries no text.
  - **`LineEdit` turns the IME on when it starts editing,** and shows the virtual keyboard with its box, type and
    maximum length (`scene/gui/line_edit.cpp` 124-152) [pass].
  - **A field does not stop actions:** `Input` updates every action's state before it hands the event to the GUI
    (`core/input/input.cpp` 1086-1131) [checked]. Only `_unhandled_input` is filtered.
- **winit 0.30.13 and Bevy** ([winit](https://github.com/rust-windowing/winit/tree/v0.30.13),
  [Bevy `93af76a`](https://github.com/bevyengine/bevy/tree/93af76a2a6228281b4c5c486ec2d8fa5807f0ca2)):
  - **The IME is off by default:** "IME is **not** allowed by default … during the preedit phase the window will NOT get
    [`KeyboardInput`] events … Not allowing IME is useful for games … iOS / Android: This will show / hide the soft
    keyboard" (`src/window.rs` 1260-1286) [checked].
  - **Editing keys stay keys:**
    - winit's `KeyEvent.text` gives `"\r"` for Enter;
    - Bevy's `TextInput` widget treats Enter, Backspace and the arrows as keys, and inserts text only for a character key;
    - it sets `Window.ime_enabled` while an editable field has focus (`crates/bevy_ui_widgets/src/text_input.rs` 632-659)
      [pass].
  - **A field does not stop actions:** `ButtonInput<KeyCode>`, which leafwing reads, updates whatever has focus [pass].
- **Unreal 5.7:**
  - an Input Action's value is a bool or an axis, never text;
  - Slate's `FCharacterEvent` carries a UTF-16 unit;
  - `SetInputMode_UIOnlyEx` "allows only the UI to respond to user input".

  [pass] All three are from Epic's API pages; its source was not read.
- **leafwing-input-manager 0.22:** an action is a button or an axis, and its network form, `ActionDiff`, holds no text
  [pass].
- **Steamworks** ([ISteamUtils](https://partner.steamgames.com/doc/api/ISteamUtils)):
  - **Two keyboards:**
    - `ShowGamepadTextInput` is modal, and hands back a whole UTF-8 string when it is dismissed;
    - `ShowFloatingGamepadTextInput` "sends OS keyboard keys directly to the game", placed beside the field's box [pass].
  - **Deck Verified:** games must "automatically display an on-screen keyboard when requiring the user to input text"
    ([recommendations](https://partner.steamgames.com/doc/steamdeck/recommendations)) [checked].
- **The browser** (the W3C's drafts) [pass]:
  - a key has its `key`; then `beforeinput` and `input` carry an `inputType` (`insertText`, `deleteContentBackward`);
  - composition has events of its own;
  - a phone's keyboard rises for a focused editable element, its `inputmode` choosing which keyboard;
  - an `EditContext` can attach to a canvas.
- **No peer records typed text in a replay or sends it per keystroke** [pass].
- **The owner's games:**
  - **FFD has no text path:**
    - no char callback, and its one typed field, a room code, is built from raw key-downs. Its comment says "**NO PASTE
      AND NO IME**, which is the honest cost and is why a PLAYER NAME is not typed here" (`game/src/game.kama` 1239)
      [checked];
    - its chat comes from speech, kept out of the simulation: "A line is not an `InputFrame` bit, it never reaches
      `World`, it is not hashed" (`engine/src/chat/board.kama` 10) [checked].
  - **The-mallow-man types into `@kama/ui`'s RmlUi fields:**
    - one code point per GLFW char event, always on, routed to a field only while a menu or the chat is open
      (`game/src/menu.kama` 534-539) [pass];
    - Backspace, Delete, Enter, the arrows, Home and End reach the field as keys, the operating system's repeats
      included [pass];
    - **while a field is open, the round steps with an idle input,** "this player's camper stands still"
      (`game/src/game.kama` 1208-1217 and 2624-2628; `menu.kama` 703-704) [checked];
    - its chat is sent whole on Enter, at most 64 bytes (`play/src/chat.kama` 49) [checked];
    - on Steam's hardware or Big Picture, A on a field opens Steam's floating keyboard, then the modal one
      (`play/src/steamkeyboard.kama`) [pass]. With no Steam, a pad cannot type.
- **kyoten** (`d19abbd`):
  - **No text reaches the binder:** the platform's pump drops `@kama/window`'s `Event::Text`, one code point an event,
    and drops a key's repeats (`engine/src/platform/open.kama` 149 and 176).
  - **The tool refuses a `Text` action** (`tools/kyoten/src/records.kama` 272).
  - **Nothing carries a request from a game back to the binder or the platform.**
  - **An Output processor may write nothing** (`tools/kyoten/src/schedule.kama` 254).
  - **`@kama/window` has no text input to turn on or off,** no IME and no on-screen keyboard; IME composition is its
    unbuilt WIN-5.
