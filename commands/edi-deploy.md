---
name: edi-deploy
description: Build and deploy the EDI parsing pipeline (Openflow NAR or Python UDF lite path)
---

Load the EDI deployment skill to build and wire your parsing pipeline.

## Workflow

1. Detect deployment path preference (Openflow or Python UDF lite)
2. Load `skills/edi-deploy/SKILL.md` for the phased deployment workflow
3. Gates verify: Openflow runtime exists (or skip for lite path)
4. Phases execute: NAR build → upload → flow wiring → network policy verification

## Paths

### Openflow (Primary)
- Builds NAR via `hatch build --target nar`
- Uploads to Openflow extensions
- Wires flow: ListS3 → FetchS3 → SplitContent → ParseX12ToJSON → RouteOnAttribute → PutSnowpipeStreaming

### Python UDF Lite
- Deploys parse_edi() as a Python stored procedure
- Creates RAW_EDI staging table + Snowpipe
- Wires scheduled task to parse raw → typed landing tables
