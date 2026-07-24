---
name: gate-repo
description: Detect or clone the x12-openflow-quickstart backbone repo
parent_skill: edi-extend
gate_id: G2
---

# Gate: Repository Detection

## Purpose
Ensure the user has a local copy of the backbone repo so generated code can be written to the correct locations.

## Steps

1. **Scan workspace** for indicators:
   - `pyproject.toml` with `hatch-datavolo-nar` in build-system requires
   - `src/x12_processors/ParseX12ToJSON.py`
   - `src/x12_processors/field_maps.py`

2. **If found**: Report location, confirm this is the working copy

3. **If not found**: Ask user:
   ```
   I don't see the x12-openflow-quickstart repo in your workspace.
   
   Options:
   A) Clone it now (from https://github.com/sfc-gh-akelkar/x12-openflow-quickstart)
   B) Point me to an existing clone elsewhere
   C) Continue in dry-run mode (I'll output code blocks instead of writing files)
   ```

4. **Set output mode**:
   - Repo found → write mode (default)
   - Option C or user preference → dry-run mode

## Pass Criteria
- Either: backbone repo located in workspace AND output mode = write
- Or: output mode = dry-run (no repo needed)

## Context for Next Gates
Pass the following to subsequent phases:
- `repo_root`: absolute path to backbone repo (or null for dry-run)
- `field_maps_path`: path to `field_maps.py`
- `sql_dir`: path to `sql/` directory
- `tests_dir`: path to `tests/` directory
- `output_mode`: "write" or "dry_run"
