# Retail declarative metadata

`Catalog.lua` is an 8,923-byte literal metadata projection of the editable
`Route-generator/data/navigation_v2/retail/declarations/catalog.json`. It is
registered once by the library XML and assigns only
`namespace.NavigationV2RetailDeclarationsData`. It creates no engine, binds no
endpoints, queries no game APIs and admits no transport, entrance or unlock.

The canonical directory retains the complete 13 existing V1 DATA tables using
typed table entries, plus normalized V2 geography and transport facts. Its README
describes the encoding, exclusions, neutral aliases and existing public exporters.
No V1 algorithm was read or copied. No supplemental data was collected.

The normalized facts retain 181 isolations, 2,052 spaces, 184 supported entrance
declarations, 272 supported transport declarations and 793 bind candidates.
113 other entrance declarations and 552 transport declarations are excluded;
their original facts, all 680 source unlock recipes and other configuration remain
available in the canonical source tables. These counts describe the initial
import and do not require editorial content to keep its current population.

The full normalized Lua exports remain offline: loading those payloads at startup
would add roughly 2.4 MiB of unbounded declarations. This metadata registration
does not claim runtime data admission, live compatibility, physical validation,
completion of NAV-20, or a V2 rollout. V1 remains the default.

Initial recipes, exact source/artifact hashes, alias mappings, exclusions and test
receipts are in `.scratch/libaprnavigation-2/reports/ORCHESTRATOR/Retail-declarations-next/`.
The original captures are immutable evidence; preserve later maintained editions.
