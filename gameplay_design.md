# Broomstick Racing — Gameplay Design Doc

## High Concept

Solo racing game. You're a witch on a broomstick flying low to the ground (hoverbike-style) over different surfaces. Core loop is pure Trackmania — chase best times on a track, contend with the shape/surfaces/physics.

## Tech Stack

- **Language:** Odin
- **Graphics:** Raylib
- **Physics:** Box3D
- **Input:** Mediapipe hand landmarker (web cam)
- **Target:** WASM / Web

---

## Surfaces

Each surface has its own base physics profile. The same inputs produce different vehicle behavior depending on what you're flying over.

| Surface | Description |
|---------|-------------|
| Dirt | Loose, slower top speed, lower grip |
| Pavement | High grip, fast |
| Sand | Slippery, high drag, low grip |
| Grass | Soft, damped, speed penalty |

Base physics numbers (informed by Trackmania surfaces — tune during playtesting):

| Surface | Max Speed | Accel | Grip | Drag |
|---------|-----------|-------|------|------|
| Pavement | 1.0 (ref) | 1.0 | 1.0 | 1.0 |
| Dirt | 0.85 | 0.9 | 0.7 | 1.1 |
| Sand | 0.75 | 0.8 | 0.4 | 1.3 |
| Grass | 0.8 | 0.85 | 0.6 | 1.2 |

---

## Starting State

- **Stance:** Advance (Thumbs up)
- **Time of day:** Noon
- **Procedure:** Like Trackmania — 3-second countdown, then go. During countdown, no stance switching or driving. After finishing/restarting, you're instantly back at the start line in the starting state.

---

## Controls

| Action | Key |
|--------|-----|
| Accelerate | Arrow Up / W |
| Brake / Reverse | Arrow Down / S |
| Steer Left | Arrow Left / A |
| Steer Right | Arrow Right / D |
| Respawn (last checkpoint) | Space |
| Restart race | Tab / R |
| Dev: Speed stance | 1 |
| Dev: Drift stance | 2 |
| Dev: Fist stance | 3 |
| Dev: OK stance | 4 |
| Dev: Advance stance | 5 |

Stance keys 1–5 bypass the pentagram lock for development testing. In production, the webcam + pentagram rules control stance switching.

---

## Hand Stances (5)

| Stance | Hand Sign | Role |
|--------|-----------|------|
| Speed | Peace sign (✌️) | On the wheel — accel/drift matrix |
| Drift | 5-fingers spread (🖐️) | On the wheel — accel/drift matrix |
| Fist | Fist (👊) | On the wheel — accel/drift matrix |
| OK | OK gesture (👌) | On the wheel — accel/drift matrix |
| Advance | Thumbs up (👍) | NOT on the wheel — triggers time tick |

### Gesture-as-button

You do not hold your hand in the position. Each stance is activated like a **button press** — flash the hand sign at the camera.

- Webcam → Mediapipe hand landmarker (JS) → stance classification → foreign import bridge → Odin wasm loop
- Flash the sign once → stance changes → 6s cooldown before you can switch again
- If tracking is lost, the last detected stance stays active. No fallback.

---

## Pentagram Navigation

The 5 stances sit on the 5 points of a pentagram. You can only switch to the two stances **across** the star from your current position — not to any stance arbitrarily.

Arrangement (clockwise from top):

```
         Speed
       /       \
    Drift     OK
      |   x   |
    Fist --- Thumbs
```

Connections (across the star):
- **Speed** ↔ **Fist** and **Thumbs**
- **Drift** ↔ **OK** and **Thumbs**
- **Fist** ↔ **Speed** and **OK**
- **OK** ↔ **Drift** and **Fist**
- **Thumbs** ↔ **Speed** and **Drift**

To reach a distant stance, you must step through intermediates — each step costs 6s cooldown.

### Flashing Advance from Advance

Same rule as any other sign — Advance is not "across" from itself, so you cannot flash Thumbs to re-advance time. You must navigate away and back.

---

## HUD: Stance Compass & Fuse

Bottom-right corner: the **pentagram** with each stance at its point. The two currently-reachable stances are highlighted. The active stance is enlarged in the center.

### 6s debounce fuse

When you switch stances, a **fuse** ignites at the newly-active stance's point and **burns out along the 5 lines** of the pentagram over 6 seconds. You cannot switch again until the fuse has fully burned:

- Burned portion is dark/embered
- Unburned portion glows/smolders

The cooldown remaining is readable at a glance. This applies equally to Advance — flashing Thumbs steps you to that point on the pentagram, then the 6s fuse begins like any other switch.

---

## Surface × Stance Matrix

4 stances (Speed, Drift, Fist, OK) interact with the 4 surfaces. Advance (Thumbs) is NOT on this matrix — it controls time instead.

At **Noon (phase 0)** — effect sequence: `[Drift, –, –, Accel]` over `[Speed, Drift, Fist, OK]`:

| Surface | Speed (✌️) | Drift (🖐️) | Fist (👊) | OK (👌) |
|---------|------------|-------------|-----------|---------|
| Dirt    | **Drift**  | –           | –         | **Accel** |
| Pavement| **Accel**  | –           | **Drift** | –       |
| Sand    | –          | **Accel**   | –         | **Drift** |
| Grass   | –          | **Drift**   | **Accel** | –       |

Every stance is the **Accel** stance on exactly one surface and the **Drift** stance on exactly one surface at any given time.

---

## Day / Night Cycle — The Wheel

4 times of day. Race timer and time-of-day are independent — one does not affect the other. Time only advances when the player flashes **Advance** (Thumbs up).

### Advance (Thumbs up) mechanics

- Flashing Advance forces 1 tick forward: skybox and lighting change, the stance wheel rotates, all surface×stance relationships shift
- Stepping to Advance on the pentagram triggers the 6s debounce, just like any other stance switch
- At Dawn, flashing Advance wraps back to Noon

### Wheel rotation

Each surface has its own base effect sequence at phase 0. All sequences rotate right by (T − P) mod 4 each tick:

| Surface | Base Sequence (Noon) |
|---------|----------------------|
| Dirt    | `[Drift, –, –, Accel]` over `[Speed, Drift, Fist, OK]` |
| Pavement| `[Accel, –, Drift, –]` |
| Sand    | `[–, Accel, –, Drift]` |
| Grass   | `[–, Drift, Accel, –]` |

At phase P, effect for stance at index T = `base_sequence[(T − P) mod 4]`.

**Dusk (phase 1):**

| Surface | Speed | Drift | Fist | OK |
|---------|-------|-------|------|-----|
| Dirt    | **Accel** | **Drift** | –    | –   |
| Pavement| –     | **Accel** | –    | **Drift** |
| Sand    | **Drift** | –     | **Accel** | –   |
| Grass   | –     | –     | **Drift** | **Accel** |

**Midnight (phase 2):**

| Surface | Speed | Drift | Fist | OK |
|---------|-------|-------|------|-----|
| Dirt    | –     | **Accel** | **Drift** | –   |
| Pavement| **Drift** | –     | **Accel** | –   |
| Sand    | –     | **Drift** | –    | **Accel** |
| Grass   | **Accel** | –     | –    | **Drift** |

**Dawn (phase 3):**

| Surface | Speed | Drift | Fist | OK |
|---------|-------|-------|------|-----|
| Dirt    | –     | –     | **Accel** | **Drift** |
| Pavement| –     | **Drift** | –    | **Accel** |
| Sand    | **Accel** | –     | **Drift** | –   |
| Grass   | **Drift** | **Accel** | –    | –   |

### Mathematical property

Over the full cycle, every stance is the Accel stance on every surface exactly once, and the Drift stance on every surface exactly once. There is no permanent "best" configuration.

---

## The Core Puzzle

The player faces a constant resource-management and routing problem:

1. **Read the track ahead** — what surface is coming up?
2. **Check the current time phase** — which stance gives accel/drift on that surface right now?
3. **Plan the navigation path** — can I reach that stance from my current position on the pentagram? How many steps (= how many seconds of cooldown)?
4. **Maybe advance time** with Thumbs if the current phase is unfavorable — but that costs a stance switch and you end up on Thumbs, and the whole matrix changes underneath you.

The optimal line through a mixed-surface track requires thinking 2–3 stance switches ahead.

---

## Implementation Architecture

Following DDD (Domain-Driven Design) and Ousterhout's *A Philosophy of Software Design* — deep modules with small, complete interfaces that hide complexity.

### Module layout (all `package main`, organized by file)

```
src/
  main.odin              # Entry point, call init/update/shutdown
  game.odin              # State, world setup, frame orchestration
  hand_tracking.odin     # Mediapipe JS bridge (exists)

  stance.odin            # Deep module: Stance enum, pentagram adjacency,
                         #   debounce timer, current stance, switch logic,
                         #   valid-target query. Hides pentagram topology.

  surface.odin           # Deep module: Surface enum, base physics profiles
                         #   (max speed, accel, grip, drag per surface)

  time_cycle.odin        # Deep module: TimePhase enum, current phase,
                         #   advance-and-wrap, effect lookup (given surface
                         #   + stance at current phase). Hides the wheel.

  track.odin             # Deep module: TrackBlock struct, hardcoded track
                         #   data (array), surface-at-position query.
                         #   Interface designed to swap in file-based data.

  broom_physics.odin     # Deep module: resolve stance×surface×phase to
                         #   final physics coefficients, apply to Box3D
                         #   rigidbody each frame. Hides the matrix.

  camera.odin            # Chase cam behind broom

  hud.odin               # Pentagram compass, fuse animation, speed, timer

  controls.odin          # Keyboard mapping (Trackmania defaults + 1-5),
                         #   hand tracking stance override, normalize to
                         #   game actions.
```

### Key module interfaces

**stance.odin:**
```odin
get_current_stance :: proc() -> Stance
get_valid_targets :: proc() -> [2]Stance
switch_stance :: proc(target: Stance) -> bool    // respects adjacency + debounce
switch_stance_unchecked :: proc(target: Stance)  // dev bypass
get_debounce_remaining :: proc() -> f32
consume_advance_flag :: proc() -> bool            // true if Advance was just activated
update_stance :: proc(dt: f32)
```

**time_cycle.odin:**
```odin
get_current_phase :: proc() -> TimePhase
advance_phase :: proc()
get_effect :: proc(surface: Surface, stance: Stance) -> Effect
```

**track.odin:**
```odin
get_surface_at :: proc(position: rl.Vector3) -> Surface
get_track_blocks :: proc() -> []TrackBlock
```

**controls.odin:**
```odin
// Controls state is read directly by broom_physics:
//   controls_state.steer, .accelerate, .brake
// Stance switching uses switch_stance_unchecked(key) via keyboard handler.
```

### Dev notes / guardrails

- Stance keys 1-5 work unconditionally (bypass pentagram) for testing. The hand tracking pipeline is the only path that enforces pentagram rules.
- Track data starts as hardcoded arrays; the `get_surface_at` / `get_track_blocks` interface is the seam to swap in file-based loading.
- Camera, ghost/replay, and medal times are not in the first milestone but the architecture should not prevent them — the camera is a separate module, and the physics/track modules don't assume anything about replays.
- Surface detection: raycast down from broom position using Box3D. Each track block stores its bounds + surface type.

---

## Camera

Third-person chase cam locked behind the broom, like Trackmania. Separate module, added after core physics and track are working.

---

## Track Structure

Discrete block/section-based, like Trackmania. Each track segment is a tile with a surface type. Transitions between surfaces are handled by blocks that blend between types.

**Track length:** One track, ~3 minutes. The first track is designed to highlight and transition between all 4 surfaces — twisty chicanes, full-speed straights, mixed surface sections that force stance planning.

**Data format (start):**
```odin
TrackBlock :: struct {
    surface:   Surface,
    start:     rl.Vector3,
    length:    f32,
    width:     f32,
    curvature: f32,  // 0 = straight, positive = right, negative = left
}
```

The `get_surface_at(pos)` function iterates blocks and returns the surface for the block containing the position.

---

## Crash / Recovery

Physics-based bounce using Box3D collision. Hitting walls/obstacles sends the broom bouncing. Respawn-to-last-checkpoint for major dislodges (Space key).

---

## Physics Integration

Stance enum modifies Box3D rigidbody parameters each frame:
- **Acceleration stance:** multiply forward force by accel_multiplier
- **Drift stance:** reduce lateral friction / increase angular damping
- **Neutral:** use surface base coefficients

Simplified coefficient resolution per frame:
```odin
base := surface_profiles[surface]
effect := get_effect(current_phase, surface, current_stance)
mult := effect == .Accel ? 1.3 : effect == .Drift ? 0.7 : 1.0
// Apply: forward_force = base.accel * mult (for accel)
// Apply: lateral_friction = base.grip * mult (for drift)
```

---

## Menu / UI

All Raylib immediate-mode GUI. No hand gestures for menu navigation — keyboard and mouse only.

---

## Future-Proofing Notes

- Ghost/replay: The broom's transform and stance at each frame can be recorded to a buffer. The camera module already treats the broom as a target — a replay just drives that target from recorded data.
- Medals / author times: The track stores a reference time. Compare on finish. No special physics needed.
- Track editor: The TrackBlock struct + file-based loading is the natural seam. An editor would emit the same data format.
- More stances or surfaces: If we add more, the pentagram and wheel scale — just extend the enums and adjacency tables.
