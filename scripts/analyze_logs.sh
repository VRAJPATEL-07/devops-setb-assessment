#!/usr/bin/env bash
set -euo pipefail

if (($# == 0)); then
  echo "Usage: $0 <log-file>" >&2
  exit 1
fi

log_file=$1
if [[ ! -f "$log_file" ]]; then
  echo "Error: file not found: $log_file" >&2
  exit 2
fi

total=$(wc -l < "$log_file")
count_4xx=$(awk '$2 >= 400 && $2 < 500 { count++ } END { print count+0 }' "$log_file")
count_5xx=$(awk '$2 >= 500 && $2 < 600 { count++ } END { print count+0 }' "$log_file")
rate=$(awk -v errors="$count_5xx" -v total="$total" 'BEGIN {
  if (total == 0) {
    print "0.00"
  } else {
    printf "%.2f", errors * 100 / total
  }
}')

printf 'Total requests: %s\n' "$total"
printf 'HTTP 4xx: %s\n' "$count_4xx"
printf 'HTTP 5xx: %s\n' "$count_5xx"
printf '5xx rate: %s%%\n' "$rate"
printf 'Top 3 routes:\n'
awk '{print $4}' "$log_file" | sort | uniq -c | sort -rn | head -3
