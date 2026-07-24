# EDI Openflow Parser

A CoCo plugin that guides healthcare (and other industry) customers through building and extending EDI parsing pipelines on Snowflake.

## Overview

This plugin provides:
- **7 pre-built X12 HIPAA transaction types** (834, 835, 837, 270/271, 276/277)
- **AI-assisted extension** for any new EDI format — describe what you need, the skill generates everything
- **Two deployment paths**: Openflow streaming (production) or Python UDF (PoC/lightweight)
- **Gold layer AI enrichment** via Cortex AI (ICD-10 decoding, procedure classification, etc.)

## Install

```bash
cortex plugin install sfc-gh-akelkar/edi-openflow-parser
```

Or find it in the **HCLS Industry Skills** profile in Cortex Code.

## Prerequisites

| Requirement | Path |
|---|---|
| Snowflake account with Cortex AI | Both paths |
| Openflow runtime (Medium+) | Openflow path only |
| Warehouse (MEDIUM recommended) | Both paths |
| S3 or SFTP source with EDI files | Openflow path |
| Internal stage with EDI files | Python UDF path |

## Quick Start

### Step 1: Install and Activate

After installation, the plugin activates automatically. You'll see three new slash commands:
- `/edi:extend` — Add support for a new EDI transaction type
- `/edi:deploy` — Build and deploy the parsing pipeline  
- `/edi:status` — Check pipeline health

### Step 2: Extend (Add a Transaction Type)

```
You: /edi:extend

Plugin: What EDI transaction type do you want to add?

You: X12 278 — Prior Authorization

Plugin: [Runs gates: verifies connection, detects repo, gathers format spec]
        [Runs phases: generates field map, landing DDL, Gold DT, tests]
        [Writes files to your workspace or outputs code blocks]
```

The skill walks you through interactively:
1. **Gate 1**: Verifies your Snowflake connection and target database
2. **Gate 2**: Detects your fork of the backbone repo (or switches to output-only mode)
3. **Gate 3**: Gathers the format specification — from an implementation guide, AI inference, or your manual input
4. **Phase 1**: Generates `field_maps.py` entry with segment-to-field mappings
5. **Phase 2**: Generates typed landing table DDL (all VARCHAR for Snowpipe Streaming compatibility)
6. **Phase 3**: Generates Gold Dynamic Table with type casting and optional AI enrichment
7. **Phase 4**: Generates pytest stubs and sample EDI data

Each phase requires your approval before proceeding.

### Step 3: Deploy

```
You: /edi:deploy

Plugin: Which deployment path?
        A) Openflow (streaming, production)
        B) Python UDF Lite (batch, no Openflow needed)
```

**Openflow path** builds the NiFi NAR, uploads it, and wires the flow:
```
S3 → ListS3 → FetchS3 → SplitContent → ParseX12ToJSON → RouteOnAttribute → PutSnowpipeStreaming
```

**Python UDF path** deploys a stored procedure + scheduled task:
```
Stage → Snowpipe → RAW_EDI → Task (5 min) → parse_edi() proc → Typed Tables
```

### Step 4: Monitor

```
You: /edi:status

Plugin: EDI Pipeline Status
        =====================
        Landing Tables:
          CLAIMS.LANDING_837_CLAIMS       | 1,234,567 rows | Lag: 3 min
          ENROLLMENTS.LANDING_834_ENROLL  |   456,789 rows | Lag: 7 min
        
        Gold Dynamic Tables:
          GOLD.GOLD_CLAIMS                | ACTIVE | Last refresh: SUCCESS
        
        Errors (last 24h): 0
```

## Architecture

```
Source (S3/SFTP/Stage)
    │
    ├─── Openflow Path (streaming/production) ────────────────────────────┐
    │    ListS3 → FetchS3 → SplitContent(ST*) → ParseX12ToJSON (NAR)    │
    │    → RouteOnAttribute → PutSnowpipeStreaming × N typed tables       │
    │                                                                     │
    ├─── Python UDF Lite Path (PoC/lightweight) ──────────────────────────┐
    │    Snowpipe → RAW_EDI table → Scheduled Task → parse_edi() proc    │
    │    → Typed Landing Tables                                           │
    │                                                                     │
    └─── Snowflake ───────────────────────────────────────────────────────┘
         Landing Tables (VARCHAR, per tx type)
              │
              ▼
         Gold Dynamic Tables (type casting + Cortex AI enrichment)
```

## Pre-Built Transaction Types

| Code | Name | Boundary Segment | Industry |
|------|------|-----------------|----------|
| 837 | Health Care Claim | CLM | Healthcare |
| 835 | Claim Payment/Remittance | CLP | Healthcare |
| 834 | Benefit Enrollment | INS | Healthcare |
| 270 | Eligibility Inquiry | HL | Healthcare |
| 271 | Eligibility Response | HL | Healthcare |
| 276 | Claim Status Request | HL | Healthcare |
| 277 | Claim Status Response | HL | Healthcare |

## Adding Your Own Format

The plugin is **config-driven**. Transaction types are defined in `config/x12_known_types.yaml`. Each entry specifies:
- Record boundary segment (what delimits individual records)
- Qualifier-aware field mappings (e.g., `NM1_85` = billing provider)
- Landing schema and table names
- Gold layer enrichment strategy

You can add formats manually by editing the YAML, or use `/edi:extend` for the guided AI-assisted workflow.

## Output Modes

| Mode | When | Behavior |
|------|------|----------|
| **Write** | Backbone repo detected in workspace | Files written directly to your repo |
| **Dry-run** | No repo detected, or user preference | Code blocks output for manual copy |

## Competitive Positioning

| Capability | This Plugin | Databricks |
|---|---|---|
| Pre-built parsers | 7 X12 types | 2 (837, 835) |
| Extensibility | Skill-guided, AI-assisted | Manual Python |
| Streaming | Openflow + Snowpipe Streaming | Spark Streaming |
| AI enrichment | Cortex AI in Gold DTs | Manual LLM |
| Agentic workflow | CoCo plugin + guided extension | None |
| Format families | X12 now, EDIFACT/flat ready | X12 only |

## Parsing Engine

The X12 parsing engine is bundled in `src/x12_processors/`:
- `ParseX12ToJSON.py` — NiFi FlowFileTransform processor (also usable standalone)
- `field_maps.py` — Qualifier-aware segment-to-field mappings for all supported types

Build the NAR (for Openflow deployment):
```bash
pip install hatch hatch-datavolo-nar
hatch build --target nar
```

Run tests:
```bash
pip install -e ".[dev]"
pytest tests/ -v
```

## Plugin Structure

```
edi-openflow-parser/
├── .cortex-plugin/          # Plugin manifest, execution contract, hooks
├── src/x12_processors/      # Parsing engine (bundled)
│   ├── ParseX12ToJSON.py    # NiFi Python processor
│   └── field_maps.py        # Segment-to-field mappings
├── sql/                     # Infrastructure DDL (landing tables, Gold DTs)
├── data/                    # Sample EDI files
├── commands/                # Slash command definitions (/edi:extend, etc.)
├── config/                  # Format specs and pre-built type definitions
├── hooks/                   # PreToolUse enforcement (blocks unsafe DDL)
├── reference/               # X12 segment reference, competitive positioning
├── scripts/                 # Health check SQL
├── skills/                  # Router + sub-skills (extend, deploy, status)
│   ├── edi-router/          # Intent routing
│   ├── edi-extend/          # Gates → Phases for adding formats
│   ├── edi-deploy/          # NAR build + Openflow wiring (or UDF lite)
│   └── edi-status/          # Pipeline health monitoring
├── tests/                   # Unit tests + sample data + demo walkthroughs
└── pyproject.toml           # NAR build config (hatch-datavolo-nar)
```

## License

BSD-3-Clause
