# Navigation benchmark

Open `/apr navbench`. Enter the start and destination **UiMapID**, X and Y in
**map percentages (0..100)**. The maps may differ. Select **Player** to capture
the start when pressing V1, V2 or V1 + V2; the two engines receive independent
copies of the same captured endpoints. Editing an input invalidates the display
and copy action. Cancel or close the window to stop an active attempt.

The benchmark owns independent planning jobs. It does not enable V2 for normal
navigation, replace the active journey, publish waypoints or advance quests.
V1 remains the default. The frame is lazy and does no per-frame work while idle.

## Reading the measurements

- `wallMs` includes time between cooperative slices. `cpuMs` measures active
  calls using `debugprofilestop`, in milliseconds; it is not an OS CPU counter.
  Initial input/player/character capture is outside those engine timings.
- `estimatedSeconds` is the **travel ETA**, shown only for a complete result.
  It is separate from calculation latency. Provisional scope/optimality stays
  explicit; an unknown result does not supply a travel ETA.
- Driver calls, actual API `Step` calls and created/completed searches are
  separate counters. The two adapters expose different public layers; consult
  their context/scopes before comparing counts. Missing measurements are
  unavailable, and an observed zero remains zero.
- V1 and V2 run sequentially, with the central slice/CPU/wall limits and no
  automatic repetitions. Native operations cannot be preempted; overruns are
  reported. No cache is reset, and no cold-cache or equivalent-domain speedup
  is asserted. The copy button exports inputs, context and scalar results.

## Data and scope limits

V2 prepares the existing V1 data through public data getters. Forever uses its
declared terrain, paths, collisions and transports, preserving direction and
conditions. Its loader also requests explicitly declared intermediate neighbor
scopes. Retail uses declared spaces, mandatory passages and transports with the
available movement model, including mounted skyriding; it does not require a
complete ground-path or collision network.

Graphs remain partial and request-scoped. A complete calculation means a route
was found in that declared model, not a global optimum or a verified journey in
the game. A source/current build mismatch, ambiguous spatial identity, missing
required observation or unsupported declaration remains explicit. Authored
geometry can justify an arrival without inventing a current-player height or
floor. No proximity edge or unproven physical shortcut is added to force success.

V1 uses a separate public planner/instance with an explicit 7 yards/second walk
model and zero fare budget. Shared mutating action/cooldown observers, dynamic
bind/housing/camp positions, taxi providers and normal adapter preparation are
excluded. Basic character fields are captured once; readonly inventory/quest
queries remain live. These are diagnostic scopes, not equivalent complete-world
navigation domains. Their limits are included in the technical report.

Synthetic tests cover behavior and real public planner/loader calls with
controlled data. Actual client rendering, timings, physical coverage and taint
checks must be observed separately; automated tests do not establish them.
This tool authorizes neither extra data collection/imports nor a V2 rollout.
