# Porting tools: other engines' projects onto kyoten

**Status:** draft, deferred to KYR-73. These are questions, not decisions.

## What the owner asks

- **Porting tools for popular engines** (2026-11-11): "Porting tools for popular engines... The first two would be
  Three.js to Kyoten and Unity to kyoten."

## What already helps

- **`@kama/graphics` keeps three.js's names** where the concept is the same ([rendering.md](rendering.md) § Decided,
  area 2): `Mesh`, `MeshStandardMaterial`, `PerspectiveCamera`, `DirectionalLight` and the rest. So a three.js scene's
  objects map one to one, its materials onto the same typed presets, and its node materials (TSL) onto the
  node-material system (area 3). The feature map (`@kama/graphics`' `FEATURES.md`) names each feature as three.js does.
- **glTF is the common asset format.** three.js loads and exports it (`GLTFExporter`). Unity exports it through
  packages such as UnityGLTF and Unity's glTFast *(to verify: which export what, and under which license)*.
- **Unity's model is close to kyoten's:**
  - a GameObject's components map onto components;
  - prefabs map onto prefab records, and ScriptableObjects onto records;
  - a `MonoBehaviour`'s `Update` maps onto a processor in a phase.

  [../research/component-models.md](../research/component-models.md) already compares the two models.
- **kyoten is AI-driven** ([../VISION.md](../VISION.md)). Translating a game's code is work an agent does, with the
  compiler as the judge, and the project database (KYR-24) holds a port's map of equivalents.

## The questions

1. **What a port produces.** A kyoten project that builds and runs: records, assets in kyoten's formats and kama code,
   with a report of what did not port and why. Is the goal a running first draft that an agent and a person finish, or
   everything ported faithfully?
2. **Assets.** Meshes and textures go through the content pipeline (KYR-29) to glTF and KTX2.
   - Unity's models are often FBX, whose SDK has its own license.
   - Do they come from an exporter running inside the Unity editor, a converter outside it, or both?
3. **Scenes and prefabs.**
   - Unity saves them as text YAML under "Force Text" serialization, with references by GUID through `.meta` files.
   - three.js has `Object3D.toJSON()` and glTF.
   - Is a project read from disk without the source engine installed, or exported from inside it?
4. **Materials and shaders.**
   - Unity's URP Lit and Standard shaders map onto `MeshStandardMaterial` and `MeshPhysicalMaterial`, Shader Graph
     onto node materials, and hand-written HLSL onto WGSL.
   - three.js's materials and TSL map nearly one to one.
5. **Code.** JavaScript or TypeScript (three.js) and C# (Unity) become kama.
   - An agent translates them, with the compiler as the judge.
   - The mechanical parts are translated deterministically, by the tool.
   - The port's map of APIs is kept in the project database.
6. **How a port is checked.** The original and the port are run side by side:
   - each scene's image is compared perceptually;
   - behaviour is compared under the same recorded inputs, where the original can be driven.
7. **Where it runs.** A `kyoten port` command, an agent's tool through MCP (KYR-25), or both. Also: whether the three.js
   port can target `@kama/graphics` alone, for a program that is not a kyoten game.
8. **Licenses and names.**
   - A port reads only the developer's own project. It never needs the engine's code and never ships it.
   - Each engine's terms are read for anything about its file formats and its editor scripts.
   - An engine's name says what a tool reads ("imports a Unity project") and is never in the tool's own name, as
     Unity's trademark guidelines ask ([../research/graphics.md](../research/graphics.md) § 8).
9. **Which engines next:**
   - Godot: MIT, with text scenes;
   - Unreal: binary assets, so through its own exporters;
   - Babylon.js, PlayCanvas and Bevy.
10. **When.** The three.js port needs the renderer and records. The Unity port needs what a Unity game uses: physics,
    animation, UI and audio.
    - So the three.js port can follow the first slice and the level (KYR-11).
    - The Unity port can follow the gate (KYR-12) and the modules it maps onto.

## Decided

- **2026-11-11, the owner: porting tools are on the roadmap** (KYR-73), three.js and Unity first. The questions above
  are decided when the row comes up.
