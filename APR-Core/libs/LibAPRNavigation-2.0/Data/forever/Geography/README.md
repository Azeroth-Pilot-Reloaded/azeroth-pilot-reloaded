# Forever geographic facts

Edit `Route-generator/data/navigation_v2/forever/geography.json`, then export from
the Route-generator root:

```powershell
.venv/Scripts/python.exe -m tools.navigation_v2.import_geography --input data/navigation_v2/forever/geography.json --output ../azeroth-pilot-reloaded/APR-Core/libs/LibAPRNavigation-2.0/Data/forever/Geography/Catalog.lua
```

`Catalog.lua` is registered once by the library XML. It assigns only
`namespace.NavigationV2ForeverGeographyData`: isolation declarations, named
logical spaces, entrance metadata, exclusions and unknowns. It performs no
client query, graph construction, transport binding or host activation. V1 stays
the default. The data uses Lua5.1 literals and the existing transport importer's
generic literal serializer, with no runtime V1 dependency.

The initial conversion copied the existing V1 `Data/forever/Geography.lua`,
`NavigationSpaces.lua` and `InstanceEntrances.lua`. It retained five isolation
records,76 logical spaces and29 entrance declarations. The record-level counts
are historical import evidence, not schema requirements. The source hashes,
editorial name mapping, converted example and disposition of every source record
are in `.scratch/libaprnavigation-2/reports/FZ-alterac-mountains/v1-geography-import-20261103/`.
The canonical JSON is authoritative after this initial migration; do not rerun
the one-shot migration over later author edits automatically.

The reviewed completion also copies the already available V1
`InstanceConnections.lua` collections `config.NavigationSpaces` and `entrances`:
26 additional spaces and30 additional entrance declarations. The resulting
snapshot contains five isolation records,102 spaces and59 entrances. These are
import receipt counts, not minimum content requirements. Its39 `connections`
remain owned by the transport import and are neither copied nor interpreted by
this geography importer. The source hashes, explicit additional aliases and
record dispositions are in
`.scratch/libaprnavigation-2/reports/FZ-alterac-mountains/v1-geography-completion-20261103/`.
All earlier facts, four exclusions and five unknown annotations remain unchanged.
This completes the two identified collections; it does not claim an audit of
every possible V1 metadata source or physical coverage.

Business IDs are editable aliases without numeric API IDs or coordinates.
Neutral `unlabelled-*` aliases explicitly retain unknown display names. Greek
letter alternatives do not identify dungeon wings, inferred directions or
relative locations. Native world/map/area IDs, bounds and positions remain
technical attributes. Source IDs and source-to-business mappings belong to the
migration receipt. Rename references together with their declared target; common
tests validate references and types without freezing a maintained name or count.
New `*-instance` aliases describe the declared instance kind. New
`*-world-entrance` aliases distinguish a declared world-position representation
from an existing map-position representation; they do not assert different
physical doors. Directional labels are retained only when present in the source
label, while the Nightmare Grove alternatives use neutral Greek letters.

The two declared collections are concatenated without matching records by name,
bounds, coordinates or shared world/instance attributes. A repeated source ID
within a collection or across its two sources rejects the migration, including
identical or unmapped repetitions. Duplicate business aliases also reject it.
No declaration is silently overwritten or merged. Spaces and entrances retain
their separate identity domains. Unsupported additional configuration or
container fields retain their original value as exclusions; the transport-owned
`connections` field is explicitly delegated instead.

Space `parentSpace` and `transitRegion` references are copied only when explicitly
declared and are rewritten through that mapping. Worlds, map/area selectors,
source bounds, optional floor/phase/access identity, faction, ground-only and
exit constraints are retained as declared. Bounds, including broad Z ranges,
are metadata and do not supply a physical floor, collision, access observation
or permission to walk. Missing fields stay missing. Overlapping selectors do
not merge records or create ancestry.

The authoring/export contract rejects self-parenting and longer parent cycles.
Initial migration retains each cycle member as a `cyclic_parent_space` exclusion
with its original declaration; dependents left without a declared parent are
retained as `unresolved_space_reference` exclusions. No parent is silently
removed or redirected to repair the hierarchy. `transitRegion` is a separate
reference domain and may refer to the record itself; its self-reference does not
form a parent cycle.

The two spaces containing `terrainScopeIDs` retain those opaque V1 technical
references and an explicit unknown binding. They do not load or reconstruct the
referenced geometry. Joining them to a separately imported terrain catalogue
requires its own reviewed mapping; this catalogue creates no link.

Entrance `exterior` and ordered `approach` positions remain metadata. The catalogue
does not turn the approach into edges, estimate its cost, infer a reverse route,
or fabricate an interior arrival/exit. Native `instanceID`, optional
`journalInstanceID` and `interiorMapIDs` are separate attributes. All initial
Forever interior UiMap lists are empty and remain empty; native instance IDs
are not substituted into them. Three candidate entrances and their reasons
remain candidates, including the entry with no exterior. A copied V1
`reviewStatus="confirmed"` is not new client validation.

The existing transport catalogue already owns the three cast/loading defaults;
they are retained here only as excluded source facts with that reason. The V1
navigation threshold is also excluded from active geography facts. The three
empty override collections are recorded as empty in the migration receipt.
Unsupported or unmapped declarations retain their original value and a machine
reason instead of being silently repaired. This import duplicates no transport
route and does not modify transport costs or binding APIs.

`complete=false` describes the catalogue's lack of physical/world coverage.
Neither the Forever client nor native arrivals, phase/access conditions or
complete Alterac navigation have been verified by this data contribution. The
separate Retail import phase is not implied by the reader's optional client
argument. No additional source collection was performed.
