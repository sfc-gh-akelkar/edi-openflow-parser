---
name: edi-extend
description: Add or customize an EDI transaction format with AI-assisted field map generation
---

Load the EDI extension skill to guide you through adding support for a new EDI transaction type.

## Workflow

1. Check `.deployment/manifest.json` for existing deployment state
2. Load `skills/edi-extend/SKILL.md` for the full phased extension workflow
3. Gates verify: Snowflake connection, repo presence, format spec validity
4. Phases generate: field map, landing DDL, Gold DT, test stubs

## Quick Start

Tell me:
- What EDI transaction type you want to add (e.g., "278 Prior Authorization", "820 Payment Order")
- Whether you have an implementation guide (PDF/text) or want AI to infer the field structure
- Whether you prefer write-mode (files written to workspace) or dry-run (code blocks output only)
