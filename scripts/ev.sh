#!/usr/bin/env bash
set -uo pipefail

if (($# < 3)); then
  echo "Usage: $0 <evidence-file> <step-name> <command...>" >&2
  exit 64
fi

evidence_file=$1
step_name=$2
shift 2
command_text=$*
mkdir -p "$(dirname "$evidence_file")"

{
  printf '\n=== %s ===\n' "$step_name"
  printf 'Exact command: %s\n' "$command_text"
  printf 'Timestamp (UTC): '
  date -u '+%Y-%m-%dT%H:%M:%SZ'
} | tee -a "$evidence_file"

bash -o pipefail -c "$command_text" 2>&1 | tee -a "$evidence_file"
command_status=${PIPESTATUS[0]}
printf 'exit code: %s\n' "$command_status" | tee -a "$evidence_file"
exit "$command_status"
