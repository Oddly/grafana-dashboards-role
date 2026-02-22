#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
AUTH="${GRAFANA_AUTH:-admin:admin}"
EXPECTED=37

echo "=== Full Deployment Verification ==="

# ES datasource
echo -n "ES datasource: "
curl -sf -u "$AUTH" "$GRAFANA_URL/api/datasources/name/Elasticsearch%20data" | jq -r .name

# Folders
echo ""
echo "Folders:"
for folder in linux network security services elasticsearch logstash grafana; do
  echo -n "  $folder: "
  STATUS=$(curl -o /dev/null -s -w "%{http_code}" -u "$AUTH" "$GRAFANA_URL/api/folders/$folder")
  if [ "$STATUS" -eq 200 ]; then
    echo "ok"
  else
    echo "MISSING (status $STATUS)"
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
echo "All checks passed!"
