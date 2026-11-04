# Forever transport data

The authoring source is `Route-generator/data/navigation_v2/forever/transports.json`.
Edit that JSON, then regenerate from the Route-generator root:

```powershell
.venv/Scripts/python.exe -m tools.navigation_v2.import_transports --input data/navigation_v2/forever/transports.json --output ../azeroth-pilot-reloaded/APR-Core/libs/LibAPRNavigation-2.0/Data/forever/Transports/Catalog.lua
```

`Catalog.lua` is factual data, indexed by readable transport ID. It creates no
graph, client calls or access evidence. Directions, numeric API attributes,
technical positions (including absent altitude), explicit requirements, actions,
cooldown groups, review flags and estimates come from V1 declarations. Excluded
records retain their declaration and a machine reason. A missing ground cost
does not become a free crossing. There is no runtime V1 dependency.

`namespace.NavigationV2ForeverTransports.Bind(id,binding)` binds **one** record to
existing V2 contracts and returns `{graph,options}`, or `nil,machineReason`.
Pass `bundle.graph` and `bundle.options` with clocks/observations to the existing
`LibAPRNavigationV2.New`; APR's existing explicit `Enable` accepts the same graph
and options. The bundle also carries `travelOptions.scheduledTimeoutSeconds`;
pass it with the objective ID to existing `StartTravel`. There is no implicit
host activation. The two nodes come from the
caller; there is no inferred approach, nearby join, floor/phase or world coverage.
The caller merging bundles owns exact node identity and remains incomplete.

Every binding supplies `from` and `to` records:
`{node,space,worldID,phase?,floorID?}`. World and any declared floor are nonnegative
native integers; space and any declared phase are business identities. A source world ID
must agree. A map-space position remains a map position; it never supplies world
or floor identity. A dynamic bind destination additionally needs
`bindObserved=true`, supplied from trustworthy current binding evidence.
No default floor or phase is created. Scheduled stops retain optional floor/phase
constraints; portal and personal declarations retain their optional phase
constraints. An unrelated observed phase does not constrain an undeclared one.
A declared constraint still requires matching evidence: missing evidence stays
unknown/pending, and an observed mismatch is refused. Missing/changed evidence
must invalidate the owning planner through the existing observation/setter contracts.

- Boat/zeppelin/elevator/tram: retain the declared aggregate automatically, or
  supply `costs={approach,boarding,ride,loading,disembark,final}` with explicit
  `wait` in the existing Scheduled format; positive `timeoutSeconds` and optional
  tri-valued `access` (Scheduled retains unknown when omitted).
- Portal/passage: retain the declared aggregate automatically, or supply
  `costs={waitSeconds,useSeconds,loadingSeconds}`; positive
  `timeoutSeconds`, through the existing confirmed-transition Portal lifecycle.
  Portal open/access observations and any declared phase remain necessary. The passage
  mapping describes an observed transition; it creates no terrain walk edge.
- Spell/item: `costs={useSeconds,loadingSeconds}`, positive `timeoutSeconds`,
  `cooldownSeconds`, explicit booleans `consumable/rare/chargeBased`, and positive
  reagent quantities for every known reagent API ID. Consumables also supply
  their `itemResourceId`. Existing Personal owns inventory/resources, cooldown
  forecasts, native usability, secure use and correlated arrival. Group spell and
  reagent alternatives remain factual metadata; they are not silently selected.

An explicit V1 bidirectional record emits forward and reverse declarations;
false emits only forward. An absent direction requires an explicit
`binding.bidirectional` decision backed by evidence. Personal reversal is refused.
Trams use Scheduled's same observed lifecycle. Ground-walk admission remains
refused with `transport_kind_unsupported`: a ground line alone cannot supply
geometry. These records remain in the data catalogue.
`gaps` describes missing facts, not an automatic veto on every record: absent
cost components do not prevent using a declared aggregate total.

Source faction/class/minimum-level requirements become **observed access facts**
`faction-alliance`, `class-mage`, `minimum-level:20` (illustrative values).
Quest/access predicates retain their actual booleans/IDs. Endpoint access keys
become `location-access:<key>`. The host/caller owns current fact evidence;
`Bind` does not evaluate characters or invent proof. All resulting requirements
are validated through the existing Conditions compiler. Missing/false evidence
retains the engine's unknown/denied behavior.

Totals in V1 are aggregate estimates. With no manual `costs`, Bind uses the
declared `seconds` as exclusive `totalSeconds`. An explicit
`binding.totalSeconds` overrides that total. It never divides the total or fills
omitted pieces with zero; `wait` and component costs remain absent. A complete
decomposition is an optional alternative and cannot be mixed with a total.
Scheduled and Portal accept total overrides through their existing setters;
partial component overrides are rejected. Calibration never describes or
measures fictional ride/loading components for an aggregate. The declared
Geography cast/loading defaults are retained as estimates in the data, not
automatically applied. No data is claimed verified in game on Forever
1.60.1.70755; no new WoW API is introduced. V1 remains the default.

Initial migration provenance, reviewed name mapping, source SHA256 values,
counts, exclusions and gaps are documented in
`.scratch/libaprnavigation-2/reports/NAV-23/`. That historical evidence is separate
from runtime data. Current canonical content is authoritative after migration;
do not rerun the historical one-shot migration over subsequent edits.
