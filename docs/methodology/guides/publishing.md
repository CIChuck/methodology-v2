curl -sS -X PUT https://here.nowdistant-steeple-gn9z/primary-domain \
  -H "Authorization: Bearer ${HERE_NOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"domain": "gendevdocs.gendevx.com"}'


curl -sS -X PUT https://here.now/api/v1/publish/distant-steeple-gn9z/primary-domain \
  -H "Authorization: Bearer ${HERE_NOW_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{"domain": "gendevx.com"}'

