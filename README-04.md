# Lab 04 — Instrukcje warunkowe (if/elif/else)

## Wymagania

- Ukończony Lab 03 — skrypt `tag.sh` przyjmujący parametry pozycyjne.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Dodanie logiki warunkowej: skrypt sprawdza, czy tag już istnieje na zasobie, zanim go doda lub nadpisze. Unikamy niepotrzebnych zmian w Azure.

Czas trwania: 60 minut

## Teoria — instrukcje warunkowe

### Składnia if/elif/else

```bash
if [ warunek ]; then
  # gdy warunek prawdziwy
elif [ inny_warunek ]; then
  # gdy drugi warunek prawdziwy
else
  # gdy żaden warunek nie jest spełniony
fi
```

### Operatory dla stringów

| Operator | Znaczenie |
|----------|-----------|
| `"$a" == "$b"` | równe |
| `"$a" != "$b"` | różne |
| `-z "$a"` | string jest pusty |
| `-n "$a"` | string jest niepusty |

> W warunkach dla stringów używaj `[[ ]]` zamiast `[ ]` — jest bezpieczniejszy i obsługuje więcej operatorów.

### Operatory dla plików

| Operator | Znaczenie |
|----------|-----------|
| `-f "$plik"` | istnieje i jest plikiem |
| `-d "$katalog"` | istnieje i jest katalogiem |
| `-e "$ścieżka"` | istnieje (plik lub katalog) |

### Operatory dla liczb

| Operator | Znaczenie |
|----------|-----------|
| `-eq` | równe |
| `-ne` | różne |
| `-gt` | większe niż |
| `-lt` | mniejsze niż |

### Łączenie warunków

```bash
if [[ -n "$a" && "$a" == "prod" ]]; then
  echo "Zmienna a jest ustawiona i równa prod"
fi
```

## Instrukcje

### Krok 1 — Przetestuj zapytanie o tagi

Zanim zmienisz skrypt, sprawdź jak wyglądają wyniki zapytania o konkretny tag:

```bash
RESOURCE_ID="PEŁNE_ID_ZASOBU"

# Pobierz wartość tagu "env" — zwróci pusty string jeśli nie istnieje
az resource show \
  --ids "$RESOURCE_ID" \
  --query 'tags."env"' \
  --output tsv
```

Uruchom to samo dla zasobu, na którym tag `env` już istnieje, i dla takiego gdzie nie istnieje. Porównaj wyniki.

### Krok 2 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 3 — Dodaj logikę warunkową

Zastąp całą zawartość pliku:

```bash
#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Użycie: $0 <resource_id> <klucz_tagu> <wartość_tagu>"
  exit 1
fi

RESOURCE_ID="$1"
TAG_KEY="$2"
TAG_VALUE="$3"

echo "Sprawdzam istniejące tagi na zasobie..."

EXISTING=$(az resource show --ids "$RESOURCE_ID" \
  --query "tags.\"${TAG_KEY}\"" --output tsv 2>/dev/null)

if [[ "$EXISTING" == "$TAG_VALUE" ]]; then
  echo "Tag '${TAG_KEY}=${TAG_VALUE}' już istnieje — pomijam."
elif [[ -n "$EXISTING" ]]; then
  echo "Tag '${TAG_KEY}' istnieje z wartością '$EXISTING' — nadpisuję na '$TAG_VALUE'."
  az tag update --operation Merge --resource-id "$RESOURCE_ID" --tags "${TAG_KEY}=${TAG_VALUE}"
  echo "Tag zaktualizowany."
else
  echo "Tag '${TAG_KEY}' nie istnieje — dodaję."
  az tag update --operation Merge --resource-id "$RESOURCE_ID" --tags "${TAG_KEY}=${TAG_VALUE}"
  echo "Tag dodany."
fi
```

> `2>/dev/null` — przekierowuje błędy do "czarnej dziury", dzięki czemu nie widać komunikatów błędu az CLI gdy zasób nie ma tagów.

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 4 — Przetestuj scenariusz: tag nie istnieje

Usuń tag `env` z zasobu (jeśli istnieje):

```bash
az tag update \
  --operation Delete \
  --resource-id "PEŁNE_ID_ZASOBU" \
  --tags env=""
```

Uruchom skrypt:

```bash
./tag.sh "PEŁNE_ID_ZASOBU" env prod
```

Powinieneś zobaczyć: `Tag 'env' nie istnieje — dodaję.`

### Krok 5 — Przetestuj scenariusz: tag już istnieje z tą samą wartością

```bash
./tag.sh "PEŁNE_ID_ZASOBU" env prod
```

Powinieneś zobaczyć: `Tag 'env=prod' już istnieje — pomijam.`

### Krok 6 — Przetestuj scenariusz: tag istnieje z inną wartością

```bash
./tag.sh "PEŁNE_ID_ZASOBU" env dev
```

Powinieneś zobaczyć: `Tag 'env' istnieje z wartością 'prod' — nadpisuję na 'dev'.`

### Krok 7 — Zweryfikuj końcowy stan tagów

```bash
az resource show \
  --ids "PEŁNE_ID_ZASOBU" \
  --query tags \
  --output json
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.04`.  
> W następnym module skrypt będzie obsługiwał wiele zasobów naraz.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 04 ukończony"
```
