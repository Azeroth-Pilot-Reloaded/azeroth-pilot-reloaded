# Conditions and observed access

This module is pure Lua 5.1. It owns compiled conjunctions and their cached
tri-valued results, not localization, time/cooldowns, routing or output.

An optional `requirements` record has these fields:

```lua
{
    world = 0, space = 'hall', floor = 'upper', phase = 'after-event',
    quests = {{questID = 123, completed = true}},
    access = {{key = 'gate-open', allowed = true}},
}
```

Every field is optional. Quest completion is character completion. Access keys
name business facts whose proof belongs to the caller; they are not evaluated
scripts. False requirements such as `completed=false` and `allowed=false` are
supported. A missing observation never satisfies a false requirement.

Use the same shape on zones, nodes, passages and transports. A usable traversal
must satisfy every applicable zone/endpoint/passage/transport requirement and
its other static/dynamic access checks. An explicit false conjunct beats an
unknown conjunct; only all true conjuncts give available. Static witnesses,
precomputed shortcuts and heuristics cannot bypass these checks. Conditional
graphs must disable optimizations whose validity is not proven for that state.

`world` is a nonnegative native world ID; space/floor/phase are nonempty strings
or nonnegative exact integers. These are proven identities, never values
deduced from UiMap, coordinate proximity, floor height, loading or arrival.
The caller must give trusted evidence with an explicit lifetime and revoke it
when its supporting observation changes. No default phase exists.

## API

- `Compile(requirements)` returns an opaque compiled handle or
  `nil,'invalid_conditions'`. Nil means an empty conjunction. The compiler
  rejects unknown fields, sparse arrays, duplicates, nonboolean expectations,
  invalid identities and more than `MAX_FACTS=64` facts per declaration. It
  captures the input once; subsequent edits do not mutate the compiled value.
- `New()` creates an independent tracker. `tracker:Track(compiled)` registers a
  binding during bounded declaration preparation. `tracker:Get(binding)` is a
  cached `available|unavailable|unknown,reason` lookup. An unrecognized binding
  returns `nil,'invalid_condition_binding'`. Empty conjunctions share one
  unconditional binding. No native calls, graph walk or fact evaluation occurs
  in Get, job Step or GetResult.
- `tracker:Dependencies()` returns independent sets `{quests,access,identity}`
  of required IDs/keys, for capture and event subscriptions. New dependencies
  added by bounded graph/catalog preparation require a fresh capture before
  their evidence can be used. Track does not invent missing evidence.
- `tracker:Observe(observation)` accepts a full snapshot
  `{sequence,worldState,quests,access,world,space,floor,phase}`. Quest/access maps
  hold boolean values; absent keys are unknown. `worldState` must be
  `ready|loading|unknown`. Loading/unknown cannot authorize conditional access,
  even if the snapshot also includes old facts. Omitted facts replace old
  evidence. Invalid input returns `nil,'invalid_condition_observation'`
  atomically; a stale sequence returns `false,'stale_observation'` without
  clearing dirty state.
- Accepted Observe returns `effectiveChanged,nil,recovered`, where the first
  boolean reports changed cached availability and the third reports a freshly
  resolved dirty burst. **An identical fresh capture after dirty is a useful
  recovery**: old jobs stay stale, a new token is usable, and the host can
  resume the retained objective once at a consumption boundary. A subsequent
  identical capture reports false/false and must not start another search.
  Changed unknown reasons alone do not restart planning.
- `tracker:MarkDirty(dependencies)` intersects dependency sets with its index,
  marks only affected bindings pending/unknown, and returns true once per burst
  to request immediate job/result/output invalidation. Other events in that
  burst can add affected bindings but return false. Unobserved dependencies
  return false. The handler reads no native API and evaluates no conjunction.
  It also revokes each requested fact in its private snapshot. A binding added
  in a later bounded preparation slice therefore sees unknown for that fact,
  until a fresh capture restores proof; unconditional declarations stay usable.
- `tracker:GetToken()/IsCurrent(token)` protect asynchronous jobs and results.
  Tokens have tracker identity and monotone revision; every semantic change or
  initial dirty event retires older tokens. While dirty, no token authorizes
  consumption. Observing unchanged data does not revive an older token.

Only the tracker mutates its internal bindings/snapshot. Native observer state
is not shared; API handles and dependency sets are copies. The tracker is
discarded on replacement of the planner/catalog. Storage is bounded by
`MAX_BINDINGS=4096` and `MAX_DEPENDENCIES=4096` distinct required facts; exceeding
either returns `nil,'condition_capacity_exceeded'` without partial mutation.
Each observation map is capped at 4096 entries. Observe compares the indexed
facts once and evaluates only affected/pending bindings, plus all conditional
bindings when world readiness changes. No condition/API scan runs per edge.

## Native adapter and host seam

`ns.NavigationV2ConditionsAdapter` is stateless. Its
`Capture(api,deps,sequence,worldState,identity,access)` queries only needed
`C_QuestLog.IsQuestFlaggedCompleted(questID)` results. Nil/missing/error/secret or
nonboolean results remain unknown. The adapter reads no quests when worldState
is not ready. Location/access evidence is explicit trusted caller data, with
the same public-value guards; the adapter never calls UnitPhaseReason or a map
API to manufacture identity. It creates no frame, timer, output or action.

`Events(deps)` returns only required quest/phase event names. `Affected(event,payload,
deps,api)` returns dirty dependencies or nil. QUEST_LOG_UPDATE has no
payload, so all tracked quests are affected; a public QUEST_TURNED_IN ID scopes
the change. A restricted/missing ID conservatively affects all tracked quests.
UNIT_PHASE invalidates required phase evidence for the player (or a restricted
unit payload). It carries no replacement identity: the host must revoke the old
identity and obtain new explicit proof, never recapture its stale identity.
Other public unit tokens are irrelevant.
The existing host observer owns registration/teardown and world/phase/access
proof invalidation. Event receipt is not completion or compatible identity.

On an event, mark affected evidence dirty and immediately invalidate old
jobs/results/actions and remove only the library-owned output. Capture once at
the next useful explicit planning/consumption boundary, then resume a retained
objective if `effectiveChanged or recovered`, with current confirmed origin
and mandatory visits. Do not reuse the previous result/action/token. Never
reseed an unconfirmed origin or infer arrival from loading. Unchanged unknown
needs new evidence, not polling. The same native event owner retains NAV15's
subscribe-then-probe bootstrap only for Enable/real subscription gaps; this
adapter neither queries readiness nor overwrites observed loading.

No text here is user-visible. Runtime reasons are technical coordinate-free
codes. Host translations keep the repository's GlobalStrings/CurseForge order;
the library remains owner of WUI/AWP and their coordinate-free labels.

## Verification limits

Native source definitions were read from installed Forever 1.60.1.70707 and
Retail 12.1.5.70688 archives, after Context7 documentation lookup. Hashes and
exact definitions are recorded in reports/NAV-16/api-proof.json and
api-evidence.md. They establish the API contract, not physical phase/access
behavior in game. No globally unique public phase identity is claimed.
Native quest loading/timing, phase/access evidence, event ordering, WUI/AWP
ownership/rendering, combat/taint and real movement remain to be checked on
both clients before switching engines. V1 stays the default.
