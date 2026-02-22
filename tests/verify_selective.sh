#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
AUTH="${GRAFANA_AUTH:-admin:admin}"
EXPECTED=20  # elasticsearch(11) + linux(9)

echo "=== Selective Deployment Verification ==="

# Folders that SHOULD exist
echo "Expected folders:"
for folder in linux services elasticsearch; do
  echo -n "  $folder: "
  STATUS=$(curl -o /dev/null -s -w "%{http_code}" -u "$AUTH" "$GRAFANA_URL/api/folders/$folder")
  if [ "$STATUS" -eq 200 ]; then
    echo "ok"
  else
    echo "MISSING (status $STATUS)"
    exit 1
  fi
done

# Folders that should NOT exist
echo "Excluded folders:"
for folder in network security logstash grafana; do
  echo -n "  $folder: "
  STATUS=$(curl -o /dev/null -s -w "%{http_code}" -u "$AUTH" "$GRAFANA_URL/api/folders/$folder")
  if [ "$STATUS" -eq 404 ]; then
    echo "correctly absent"
  else
    echo "UNEXPECTED (status $STATUS)"
    exit 1
  fi
done

# Dashboard count
echo ""
TOTAL=$(curl -sf -u "$AUTH" "$GRAFANA_URL/api/search?type=dash-db&limit=100" | jq length)
echo "Dashboards deployed: $TOTAL (expected: $EXPECTED)"

if [ "$TOTAL" -ne "$EXPECTED" ]; then
  echo "FAIL: Expected $EXPECTED dashboards, got $TOTAL"
  echo "Deployed:"
  curl -sf -u "$AUTH" "$GRAFANA_URL/api/search?type=dash-db&limit=100" | jq -r '.[].title' | sort
  exit 1
fi

echo ""
echo "Selective deployment checks passed!"
