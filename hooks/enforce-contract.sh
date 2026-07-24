#!/bin/bash
# enforce-contract.sh — PreToolUse hook for edi-openflow-parser
# Blocks operations that violate the execution contract

INPUT="$1"

# Block direct CREATE TABLE outside prescribed schemas
if echo "$INPUT" | grep -qi "CREATE.*TABLE" && ! echo "$INPUT" | grep -qi "only_compile"; then
  if ! echo "$INPUT" | grep -qi "CLAIMS\|ENROLLMENTS\|REMITTANCES\|GOLD\|RAW_EDI"; then
    echo "BLOCKED: CREATE TABLE must target prescribed schemas (CLAIMS, ENROLLMENTS, REMITTANCES, GOLD, or RAW_EDI). Update config/edi_format_specs.yaml instead."
    exit 1
  fi
fi

# Block PutSnowpipeStreaming2 references
if echo "$INPUT" | grep -qi "PutSnowpipeStreaming2"; then
  echo "BLOCKED: Use PutSnowpipeStreaming v1 (Record Reader + Table target), not PutSnowpipeStreaming2."
  exit 1
fi

# Block manual NAR packaging
if echo "$INPUT" | grep -qi "zip.*\.nar\|jar.*\.nar"; then
  echo "BLOCKED: Use 'hatch build --target nar' for NAR packaging. Never manual zip/jar."
  exit 1
fi

# Block network policy changes without the network phase
if echo "$INPUT" | grep -qi "ALTER.*NETWORK.*POLICY\|CREATE.*NETWORK.*POLICY"; then
  echo "BLOCKED: Network policy changes must go through the edi-deploy network verification phase. Run /edi:deploy first."
  exit 1
fi

exit 0
