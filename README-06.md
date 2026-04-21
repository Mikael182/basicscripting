# Lab 06 — Funkcje

## Wymagania

- Ukończony Lab 05 — skrypt `tag.sh` z pętlą for i obsługą wielu zasobów.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Refaktoryzacja skryptu przez wydzielenie logiki do osobnych funkcji. Skrypt robi dokładnie to samo co po Lab 05, ale kod jest czytelniejszy, łatwiejszy do testowania i gotowy na dalszą rozbudowę.

Czas trwania: 60 minut

## Teoria — funkcje w Bash

### Deklaracja i wywołanie

```bash
przywitaj() {
  echo "Cześć, $1!"
}

przywitaj "Jan"   # wypisuje: Cześć, Jan!
```

### Zmienne lokalne

Bez słowa `local` zmienne wewnątrz funkcji są globalne — mogą niechcący nadpisać inne zmienne:

```bash
suma() {
  local a="$1"
  local b="$2"
  echo $((a + b))
}
```

### Zwracanie wartości

Funkcje w Bash zwracają **kod wyjścia** (0–255) przez `return`, nie wartości.  
Aby "zwrócić" tekst, używamy `echo` i podstawiania komend:

```bash
pobierz_wartosc() {
  echo "wynik"
}

WYNIK=$(pobierz_wartosc)
echo "$WYNIK"   # wypisuje: wynik
```

### Kod wyjścia funkcji

```bash
sprawdz() {
  if [[ "$1" == "ok" ]]; then
    return 0   # sukces
  else
    return 1   # błąd
  fi
}

if sprawdz "ok"; then
  echo "Sukces"
fi
```

## Instrukcje

### Krok 1 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 2 — Zastąp skrypt wersją z funkcjami

Zastąp całą zawartość pliku:

```bash
#!/bin/bash

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
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 3 — Przeanalizuj strukturę

Skrypt zawiera teraz 5 funkcji:

| Funkcja | Odpowiedzialność |
|---------|-----------------|
| `usage` | Wyświetla instrukcję użycia i kończy skrypt |
| `log` | Wypisuje wiadomość z aktualnym czasem |
| `check_tag` | Sprawdza bieżącą wartość tagu na zasobie |
| `apply_tag` | Wywołuje `az tag update` |
| `process_resource` | Łączy `check_tag` i `apply_tag` z logiką warunkową |
| `main` | Wejście do skryptu, parsuje argumenty, wywołuje pętlę |

> Ostatnia linia `main "$@"` uruchamia funkcję `main` i przekazuje do niej wszystkie argumenty skryptu.

### Krok 4 — Uruchom skrypt

```bash
./tag.sh env staging "ID_ZASOBU_1" "ID_ZASOBU_2"
```

Zwróć uwagę na format timestampów z funkcji `log`.

### Krok 5 — Przetestuj wywołanie bez argumentów

```bash
./tag.sh
```

Powinieneś zobaczyć wynik funkcji `usage`.

### Krok 6 — Ćwiczenie: dodaj funkcję validate_resource

Dodaj do skryptu funkcję, która sprawdza czy zasób w ogóle istnieje przed próbą tagowania.  
Wstaw ją w `process_resource` przed wywołaniem `check_tag`:

```bash
validate_resource() {
  local resource_id="$1"
  az resource show --ids "$resource_id" --query id --output tsv 2>/dev/null
}
```

W `process_resource` użyj jej w ten sposób:

```bash
if [[ -z $(validate_resource "$resource_id") ]]; then
  log "OSTRZEŻENIE: Zasób '$resource_id' nie istnieje — pomijam."
  return
fi
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.06`.  
> W następnym module zmienimy interfejs skryptu na nazwane flagi: `-s`, `-g`, `-r`, `-t`.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 06 ukończony"
```
