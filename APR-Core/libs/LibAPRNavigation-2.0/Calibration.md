# Local travel cost calibration

`namespace.NavigationV2Calibration` is pure Lua 5.1. It does not observe the
client, own an event frame, poll, persist globals or run the planner. The APR
adapter captures public time only at explicit execution/event boundaries.
V1 remains the default navigation engine.

## Data and priority

`New({store,identity,definitions})` takes an optional calibration namespace,
`identity={client='Forever'|'Retail',build,character,computer}` and a dense list
of `{key,component='ride'|'loading',defaultSeconds,manualSeconds?}`. Keys and
identities are readable nonempty strings. `computer` is an explicit installation
identifier: WoW exposes no stable machine identifier. A caller may deliberately
use a local installation label, but must change it when copying SavedVariables
to another machine if distinct estimates are wanted. Client builds and characters
are separate partitions. Missing public character/build identity disables
calibration rather than mixing characters or clients.

`Get(key)` returns seconds and `manual`, `measured` or `default`. Persisted manual
settings take precedence over a definition's explicit configured manual setting,
then measured calibration, then the definition's captured fallback. `SetManual`
accepts a number or nil to remove a persisted override. `Reset(keyOrNil,mode)`
accepts `manual`, `measured` or `all`; nil selects this identity's registered
keys only. It preserves other clients/builds/characters/computers and foreign
fields. Fixed personal use/cast duration, committed receipt, timeout, cooldown,
resources and transport schedule are never adjusted by calibration.

Every bound/weight is centralized in `Calibration.Policy`: schema1, maximum2048
keys,200-character identifiers,1000 retained sample count, EMA weight0.25,
relative adjustment limit0.5 per sample, precision100 (centiseconds), minimum
sample0.05s, loading maximum300s, ride maximum3600s, total interval7200s.
The first sample replaces the fallback. Subsequent changes are clamped relative
to the last measured value before weighting and rounding. A zero legacy loading
estimate is replaced by the first positive observation. No sample history is
retained. Manual loading may be zero; ride must be positive.

## Correlated observations

`Begin({ride=key?,loading=key?},owner,attempt,now)` returns an opaque handle.
`owner` and `attempt` identify the actual execution/segment, not just its goal.
A new Begin rejects any unfinished measurement. The host must call Begin only
after real taxi boarding, scheduled departure, or a committed portal/personal
use. Only ride/loading components with those exact boundaries are measured.
Approach, queue wait, cast/use, boarding and final movement remain separate.

`Loading(handle,owner,attempt,enabled,now)` pairs entry and exit. Relevant native
world-loading events can provide these boundaries while the existing host owns
their subscriptions; initial login/UI reload cancels instead. An entry cannot
be paired with an exit from a different execution. These are observed event
intervals, not a claim about the physical loading-screen duration. No time is
inferred from an isolated PLAYER_ENTERING_WORLD.

`Finish(handle,owner,attempt,now,confirmed)` commits only if the host's real
Actions lifecycle already accepted a trustworthy correlated destination for
this same execution. Loading ends alone never confirm arrival. Ride time is
elapsed minus the sum of completed loading intervals, so loading is charged
once. Portal/personal measure loading only and preserve the configured use time.
All loading observations stay pending until Finish; cancellation rejects them.

Missing, nonfinite or regressed clocks, excessive intervals, unpaired loading,
unconfirmed completion, interruption, replacement, lost correlation and disable
reject the sample. A stale handle/owner/attempt cannot affect a newer interval.
`Cancel()` releases the sole active interval. Runtime handles/clocks are never
serialized, so reload/disconnection cannot complete a pre-reload measurement.

`GetRevision()` advances once per operation only when effective seconds change.
Equal samples, statistics, masked samples and ineffective resets do not advance
it. `GetStats()` returns an isolated accepted/rejected counter snapshot.

## Persistence

The APR adapter exclusively uses
`APRNavigationCharacterSettings.navigationV2Costs`:

```lua
{version=1, profiles={
  Forever={['client-build']={['character-guid']={['installation-name']={
    costs={['taxi/business-route/ride']={
      manualSeconds=12, measuredSeconds=13, samples=4}}
  }}}}
}}
```

`Export(latestNamespace?)` returns a copy on write, preserving all foreign
fields and old references. Reads never repair SavedVariables. Version0 numeric
costs migrate lazily to measured records only for edited keys. Other partitions
and foreign cost entries remain untouched. Unknown future versions are neither
interpreted nor overwritten; Export returns `unsupported_calibration_version`.
Malformed namespace/container values also prevent destructive persistence.
Existing APRSettings, APRNavigationCharacterSettings fields and legacy taxi
durations are left intact and not guessed into a new identity.

## APR adapter and integration

`NavigationV2CalibrationAdapter.Identity(client,build,computer,api?)` reads only
public `UnitGUID('player')`. `Describe(planner,options?)` reads captured catalogues
once, creating loading keys for portal/personal and ride/loading keys for
taxi/scheduled, with existing taxi/settings and scheduled overrides preserved.
`New({store=root,identity,definitions,api?,clock?})` returns a private session.
It forwards Get/GetRevision/GetStats/SetManual/Reset/Cancel. Its Begin adds
`kind,id` instead of the core's key map. Loading and Finish receive the same
handle/owner/attempt; Finish's last arguments are `confirmed,now?` (core uses
`now,confirmed`). Omitted time captures the injected clock or public GetTime.

`Pending()` returns isolated `{kind,id,costs={field=effectiveSeconds}}` updates
grouped by route and only for numerically different effective fields.
`Acknowledge(update)` accepts a successfully applied current update; stale
values are rejected. The host uses the existing solver/setters and coalesces
invalidation/recovery across the batch, retaining Journey visits, objective,
conditions, resources, movement and cooldown observations. Prepared witnesses
must be invalidated by a real cost revision. `Export(latestRoot)` returns a
copy of the root with only its namespace replaced; the host owns assignment to
the existing SavedVariables global at explicit boundaries. Nothing here runs
from Step/GetResult/edge relaxation.

Native GetTime/UnitGUID/secret checks and world events were verified against
installed Forever1.60.1.70707 and Retail12.1.5.70688 sources, with exact hashes
under reports/NAV-19/api-verification.json. Synthetic tests do not establish
physical timing, taint, rendering or trustworthy in-game arrival. Both clients
still require those checks before their navigation engine switch.
