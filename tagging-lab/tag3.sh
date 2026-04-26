#!/bin/bash

usage() {
  cat <<EOF
Użycie: $0 [OPCJE]

Opcje:
  -s <subscription_id>   ID subskrypcji (wymagane)
  -g <resource_group>    Nazwa grupy zasobów (wymagane)
  -r <resource_name>     Nazwa zasobu (wymagane)
  -t <key=value>         Tag w formacie klucz=wartość (wymagane)
  -h                     Wyświetl pomoc

Przykład:
  $0 -s 00000000-0000-0000-0000-000000000000 -g rg-prod -r myVM -t env=prod
EOF
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

resolve_resource_id() {
  local subscription="$1"
  local resource_group="$2"
  local resource_name="$3"

  az resource list \
    --subscription "$subscription" \
    --resource-group "$resource_group" \
    --name "$resource_name" \
    --query "[0].id" --output tsv 2>/dev/null
}

main() {
  local subscription=""
  local resource_group=""
  local resource_name=""
  local tag_key=""
  local tag_value=""

  while getopts "s:g:r:t:h" opt; do
    case $opt in
      s) subscription="$OPTARG" ;;
      g) resource_group="$OPTARG" ;;
      r) resource_name="$OPTARG" ;;
      t)
        tag_key="${OPTARG%%=*}"
        tag_value="${OPTARG#*=}"
        ;;
      h) usage ;;
      *) usage ;;
    esac
  done

  if [[ -z "$subscription" || -z "$resource_group" || -z "$resource_name" || -z "$tag_key" || -z "$tag_value" ]]; then
    log "BŁĄD: Wszystkie parametry -s, -g, -r, -t są wymagane."
    usage
  fi

  log "=== Start tagowania ==="
  log "Szukam zasobu '$resource_name' w grupie '$resource_group' (subskrypcja: $subscription)..."

  local resource_id
  resource_id=$(resolve_resource_id "$subscription" "$resource_group" "$resource_name")

  if [[ -z "$resource_id" ]]; then
    log "BŁĄD: Nie znaleziono zasobu '$resource_name' w grupie '$resource_group'."
    exit 1
  fi

  log "Znaleziono: $resource_id"
  process_resource "$resource_id" "$tag_key" "$tag_value"
  log "=== Zakończono."
}

main "$@"