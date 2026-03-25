#!/usr/bin/env bash
set -euo pipefail

json_input=$(cat)
filepath=$(echo "$json_input" | jq -r '.tool_input.file_path // empty')

if [[ -z "$filepath" ]]; then
    exit 0
fi

if [[ "$filepath" == *.ts || "$filepath" == *.js || "$filepath" == *.json || "$filepath" == *.cls || "$filepath" == *.trigger ]]; then
    npx prettier --write "$filepath"
fi
