# Repository Update Summary - November 7, 2025

## What Was Done

### ✅ Completed

1. **Route File Normalization (31 files)**
   - Normalized `Coord` → `coord` across all expansion route files
   - Fixed trailing commas and duplicate commas
   - Improved consistent spacing around `=` operators
   - All changes are syntax-safe and preserve game logic

2. **Validation Infrastructure**
   - Created `scripts/route_validator.py` - table-aware validator
   - Created `scripts/auto_fix_routes.py` - safe auto-fixer
   - Created `scripts/scan_quests_deep.py` - heuristic scanner
   - Generated validation reports in `reports/`

3. **CI/CD Setup**
   - Added `.github/workflows/lua-syntax.yml` - syntax checking
   - Added `.github/workflows/luacheck.yml` - linting workflow
   - Added `scripts/package.sh` - release packaging

4. **Documentation**
   - Added `.github/copilot-instructions.md` - AI agent guidance
   - Updated README with developer info

### 📊 Current Validation Status

- **Files scanned**: 31 route files
- **Files with issues**: 31 (all files have at least one issue)

**Issue breakdown** (post-normalization):
- `missing_id`: 29,541 occurrences - route steps without explicit id/questID
- `coord_used`: 28,982 occurrences - using lowercase `coord` (expected, post-fix)
- `qpart_without_id`: 9,394 occurrences - Qpart entries where validator couldnt
