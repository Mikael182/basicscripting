#!/bin/bash
set -euo pipefail

LOG_FILE="tag-resources.log"

usage() {
  cat <<EOF
Użycie: $0 [OPCJE]

Opcje:
  -s <subscription_id>   ID subskrypcji (wymagane)
  -g <resource_group>    Nazwa grupy zasobów (wymagane)
  -r <resource_name>     Nazwa zasobu (wymagane)
  -t <key=value>         Tag w formacie klucz=wartość (wymagane)
  -n                     Dry-run (podgląd bez wprowadzania zmian)
  -h                     Wyświetl pomoc

Przykłady:
  $0 -s 00000000-0000-0000-0000-000000000000 -g rg-prod -r myVM -t env=prod
  $0 -s 00000000-0000-0000-0000-000000000000 -g rg-prod -r myVM -t env=prod -n
EOF
  exit 1
}

log() {
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$message"
  echo "$message" >> "$LOG_FILE"
}

log_error() {
  log "BŁĄD: $*" >&2
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
  local dry_run="$4"

  if [[ "$dry_run" == "true" ]]; then
    log "[DRY-RUN] Dodałbym tag '${tag_key}=${tag_value}' do: $resource_id"
    return 0
  fi

  az tag update \
    --operation Merge \
    --resource-id "$resource_id" \
    --tags "${tag_key}=${tag_value}"
}

process_resource() {
  local resource_id="$1"
  local tag_key="$2"
  local tag_value="$3"
  local dry_run="$4"

  log "Przetwarzam: $resource_id"

  local existing
  existing=$(check_tag "$resource_id" "$tag_key")

  if [[ "$existing" == "$tag_value" ]]; then
    log "Tag '${tag_key}=${tag_value}' już istnieje — pomijam."
  elif [[ -n "$existing" ]]; then
    log "Tag '${tag_key}' istnieje z wartością '$existing' — nadpisuję na '$tag_value'."
    apply_tag "$resource_id" "$tag_key" "$tag_value" "$dry_run"
    [[ "$dry_run" != "true" ]] && log "Tag zaktualizowany."
  else
    log "Tag '${tag_key}' nie istnieje — dodaję."
    apply_tag "$resource_id" "$tag_key" "$tag_value" "$dry_run"
    [[ "$dry_run" != "true" ]] && log "Tag dodany."
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

validate_inputs() {
  local subscription="$1"
  local resource_group="$2"
  local resource_name="$3"
  local tag_key="$4"
  local tag_value="$5"

  if [[ -z "$subscription" || -z "$resource_group" || -z "$resource_name" ]]; then
    log_error "Parametry -s, -g i -r są wymagane."
    usage
  fi

  if [[ -z "$tag_key" || -z "$tag_value" ]]; then
    log_error "Parametr -t key=value jest wymagany i musi mieć format klucz=wartość."
    usage
  fi
}

main() {
  local subscription=""
  local resource_group=""
  local resource_name=""
  local tag_key=""
  local tag_value=""
  local dry_run="false"

  while getopts "s:g:r:t:nh" opt; do
    case $opt in
      s) subscription="$OPTARG" ;;
      g) resource_group="$OPTARG" ;;
      r) resource_name="$OPTARG" ;;
      t)
        tag_key="${OPTARG%%=*}"
        tag_value="${OPTARG#*=}"
        ;;
      n) dry_run="true" ;;
      h) usage ;;
      *) usage ;;
    esac
  done

  validate_inputs "$subscription" "$resource_group" "$resource_name" "$tag_key" "$tag_value"

  log "=== Start: tag-resources.sh ==="
  [[ "$dry_run" == "true" ]] && log "[DRY-RUN] Tryb podglądu — żadne zmiany nie zostaną wprowadzone."
  log "subscription=$subscription | rg=$resource_group | resource=$resource_name | tag=${tag_key}=${tag_value}"

  log "Szukam zasobu '$resource_name' w grupie '$resource_group'..."

  local resource_id
  resource_id=$(resolve_resource_id "$subscription" "$resource_group" "$resource_name")

  if [[ -z "$resource_id" ]]; then
    log_error "Nie znaleziono zasobu '$resource_name' w grupie '$resource_group'."
    exit 1
  fi

  log "Znaleziono: $resource_id"
  process_resource "$resource_id" "$tag_key" "$tag_value" "$dry_run"

  log "=== Zakończono. Log zapisany w: $LOG_FILE"
}

trap 'log_error "Nieoczekiwany błąd w linii $LINENO. Sprawdź log: $LOG_FILE"' ERR

main "$@"