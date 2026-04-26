usage() {
  echo "Użycie: $0 <klucz_tagu> <wartość_tagu> <resource_id> [resource_id ...]"
  echo ""
  echo "Przykład:"
  echo "  $0 env prod /subscriptions/.../res1 /subscriptions/.../res2"
  exit 1
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

check_tag() {
  local resource_id="$1"
  local tag_key="$2"

  az resource show --ids "$resource_id" \
    --query "tags.\"${tag_key}\"" --output tsv 2>/dev/null
}

apply_tag() {
  local resource_id="$1"
  local tag_key="$2"
  local tag_value="$3"

  az tag update \
    --operation Merge \
    --resource-id "$resource_id" \
    --tags "${tag_key}=${tag_value}"
}

process_resource() {
  local resource_id="$1"
  local tag_key="$2"
  local tag_value="$3"

  log "Przetwarzam: $resource_id"

  local existing
  existing=$(check_tag "$resource_id" "$tag_key")

  if [[ "$existing" == "$tag_value" ]]; then
    log "Tag '${tag_key}=${tag_value}' już istnieje — pomijam."
  elif [[ -n "$existing" ]]; then
    log "Tag '${tag_key}' istnieje z wartością '$existing' — nadpisuję na '$tag_value'."
    apply_tag "$resource_id" "$tag_key" "$tag_value"
    log "Tag zaktualizowany."
  else
    log "Tag '${tag_key}' nie istnieje — dodaję."
    apply_tag "$resource_id" "$tag_key" "$tag_value"
    log "Tag dodany."
  fi
}

main() {
  if [ "$#" -lt 3 ]; then
    usage
  fi

  local tag_key="$1"
  local tag_value="$2"
  shift 2

  log "=== Start tagowania ==="
  log "Tag: ${tag_key}=${tag_value} | Liczba zasobów: $#"

  for resource_id in "$@"; do
    process_resource "$resource_id" "$tag_key" "$tag_value"
  done

  log "=== Zakończono przetwarzanie."
}

main "$@"