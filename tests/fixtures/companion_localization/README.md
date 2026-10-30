These are recorded `GF_*` TableAdditions exports from the CurseForge export
snapshots dated 2026-10-28. They contain companion UI strings only, never route
content, credentials or runtime locale initialization.

Runtime locale sources deliberately contain packager directives. The offline
test checks those bindings separately and retains its full cross-locale key,
printf, newline and WoW-markup assertions against these exports. It also checks
that statically resolved current `GF_*` references exist in the English export.
Synthetic negative cases prove that each contract still rejects broken data.

When companion keys change, refresh every declared locale from CurseForge; do
not fill missing translations with expected test output. The translation CI job
checks current remote exports. These snapshots cannot certify later translator
edits that have not been exported again. They are excluded from addon packages
with the rest of `tests/`.
