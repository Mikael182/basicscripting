# Lab 07 — Nazwane parametry (getopts)

## Wymagania

- Ukończony Lab 06 — skrypt `tag.sh` z funkcjami.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Zmiana interfejsu skryptu z parametrów pozycyjnych na nazwane flagi.  
Skrypt będzie przyjmował subskrypcję, grupę zasobów i nazwę zasobu jako osobne flagi, a resource ID będzie rozwiązywane automatycznie przez Azure CLI.

```bash
./tag.sh -s 00000000-0000-0000-0000-000000000000 -g rg-prod -r myVM -t env=prod
```

Czas trwania: 75 minut

## Teoria — getopts

### Składnia

```bash
while getopts "ab:c:" opt; do
  case $opt in
    a) echo "Flaga -a" ;;
    b) echo "Opcja -b z wartością: $OPTARG" ;;
    c) echo "Opcja -c z wartością: $OPTARG" ;;
    *) echo "Nieznana opcja" ;;
  esac
done
```

- Litera bez `:` → flaga bez wartości (np. `-a`)
- Litera z `:` → opcja z wartością (np. `-b wartość`)
- `$OPTARG` → wartość przekazana do opcji
- `*` → obsługa nieznanych opcji

### Typowy wzorzec

```bash
while getopts "s:g:r:h" opt; do
  case $opt in
    s) SUBSCRIPTION="$OPTARG" ;;
    g) RESOURCE_GROUP="$OPTARG" ;;
    r) RESOURCE_NAME="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done
```

### Parsowanie tagu w formacie key=value

```bash
TAG="env=prod"
TAG_KEY="${TAG%%=*}"    # wszystko PRZED pierwszym =  →  env
TAG_VALUE="${TAG#*=}"   # wszystko PO pierwszym =    →  prod
```

## Instrukcje

### Krok 1 — Sprawdź jak az resolves resource ID

Zanim zmodyfikujesz skrypt, przetestuj polecenie `az resource list` z filtrowaniem po nazwie:

```bash
az resource list \
  --subscription "SUBSCRIPTION_ID" \
  --resource-group "NAZWA_GRUPY" \
  --name "NAZWA_ZASOBU" \
  --query "[0].id" \
  --output tsv
```

Powinieneś otrzymać pełne resource ID.

### Krok 2 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 3 — Zastąp skrypt wersją z getopts

Zastąp całą zawartość pliku:

```bash
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
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 4 — Uruchom skrypt

Pobierz ID subskrypcji:

```bash
az account show --query id --output tsv
```

Uruchom skrypt z flagami:

```bash
./tag.sh \
  -s "SUBSCRIPTION_ID" \
  -g "NAZWA_GRUPY_ZASOBÓW" \
  -r "NAZWA_ZASOBU" \
  -t env=prod
```

### Krok 5 — Przetestuj pomoc

```bash
./tag.sh -h
./tag.sh
./tag.sh -s "abc" -g "rg"
```

Każde wywołanie powinno wyświetlić instrukcję użycia.

### Krok 6 — Przetestuj nieistniejący zasób

Podaj nazwę zasobu, który nie istnieje:

```bash
./tag.sh -s "SUBSCRIPTION_ID" -g "NAZWA_GRUPY" -r "zasob-ktory-nie-istnieje" -t env=prod
```

Powinieneś zobaczyć komunikat o błędzie i kod wyjścia `1`.

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.07`.  
> W ostatnim module dodamy pełną obsługę błędów, tryb dry-run i zapis logów do pliku.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 07 ukończony"
```
