#!/bin/bash

if [ "$#" -lt 3 ]; then
  echo "Użycie: $0 <klucz_tagu> <wartość_tagu> <resource_id> [resource_id ...]"
  echo ""
  echo "Przykład:"
  echo "  $0 env prod /subscriptions/.../res1 /subscriptions/.../res2"
  exit 1
fi

TAG_KEY="$1"
TAG_VALUE="$2"
shift 2

for RESOURCE_ID in "$@"; do
  echo "--- Przetwarzam: $RESOURCE_ID"

  EXISTING=$(az resource show --ids "$RESOURCE_ID" \
    --query "tags.\"${TAG_KEY}\"" --output tsv 2>/dev/null)

  if [[ "$EXISTING" == "$TAG_VALUE" ]]; then
    echo "Tag '${TAG_KEY}=${TAG_VALUE}' już istnieje — pomijam."
  elif [[ -n "$EXISTING" ]]; then
    echo "Tag '${TAG_KEY}' istnieje z wartością '$EXISTING' — nadpisuję na '$TAG_VALUE'."
    az tag update --operation Merge --resource-id "$RESOURCE_ID" --tags "${TAG_KEY}=${TAG_VALUE}"
  else
    echo "Tag '${TAG_KEY}' nie istnieje — dodaję."
    az tag update --operation Merge --resource-id "$RESOURCE_ID" --tags "${TAG_KEY}=${TAG_VALUE}"
  fi
done

echo "=== Zakończono przetwarzanie."