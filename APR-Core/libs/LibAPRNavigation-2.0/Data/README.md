# Terrain producer boundary

`Loader.lua` is pure Lua 5.1, with no WoW events, timers, frame work or host
activation. `ForeverFirstTile.lua` declares one generated sector in the existing
addon namespace. The shipped library XML registers both files without decoding
any block. V1 stays active by default. The explicit APR development path is:

```lua
local host = APR.NavigationV2
local loading, reason = host:LoadTerrain("forever-first-tile")
assert(loading, reason)
local result = loading:Step(64) -- repeat on subsequent ticks while running
-- result.status: running / complete / unknown / invalid / cancelled
-- On complete: result.graph and result.positions (technical positions only).
-- loading:Cancel() releases a partial load; no timer is installed automatically.
if result.status == "complete" then
    assert(host:Enable(result.graph)) -- a separate explicit development action
    -- Select located technical node IDs, then host:Plan({from=..., to=...}).
    -- Repeat host:Step() while running; only host:SetTarget publishes guidance.
end
```

`LoadTerrain` returns an independent loading job and leaves the host's enabled
state, current request and legacy navigation untouched. Injected decoder options
may be supplied as its second argument in tests. The default uses the verified
native EncodingUtil APIs; absent APIs return `decoder_unavailable`. The pure
library equivalent remains `NavigationV2Terrain.New(catalog, options):Load(id)`.
The concrete sector is a Forever development sample, not a default route for
either client. Do not activate it outside its documented client/build/domain.

Load defers decoding; Step checks a 1 ms cooperative slice between work units.
When loaded with the library's `Graph.lua` (the actual XML path), standalone
loading also uses its centralized 100 ms accumulated profiling and 5 s elapsed
defaults. Optional `options.clock` supplies monotonic seconds; otherwise elapsed
time is derived from `profileClock` milliseconds. All slices share the same
budget; a stop is terminal `budget_exceeded`, never an unchanged decode retry.
Isolated legacy loader-only consumers keep their earlier slice-only contract.
Partitioned planning calls the loader's internal one-unit `Advance`, since its
outer job already owns preparation/decoding/search/reconstruction budgets.
Do not drive that internal operation directly from a frame loop.
One unit is one bounded native decode, one validation stage, one copied node,
one copied edge or one reference check. At most 32 blocks, 128 nodes per block,
768 outgoing edges per block and 16 KiB CBOR per block are accepted. Each job
holds one decoded block at a time and at most 4096 nodes / 24576 edges. It has
no cache and does not restart itself. Cancel releases partial graph/positions
and the decoded block, including cancellation inside a decoder callback.
Missing sectors, empty data and decoder failures are explicit; no missing
surface becomes a direct route or a proof of disconnection.

Native decoding cannot be preempted and can exceed a slice by one operation.
The input is trusted static addon data, **not a network or SavedVariables input**:
WoW's native DecompressString has no output-size argument. The loader checks
encoded size before decoding and decoded size immediately afterwards. For
untrusted inputs a bounded decompressor would be required.

Wire format: RFC 8949 definite-length arrays and signed/unsigned integers only:
`[2, firstGlobalNode, [[recastXMilliyards, heightMilliyards, recastZMilliyards], ...],
[[fromGlobalNode, toGlobalNode, costMilliseconds], ...]]`.
The CBOR bytes are raw RFC 1951 Deflate (`wbits=-15`), then standard padded RFC
4648 Base64. `first`, `nodes`, `edges` and `rawBytes` are the declared envelope.
Node IDs become technical `terrain:<index>` strings; client/build/map/tile identity
remains in declaration attributes and in the offline provenance manifest.
Positions are separate from the planning graph.

`ClientOptions` explicitly selects `Enum.Base64Variant.Standard` and
`Enum.CompressionMethod.Deflate`. The API signatures were checked against the
[Forever](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncodingUtilDocumentation.lua)
and [Retail](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncodingUtilDocumentation.lua)
client API documentation. Automated tests inject Python equivalents; native
WoW decoding, frame latency and gameplay remain unverified in both clients.

All exported graphs have `complete=false`: this first terrain-only sector omits
liquids, cells containing unparsed objects, neighboring tiles, dynamic combat,
phases and all non-foot travel. A successful route is optimal in the retained
portal graph with its declared cost model; it is not a claim of complete world
coverage or continuous geometric shortest distance. The first cost model uses
7 yards/second on foot with each segment rounded up to milliseconds. No jumps,
damaging drops, transport or mode-switch edges are generated.

The result contains machine reasons and technical positions only. Consumers
must not render IDs or positions as guidance titles, errors or tooltips.

## Partitioned graphs (NAV-07)

`Sectors.lua` adapts the same loader and shortest-path engine to several named
sectors. The light index contains only names, local node counts, coverage flags
and explicit directed boundary links. Encoded blocks remain in the catalog.
The adapter does not enumerate or decode the catalog at construction, request
capture or request validation. A popped search node loads its own sector, one
loader/graph-preparation/boundary-validation operation per planning advance.
Unvisited sectors are not decoded or compiled. There is no world-graph merge.

```lua
local index = {
    garden = {name="Garden path", nodes=2, complete=false, links={
        {id="market-gate", name="Market gate", from=2,
            sector="square", to=1, seconds=0.25, access="available"},
    }},
    square = {name="Market square", nodes=1, complete=true, links={}},
}
-- These technical blocks come from the offline exporter, never from proximity.
local source, reason = namespace.NavigationV2Sectors.Source(index, catalog, {
    profileClock=profileClock, decodeBase64=decodeBase64,
    inflate=inflate, deserialize=deserialize, cacheSize=2, complete=false,
})
assert(source, reason)
local planner = assert(namespace.LibAPRNavigationV2.New(source, {
    clock=clock, profileClock=profileClock,
}))
local job = planner:Plan({from="garden:terrain:1", to="square:terrain:1"})
-- Call job:Step() on subsequent ticks, or job:Cancel(). No automatic timer/output.
```

`complete` on the source describes coverage of the indexed graph. The default
is false. Each sector's `complete` must match the catalog flag; the actual
decoded node count must match `nodes`. A complete flag is an author/importer's
explicit coverage assertion, not a side effect of successful decoding. The
NAV-04 shipped sample remains partial. A successful route is optimal in the
known usable graph; incomplete coverage or failed/missing decoding cannot prove
disconnection. A usable known alternative wins over unknown or absent branches.
The destination sector must decode and validate before a boundary route can
complete, including a route whose destination is its first boundary node.

Sector IDs and link IDs are readable ASCII slugs (`garden`, `market-gate`).
Each sector and boundary requires a separate human name. Local indices and
qualified node IDs (`garden:terrain:2`) are technical references. Boundaries
are directed; a reverse crossing requires its own declaration. No geometric
adjacency, reverse edge or connection to an absent neighbor is inferred.
Links may target a sector not yet surveyed: this remains an unknown reference,
not a fabricated sector. Known target node counts are validated. Access values
are `available` (default), `unavailable` and `unknown`. At most 256 boundary
declarations per sector are accepted. Dense arrays, unique link IDs, finite
nonnegative costs, endpoint ranges and human names are checked lazily at entry.

Each planner's cache contains at most `cacheSize` fully decoded/compiled sectors
(default 2, supported range 1–8), with O(1) LRU touch/eviction. No cache entry is
pinned by an open search. Each concurrent search owns at most one partial sector
in addition to this cache. Search labels retain node IDs/costs/predecessors,
not sector graphs. Eviction may cause a later reload; it never restarts a request
or drops a predecessor. Search and path reconstruction use the existing shared
1 ms slice, 100 ms cumulative CPU and 5 s elapsed defaults. A single native
decode remains non-preemptible; the NAV-04 trust/size limits apply unchanged.
Cancellation releases partial decoding; terminal/budget-exhausted jobs do not
restart. Failed sector decoding is remembered for that request, so reaching a
second boundary node in the same missing sector does not repeat unchanged work.
A new explicit request may retry; a transient failure is not cached forever.
Loaded sectors are immutable for a planner's lifetime: create a new
planner/source when updating an index or catalog. `Invalidate` invalidates
request revisions; it is not a data-editing operation.

`Loader:Load(id, true)` qualifies local nodes/edges with their sector ID for this
adapter. Omitting the flag preserves the original NAV-04 IDs and API behavior.
`Sectors.Source` constructs a descriptor without decoding. `Graph.New` accepts
this descriptor in the normal `Navigation.New`/APR `Enable` planning path.
The public factory and explicit APR `EnableSectors` wrapper require the shared
XML/factory/host integration recorded in NAV-07's report; no default is switched.

Prepared routing retains only the active adjacency row and its edge-validation
bits in each search, rather than locating/touching the same page for every edge.
This row may outlive eviction of its page; it does not pin the other decoded
rows. Include that one bounded row per open search in memory accounting.

Offline, `tools/navigation_v2/sectors.py` exposes `build_catalog(sectors, links)`
and `lua_catalog(result)`. Inputs are surveyed milliyard node triples and
directed local edges with millisecond costs, plus named explicit boundary
declarations (`from=[sector,node]`, `to=[sector,node]`, `milliseconds=...`).
It reuses `compact.blocks`, writes no files, and emits deterministic Lua 5.1
with UTF-8 human names. Importers must supply evidence for each boundary; this
module has no terrain-neighbor inference or runtime NavigationData writes.

Pure Lua contracts cover directed crossings, missing/unknown/inaccessible
neighbors, optimal known alternatives, via nodes, invalid declarations,
cache eviction/reload, interleaved searches and cancellation/budgets during
loading and reconstruction. The actual Python codec/export round trip compares
36 small generated directed graphs with an independent cost oracle. These are
synthetic tests, not observations of movement or native client timing. Native
Forever/Retail codec, frame latency, boundaries and physical movement must still
be checked in game before either client switch.

## Prepared routing for large surveyed graphs

The delivered offline CLI still calls `partition_graph` and `build_catalog`.
It additionally calls `routing.prepare_routing` and audits the serialized export
through `generate.audit_export(output)`. `graph.json` retains the original
directed multigraph and optional walk/swim/shore-transition mode codes;
`node-map.json` remains offline. The manifest keeps source hashes, coverage,
native agent, client/build, movement costs and partition settings. No new data
is automatically installed in the addon or activated for a client.

`SectorBundle.lua` merges the light index/catalog and also registers one complete
descriptor in `namespace.NavigationV2SectorBundles[bundleId]`. All three
namespaces are preflighted before any entry is inserted. A duplicate fails
without overwriting another export or leaving half a bundle registered.
For an authorized, audited packaged import, explicit activation is:

```lua
local bundle = namespace.NavigationV2SectorBundles["surveyed-paths"]
local decoder, reason = namespace.NavigationV2Terrain.ClientOptions(
    C_EncodingUtil, Enum, debugprofilestop)
assert(decoder, reason)
decoder.routing = bundle.routing
decoder.routingIdentity = bundle.routingIdentity -- source identity from offline audit
assert(APR.NavigationV2:EnableSectors(bundle.index, bundle.catalog, decoder, {
    clock = GetTime, profileClock = debugprofilestop,
}))
```

`LibAPRNavigationV2.NewSectorGraph(index,catalog,decoder)` accepts the same options
for consumers using `Navigation.New` directly. Omitting `decoder.routing`
explicitly selects the geometry-sector adapter above. The default APR engine
remains V1. No new client API is used by prepared routing: its injected native
codec adapter is the previously verified Forever/Retail adapter.

The atlas is an **immutable trusted compiled artifact**. At generation and
again before import, `verify_routing(atlas,sectors,links,context=...)` recomputes
the identity from the actual source, checks every compiled adjacency against
the declared edges (including serial/cost/access), verifies both directed
potential triangle inequalities, and audits every witness edge, accumulated
distance and acyclic forest. `generate.audit_export` rebuilds the partition
from the actual graph/settings, compares all encoded geometry and the complete
light index/movement metadata, then performs that routing audit. Invoke it as:

```powershell
python -m tools.navigation_v2.generate audit --input output/surveyed-paths
```

The returned identity is SHA-256 of canonical UTF-8 JSON containing the source
sectors, validated boundaries and source context. For the CLI, context includes
client/build, tile/map attributes, coverage, source hashes, native agent,
movement modes, movement costs and swim draft. Runtime compares the explicit
expected source identity and validates useful page/edge formats and boundary
contracts. It **does not authenticate hand-edited local adjacency or witnesses**
against geometry, nor compute a cryptographic whole-graph hash during planning.
Changing data after audit violates the artifact contract. Any source, cost,
access, mode, coverage or geometry change requires regeneration plus import
audit, or explicit disabling of prepared routing and creation of a fresh source
using updated geometry. `Invalidate` only changes request revisions.

Schema 1 uses integer/array CBOR, raw Deflate and standard Base64. A block holds
`[1, firstLocalNode, rows]`. Adjacency tuples contain target sector ordinal,
target local node, milliseconds, access code and source edge serial. There are
separate pages for directed landmark potentials and each witness direction.
Default adjacency/potential/witness page sizes are 16/32/64 rows; all have a hard
128-row bound, 16,384 raw-byte bound and 22,000-byte Base64 envelope bound.
Two landmarks are selected offline by deterministic distance sampling, with a
supported range of 0–8. The planner does not scan a world-sized per-node index,
merge geometry, decompress all pages, or select landmarks in `New`/`Plan`.
The schema and declared row-size attributes are unchanged; older audited
16/32/8 archives remain valid. Larger default pages reduce the resident Lua
record/string overhead of tiny witness blocks and compress repeated values
together. Adjacency and potential defaults retain their smaller native decode
granularity. The controlled 1024-node fixture checks a192KiB static Lua ceiling
before decoding; this fixture is not an aggregate
addon/world residency bound; real codecs and larger payloads still need timing
validation on both clients.

Each prepared planner caches at most `cacheSize * 128` adjacency rows (default
256, supported 128–1024), plus 1024 potential rows and 1024 witness rows in
separate LRU caches. A search owns at most one partial decoded page (128 rows)
in addition to those caches. Encoded static atlas data and search labels are
separate memory costs. Failure of a page is remembered for the request; no
unchanged automatic retry loop is introduced. Geometry is not decoded to plan
on the atlas. A needed missing adjacency yields unknown coverage; a missing or
unusable certificate falls back once to the same bounded search engine.

Directed capped landmark distances give an admissible A* lower bound. A cheap
certificate is accepted only when a directed source-to-landmark-to-destination
witness equals that lower bound, every returned edge is available, the exact
integer cost sum agrees and the full path is continuous. Unknown/unavailable
witnesses, cycles, a more expensive witness and requests with mandatory visits
use the ordinary search. Existing reconstruction, revision/cancellation and
1 ms slice / 100 ms CPU / 5 s elapsed budgets remain active throughout page
loading, certificate tracing and reconstruction. Native codec calls remain
non-preemptible. A successful route proves optimality only in its declared
known graph/cost model. Large searches can still exhaust their budget; the
bounded cache and landmarks do not guarantee all world queries finish in 100 ms.

Synthetic tests include independent directed-graph oracles, non-landmark
endpoints, false local witnesses with plausible equal bounds, stale source
identities, unavailable/unknown access, zero cycles, changed costs, partial data,
interleaved jobs and cancellation during decoding and reconstruction. The
actual exporter/import gate/XML/public factory/APR opt-in host are exercised.
Desktop codec equivalents are not in-game codec or movement evidence.

## Explicit flat-page backend (NAV-20 seam)

`Pages.lua` adds an opt-in backend for an already audited runtime sector bundle.
The pure offline `tools.navigation_v2.pages.compile_pages(bundle)` compiler lives
in Route-generator. It neither extracts geometry nor prepares routes, reads
client data, writes exports, or publishes addon folders. Publication/import must
still bind the input to its original graph through the existing audited-import
gate. `generate.py` and the host have no automatic flat-format integration.
Legacy envelope catalogs and prepared routing remain supported.

The package has `format="apr-flat-pages-1"`, a small `bootstrap` map containing
only each sector's node count, completeness and metadata record ordinal, and
the unchanged global routing header. Encoded `index`, `payloads`, `extras` and
offline-only `attributes` are strings. No permanent Lua envelope is created for
each page. Source page order/boundaries/payload bytes, human names, routing
identity, costs, access, geometry movement attributes and other envelope fields
are conserved; navigation payloads are never recompressed by this compiler.

The index is Base64 over19-byte big-endian records: first/count/rawBytes
(uint16 each), payload offset (uint32), payload length (uint16), extras offset
(uint32), extras length (uint16), and kind (uint8:1routing,2geometry,3metadata).
Offsets are zero-based; exposed record ordinals are one-based. An explicit
read decodes at most28 Base64 index characters. It returns one temporary
envelope; there is no metatable that decodes when callers index a page array.
The complete decoded index is never retained.

Each sector has a bounded CBOR header; its boundary links use CBOR chunks of at
most16 links. Headers reference contiguous page families by first/count spans.
Metadata uses the existing Deflate/Base64/CBOR pipeline, with definite CBOR
arrays/maps, UTF-8 text keys/values, booleans and finite binary64 numbers. The
encoder's default integer/array mode and existing geometry/routing CBOR bytes
are unchanged. Metadata mode rejects nil/None, non-finite values, byte strings
and non-text map keys rather than coercing or dropping fields. Envelope extras
are Base64 CBOR without another compression layer; package attributes are
opaque offline-only CBOR and are not materialized by the runtime.

Use the existing factory explicitly:

```lua
options.routing = packed.routing or nil
options.routingIdentity = packed.routingIdentity
local source = assert(namespace.LibAPRNavigationV2.NewSectorGraph(
    packed.bootstrap, packed, options))
local planner = assert(namespace.LibAPRNavigationV2.New(source, plannerOptions))
local job = planner:Plan(request)
-- Metadata, index reads and native decoding occur only in subsequent Step work.
```

`New`/`Plan` do not decode metadata. The first loading job validates bootstrap
entries and routing name references one per advance; progress is shared by the
immutable package, so later requests do not restart a world scan. Header/link
decode, incremental field validation and envelope reads belong to the existing
`search.loading.job` or standalone loader job. Existing cumulative CPU/wall and
slice checks therefore include this work. Cancellation/staleness releases its
partial state. An unchanged terminal job never retries a failed decode; a new
explicit request can recover. A request may retain its active sector metadata
while another request evicts the shared entry; decoded row caches do not pin a
metadata object for every cached page.

Limits are centralized in `Pages.lua`:16MiB encoded strings,4MiB decoded index
equivalent,1,024 bootstrap sectors/4,096 routing names and64KiB charged bootstrap
IDs,16KiB raw metadata record,64KiB aggregate raw metadata per sector,4,096
validated fields and depth16 per assembled sector,256 links, and an8-entry /
512KiB raw-metadata-charge LRU. The offline compiler also checks the bootstrap's
encoded CBOR size against64KiB and only accepts lower overrides. Transport
Base64 is capped at22,000 characters, deriving a16,500-byte packed/extra CBOR
maximum; decompressed metadata and original inner page raw caps remain16KiB.
`pages.stats` exposes bootstrap units, operations, index/native decode counts,
loads/hits/evictions, resident entries and raw-byte charge. Existing geometry
and routing row-cache bounds remain in effect.

The metadata byte charge counts source CBOR, not Lua allocator bytes. Field,
depth, string transport, entry and active-job bounds constrain structure;
temporary native decode allocations and Lua table overhead are not a strict
allocator-byte certificate. Native decode is still indivisible. The native
EncodingUtil signatures/Deflate/Standard Base64 contracts were checked for
Forever and supported Retail11.2.7,12.0.0/1/5/7,12.1.0/5 against their primary
client API documentation; tests inject an independent RFC CBOR cross-reader.
Actual client CBOR mapping, frame timing, combat/taint and native allocator
behavior remain unverified. See the linked Forever/Retail API sources above.

This seam does not resolve the prior prototype's18.75ms desktop Lua literal
load observation. This backend has no whole-pilot profile yet. Admission before
package construction, accumulated world/package
residency, or arbitrary native file IO. No game API, JSON parser, per-page addon,
new planner lifecycle, host integration or default-client switch is introduced.
