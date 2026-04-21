# Lab 08 — Obsługa błędów i finalna wersja skryptu

## Wymagania

- Ukończony Lab 07 — skrypt `tag.sh` z getopts i resolve_resource_id.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Dodanie profesjonalnej obsługi błędów, trybu dry-run i zapisu logów do pliku.  
Po tym module skrypt jest gotowy do użycia produkcyjnego.

Czas trwania: 60 minut

## Teoria — obsługa błędów

### set -euo pipefail

Umieszczone na początku skryptu:

```bash
set -euo pipefail
```

| Flaga | Działanie |
|-------|-----------|
| `-e` | Zatrzymaj skrypt przy pierwszym błędzie (niezerowy kod wyjścia) |
| `-u` | Traktuj niezdefiniowane zmienne jako błąd |
| `-o pipefail` | Potok `cmd1 | cmd2` kończy błędem jeśli którekolwiek polecenie się nie powiedzie |

### trap — przechwytywanie sygnałów i błędów

```bash
trap 'echo "Błąd w linii $LINENO"' ERR
trap 'echo "Skrypt przerwany"' INT TERM
```

- `ERR` — wyzwalany przy każdym błędzie (gdy `-e` jest aktywne)
- `INT` — wyzwalany przez Ctrl+C
- `$LINENO` — numer linii gdzie wystąpił błąd

### Przekierowanie stderr do pliku

```bash
log_error() {
  local message="[$(date '+%Y-%m-%d %H:%M:%S')] BŁĄD: $*"
  echo "$message" >&2           # na stderr
  echo "$message" >> "$LOG_FILE" # do pliku
}
```

> `>&2` — przekierowanie do stderr (standardowego strumienia błędów)

### Tryb dry-run

Wzorzec używany w wielu narzędziach CLI:

```bash
if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY-RUN] Wywołałbym: az tag update ..."
  return 0
fi
# rzeczywiste polecenie
az tag update ...
```

## Instrukcje

### Krok 1 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 2 — Zastąp skrypt finalną wersją

Zastąp całą zawartość pliku:

```bash
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
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 3 — Przetestuj dry-run

```bash
./tag.sh \
  -s "SUBSCRIPTION_ID" \
  -g "NAZWA_GRUPY_ZASOBÓW" \
  -r "NAZWA_ZASOBU" \
  -t env=prod \
  -n
```

Powinieneś zobaczyć co skrypt *zrobiłby* — bez żadnych zmian w Azure.

### Krok 4 — Uruchom właściwe tagowanie

```bash
./tag.sh \
  -s "SUBSCRIPTION_ID" \
  -g "NAZWA_GRUPY_ZASOBÓW" \
  -r "NAZWA_ZASOBU" \
  -t env=prod
```

### Krok 5 — Sprawdź plik logu

```bash
cat tag-resources.log
```

Każde uruchomienie dopisuje wpisy do tego samego pliku — masz pełną historię operacji.

### Krok 6 — Przetestuj set -u (niezdefiniowana zmienna)

```bash
bash -c 'set -u; echo "$NIEZDEFINIOWANA"'
```

Powinieneś zobaczyć błąd. Porównaj z:

```bash
bash -c 'echo "$NIEZDEFINIOWANA"'
```

Bez `set -u` bash nie zgłasza błędu — to częste źródło trudnych do znalezienia bugów.

### Krok 7 — Przetestuj trap ERR

Stwórz testowy skrypt, który wywołuje błąd:

```bash
cat <<'EOF' > test-trap.sh
#!/bin/bash
set -e
trap 'echo "Błąd w linii $LINENO!"' ERR
echo "Przed błędem"
nieistniejace-polecenie
echo "Ta linia się nie wykona"
EOF
bash test-trap.sh
```

### Krok 8 — Pełny test scenariuszy

```bash
# 1. Brak wymaganych parametrów
./tag.sh -s "SUBSCRIPTION_ID"

# 2. Nieistniejący zasób
./tag.sh -s "SUBSCRIPTION_ID" -g "NAZWA_GRUPY" -r "nie-istnieje" -t env=prod

# 3. Dry-run na istniejącym zasobie
./tag.sh -s "SUBSCRIPTION_ID" -g "NAZWA_GRUPY" -r "NAZWA_ZASOBU" -t env=prod -n

# 4. Dodanie nowego tagu
./tag.sh -s "SUBSCRIPTION_ID" -g "NAZWA_GRUPY" -r "NAZWA_ZASOBU" -t owner=jan.kowalski

# 5. Tag już istnieje
./tag.sh -s "SUBSCRIPTION_ID" -g "NAZWA_GRUPY" -r "NAZWA_ZASOBU" -t owner=jan.kowalski
```

### Krok 9 — Zweryfikuj końcowy stan tagów

```bash
az resource show \
  --ids "PEŁNE_ID_ZASOBU" \
  --query tags \
  --output json
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.08`.

## Podsumowanie kursu

Skrypt ewoluował przez 8 modułów:

| Moduł | Dodana funkcjonalność |
|-------|-----------------------|
| 01 | Hardcoded `az tag update` |
| 02 | Zmienne — łatwiejsza modyfikacja |
| 03 | Parametry pozycyjne `$1 $2 $3` |
| 04 | Warunki `if/elif/else` — sprawdzenie istniejącego tagu |
| 05 | Pętla `for` — wiele zasobów naraz |
| 06 | Funkcje — czytelna struktura kodu |
| 07 | `getopts` — nazwane flagi `-s -g -r -t` |
| 08 | `set -euo pipefail`, `trap`, dry-run, log do pliku |

**Kolejny krok:** Lab 09 — obsługa pliku CSV z listą zasobów do zbiorczego tagowania.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 08 ukończony"
```
