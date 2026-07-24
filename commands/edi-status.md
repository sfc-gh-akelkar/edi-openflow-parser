---
name: edi-status
description: Check EDI pipeline health, DT refresh status, and error counts
---

Load the EDI status skill to check your pipeline health.

## What It Checks

1. **Dynamic Table refresh status** — lag, last refresh time, errors
2. **Snowpipe Streaming channels** — offset lag, error counts
3. **Landing table row counts** — per transaction type
4. **Gold layer enrichment** — AI function call success/failure rates
5. **Openflow flow status** — if Openflow API is accessible

## Usage

Just ask: "How is my EDI pipeline doing?" or "Show me pipeline status"
