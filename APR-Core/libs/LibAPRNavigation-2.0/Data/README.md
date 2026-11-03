# NAV-04 terrain producer boundary

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
