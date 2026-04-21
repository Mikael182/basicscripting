# Lab 09 — Obsługa pliku CSV

## Wymagania

- Ukończony Lab 08 — skrypt `tag.sh` z obsługą błędów, dry-run i logowaniem.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.
- Co najmniej dwa zasoby w Azure do przetestowania zbiorczego tagowania.

## Wstęp

### Cel

Zastąpienie ręcznego podawania zasobu flagami `-g -r -t` obsługą pliku CSV — skrypt przetworzy dowolną liczbę zasobów z jednego pliku wejściowego.

```bash
./tag.sh -s "SUBSCRIPTION_ID" -f resources.csv
./tag.sh -s "SUBSCRIPTION_ID" -f resources.csv -n   # dry-run
```

Czas trwania: 60 minut

## Teoria — czytanie pliku CSV w bash

### IFS — separator pól

`IFS` (*Internal Field Separator*) to zmienna bash określająca znaki traktowane jako separatory przy podziale słów. Domyślna wartość to spacja + tabulator + nowa linia.

```bash
echo "$IFS" | cat -A   # wyświetl znaki specjalne
```

Tymczasową zmianę IFS stosuje się najczęściej razem z `read`:

```bash
IFS=, read -r pole1 pole2 pole3 <<< "alfa,beta,gamma"
echo "$pole1"   # alfa
echo "$pole2"   # beta
echo "$pole3"   # gamma
```

> Przypisanie `IFS=,` przed `read` obowiązuje tylko dla tego jednego polecenia — nie zmienia globalnej wartości IFS w skrypcie.

### while read -r — czytanie pliku linia po linii

```bash
while read -r linia; do
  echo "Linia: $linia"
done < plik.txt
```

- `< plik.txt` — przekierowanie pliku jako standardowego wejścia pętli
- `-r` — wyłącza interpretację sekwencji `\` (raw mode); zawsze używaj `-r`

### while IFS=, read -r — parsowanie CSV

Połączenie `IFS=,` z `read -r` dzieli każdą linię po przecinkach:

```bash
while IFS=, read -r resource_group resource_name tag_key tag_value; do
  echo "Grupa: $resource_group"
  echo "Zasób: $resource_name"
  echo "Tag:   ${tag_key}=${tag_value}"
done < resources.csv
```

Jeśli w wierszu jest więcej pól niż zmiennych, nadmiar trafia do ostatniej zmiennej.  
Jeśli jest mniej pól, brakujące zmienne mają wartość pustą.

### Pomijanie nagłówka i pustych linii

```bash
line_num=0

while IFS=, read -r col1 col2; do
  (( line_num += 1 ))
  [[ $line_num -eq 1 ]] && continue   # pomiń wiersz nagłówka
  [[ -z "$col1" ]] && continue        # pomiń puste linie
  [[ "$col1" == \#* ]] && continue    # pomiń komentarze
  # ... przetwarzaj dane
done < plik.csv
```

- `continue` — przechodzi od razu do następnej iteracji pętli

### Pliki CSV z Windows — problem z \r

Pliki CSV zapisane na Windows używają sekwencji `\r\n` (CRLF) zamiast `\n` (LF). Bash rozpoznaje `\n`, ale nie usuwa `\r`, który pozostaje na końcu ostatniego pola:

```bash
# Bez usuwania \r:
tag_value="prod\r"   # niewidoczny znak, ale psuje porównania

# Rozwiązanie — usuwanie \r z końca ostatniego pola:
tag_value="${tag_value%$'\r'}"
```

`${zmienna%wzorzec}` usuwa najkrótsze dopasowanie wzorca z **końca** wartości.

### Arytmetyka w bash

| Składnia | Opis | Przykład |
|----------|------|---------|
| `$(( wyraż ))` | Podstawianie arytmetyczne — zwraca wartość | `x=$(( 3 + 2 ))` |
| `(( wyraż ))` | Polecenie arytmetyczne — ustawia kod wyjścia | `(( x += 1 ))` |

Z `set -e` bezpieczniej używać `+= 1` niż `++`, bo `(( x++ ))` zwraca kod 1 gdy `x=0` (wynik wyrażenia to 0 = fałsz):

```bash
count=0
(( count += 1 ))   # bezpieczne: 0+1=1, kod wyjścia 0
(( count++ ))      # ryzykowne przy count=0: wynik=0, kod wyjścia 1 → set -e zatrzyma skrypt
```

### Obsługa błędów w pętli CSV

Z `set -e` błąd w pętli zatrzymałby cały skrypt. Aby zliczyć błędy i kontynuować dla pozostałych wierszy, używamy `if`:

```bash
if process_resource "$resource_id" "$tag_key" "$tag_value" "$dry_run"; then
  (( count_ok += 1 ))
else
  log_error "Błąd podczas tagowania $resource_name."
  (( count_err += 1 ))
fi
```

Warunek `if` przechwytuje niezerowy kod wyjścia — `set -e` nie wychodzi z programu, bo błąd jest jawnie obsłużony.

## Instrukcje

### Krok 1 — Stwórz plik CSV

```bash
cd tagging-lab
```

Utwórz plik `resources.csv` z co najmniej dwoma zasobami ze swojej subskrypcji:

```bash
cat <<'EOF' > resources.csv
resource_group,resource_name,tag_key,tag_value
rg-prod,NAZWA_ZASOBU_1,env,prod
rg-dev,NAZWA_ZASOBU_2,owner,jan.kowalski
EOF
```

Zastąp `rg-prod`, `NAZWA_ZASOBU_1` itd. rzeczywistymi wartościami ze swojej subskrypcji.

Aby sprawdzić dostępne zasoby i grupy:

```bash
az resource list \
  --subscription "SUBSCRIPTION_ID" \
  --query "[].{rg:resourceGroup, name:name}" \
  --output table
```

### Krok 2 — Zastąp skrypt wersją CSV

Zastąp całą zawartość pliku `tag.sh`:

```bash
#!/bin/bash
set -euo pipefail

LOG_FILE="tag-resources.log"

usage() {
  cat <<EOF
Użycie: $0 [OPCJE]

Opcje:
  -s <subscription_id>   ID subskrypcji (wymagane)
  -f <plik_csv>          Plik CSV z zasobami (wymagany)
  -n                     Dry-run (podgląd bez wprowadzania zmian)
  -h                     Wyświetl pomoc

Format CSV (pierwsza linia to nagłówek):
  resource_group,resource_name,tag_key,tag_value

Przykłady:
  $0 -s 00000000-0000-0000-0000-000000000000 -f resources.csv
  $0 -s 00000000-0000-0000-0000-000000000000 -f resources.csv -n
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

process_csv() {
  local subscription="$1"
  local csv_file="$2"
  local dry_run="$3"

  local line_num=0
  local count_ok=0
  local count_err=0

  while IFS=, read -r resource_group resource_name tag_key tag_value; do
    (( line_num += 1 ))

    # Pomiń nagłówek (pierwsza linia)
    [[ $line_num -eq 1 ]] && continue

    # Usuń ewentualny \r z końca wartości (pliki CSV zapisane na Windows)
    tag_value="${tag_value%$'\r'}"

    # Pomiń puste linie i komentarze zaczynające się od #
    [[ -z "$resource_group" ]] && continue
    [[ "$resource_group" == \#* ]] && continue

    # Sprawdź czy wszystkie cztery pola są wypełnione
    if [[ -z "$resource_group" || -z "$resource_name" || -z "$tag_key" || -z "$tag_value" ]]; then
      log_error "Linia $line_num: brakujące pola — pomijam."
      (( count_err += 1 ))
      continue
    fi

    log "--- Linia $line_num: $resource_group / $resource_name / ${tag_key}=${tag_value}"

    local resource_id
    if ! resource_id=$(resolve_resource_id "$subscription" "$resource_group" "$resource_name"); then
      log_error "Linia $line_num: błąd podczas szukania zasobu '$resource_name' — pomijam."
      (( count_err += 1 ))
      continue
    fi

    if [[ -z "$resource_id" ]]; then
      log_error "Linia $line_num: zasób '$resource_name' nie znaleziony w grupie '$resource_group' — pomijam."
      (( count_err += 1 ))
      continue
    fi

    if process_resource "$resource_id" "$tag_key" "$tag_value" "$dry_run"; then
      (( count_ok += 1 ))
    else
      log_error "Linia $line_num: błąd podczas tagowania zasobu '$resource_name'."
      (( count_err += 1 ))
    fi

  done < "$csv_file"

  log "=== Podsumowanie: przetworzono=$count_ok błędy=$count_err ==="
}

validate_inputs() {
  local subscription="$1"
  local csv_file="$2"

  if [[ -z "$subscription" ]]; then
    log_error "Parametr -s jest wymagany."
    usage
  fi

  if [[ -z "$csv_file" ]]; then
    log_error "Parametr -f jest wymagany."
    usage
  fi

  if [[ ! -f "$csv_file" ]]; then
    log_error "Plik '$csv_file' nie istnieje."
    exit 1
  fi

  if [[ ! -r "$csv_file" ]]; then
    log_error "Plik '$csv_file' nie jest czytelny (brak uprawnień)."
    exit 1
  fi
}

main() {
  local subscription=""
  local csv_file=""
  local dry_run="false"

  while getopts "s:f:nh" opt; do
    case $opt in
      s) subscription="$OPTARG" ;;
      f) csv_file="$OPTARG" ;;
      n) dry_run="true" ;;
      h) usage ;;
      *) usage ;;
    esac
  done

  validate_inputs "$subscription" "$csv_file"

  log "=== Start: tag-resources.sh (tryb CSV) ==="
  [[ "$dry_run" == "true" ]] && log "[DRY-RUN] Tryb podglądu — żadne zmiany nie zostaną wprowadzone."
  log "subscription=$subscription | csv=$csv_file"

  process_csv "$subscription" "$csv_file" "$dry_run"

  log "=== Zakończono. Log zapisany w: $LOG_FILE ==="
}

trap 'log_error "Nieoczekiwany błąd w linii $LINENO. Sprawdź log: $LOG_FILE"' ERR

main "$@"
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 3 — Przetestuj parsowanie CSV bez Azure

Zanim uruchomisz skrypt przeciw Azure, sprawdź czy plik CSV jest poprawnie czytany:

```bash
while IFS=, read -r resource_group resource_name tag_key tag_value; do
  echo "rg=$resource_group | name=$resource_name | tag=${tag_key}=${tag_value}"
done < resources.csv
```

Powinieneś zobaczyć cztery kolumny dla każdej linii danych (nagłówek też się wyświetli — to normalne, skrypt go pominie).

### Krok 4 — Uruchom dry-run

```bash
./tag.sh -s "SUBSCRIPTION_ID" -f resources.csv -n
```

Sprawdź, że każda linia CSV generuje wpis `[DRY-RUN]` — bez żadnych zmian w Azure.

### Krok 5 — Uruchom właściwe tagowanie

```bash
./tag.sh -s "SUBSCRIPTION_ID" -f resources.csv
```

Obserwuj logi — każdy zasób z pliku powinien zostać przetworzony po kolei.

### Krok 6 — Sprawdź podsumowanie i plik logu

```bash
cat tag-resources.log
```

Na końcu logu znajdziesz wiersz podsumowania:

```
[2026-01-15 12:34:56] === Podsumowanie: przetworzono=2 błędy=0 ===
```

### Krok 7 — Przetestuj scenariusze błędów

Przygotuj plik z celowo błędnymi danymi:

```bash
cat <<'EOF' > resources-bad.csv
resource_group,resource_name,tag_key,tag_value
# to jest komentarz — zostanie pominięty

rg-prod,NIE_ISTNIEJE,env,test
rg-prod,,env,test
EOF
```

```bash
./tag.sh -s "SUBSCRIPTION_ID" -f resources-bad.csv -n
```

Oczekiwane zachowanie:
- Linia z `#` — pominięta bez błędu
- Pusta linia — pominięta bez błędu
- Nieistniejący zasób — błąd w logu, przetwarzanie kontynuowane
- Linia z pustym polem — błąd w logu, przetwarzanie kontynuowane

### Krok 8 — Przetestuj brakujące parametry

```bash
# Brak -s
./tag.sh -f resources.csv

# Brak -f
./tag.sh -s "SUBSCRIPTION_ID"

# Nieistniejący plik
./tag.sh -s "SUBSCRIPTION_ID" -f nie-istnieje.csv
```

### Krok 9 — Zweryfikuj tagi na zasobach

```bash
az resource list \
  --subscription "SUBSCRIPTION_ID" \
  --query "[].{name:name, tags:tags}" \
  --output json
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.09`.

## Podsumowanie kursu

Skrypt ewoluował przez 9 modułów:

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
| 09 | `while IFS=, read -r` — zbiorcze tagowanie z pliku CSV |

## Ćwiczenia

1. **Obsługa średnika jako separatora** — Excel w europejskich ustawieniach regionalnych eksportuje CSV z `;` zamiast `,`. Dodaj flagę `-d <separator>` i przekaż ją do `IFS` w pętli.

2. **Raport wynikowy** — po przetworzeniu wszystkich wierszy zapisz plik `results.csv` z dodatkową kolumną `status` (`ok` / `skipped` / `error`) dla każdego zasobu.

3. **Walidacja pliku przed uruchomieniem** — przed wejściem do pętli policz wiersze danych (`wc -l`) i wyświetl komunikat: `"Znaleziono N zasobów do przetworzenia."` Zatrzymaj skrypt jeśli plik jest pusty (tylko nagłówek).

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` i plik CSV w swojej gałęzi:

```bash
git add tag.sh resources.csv
git commit -m "Lab 09 ukończony"
```
