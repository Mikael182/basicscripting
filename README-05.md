# Lab 05 — Pętle i tablice

## Wymagania

- Ukończony Lab 04 — skrypt `tag.sh` z logiką warunkową.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.
- Co najmniej dwa zasoby w tej samej lub różnych grupach zasobów.

## Wstęp

### Cel

Przebudowa skryptu tak, aby w jednym wywołaniu obsługiwał wiele zasobów.  
Interfejs zmienia się: pierwsze dwa argumenty to klucz i wartość tagu, kolejne to lista resource IDs.

```bash
./tag.sh env prod /subscriptions/.../res1 /subscriptions/.../res2
```

Czas trwania: 60 minut

## Teoria — pętle i tablice

### Pętla for po liście wartości

```bash
for ELEMENT in alfa beta gamma; do
  echo "Element: $ELEMENT"
done
```

### Pętla for po tablicy

```bash
ZASOBY=("/sub/.../res1" "/sub/.../res2" "/sub/.../res3")

for ZASOB in "${ZASOBY[@]}"; do
  echo "Przetwarzam: $ZASOB"
done
```

> Zawsze używaj `"${TABLICA[@]}"` z cudzysłowami — chroni przed problemami ze spacjami w elementach.

### Pętla for po argumentach skryptu `$@`

```bash
for ARG in "$@"; do
  echo "Argument: $ARG"
done
```

### Komenda shift

`shift N` przesuwa argumenty pozycyjne — usuwa pierwsze N argumentów, pozostałe "awansują":

```bash
echo "$1"  # pierwszy argument
shift 1
echo "$1"  # teraz to był drugi argument
```

Typowe użycie: pobierz kilka pierwszych argumentów, potem iteruj po reszcie:

```bash
KLUCZ="$1"
WARTOSC="$2"
shift 2

for ZASOB in "$@"; do
  echo "Taguj $ZASOB: ${KLUCZ}=${WARTOSC}"
done
```

### Pętla while

```bash
LICZNIK=1
while [ "$LICZNIK" -le 5 ]; do
  echo "Iteracja: $LICZNIK"
  LICZNIK=$((LICZNIK + 1))
done
```

## Instrukcje

### Krok 1 — Przygotuj listę ID zasobów

Pobierz ID kilku zasobów z wybranej grupy:

```bash
az resource list \
  --resource-group NAZWA_GRUPY_ZASOBÓW \
  --query "[].id" \
  --output tsv
```

Skopiuj co najmniej dwa ID — będą potrzebne w testach.

### Krok 2 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 3 — Dodaj pętlę for

Zastąp całą zawartość pliku:

```bash
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
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 4 — Uruchom dla jednego zasobu

Sprawdź, że poprzednia funkcjonalność nadal działa:

```bash
./tag.sh env prod "ID_ZASOBU_1"
```

### Krok 5 — Uruchom dla wielu zasobów

```bash
./tag.sh env prod "ID_ZASOBU_1" "ID_ZASOBU_2"
```

### Krok 6 — Uruchom za pomocą tablicy

Zdefiniuj tablicę w Cloud Shell i przekaż jako argumenty:

```bash
ZASOBY=(
  "ID_ZASOBU_1"
  "ID_ZASOBU_2"
)

./tag.sh env prod "${ZASOBY[@]}"
```

### Krok 7 — Przetestuj walidację

```bash
./tag.sh env
```

Powinieneś zobaczyć komunikat o użyciu (za mała liczba argumentów: `$# -lt 3`).

### Krok 8 — Zweryfikuj tagi na wszystkich zasobach

```bash
for ID in "ID_ZASOBU_1" "ID_ZASOBU_2"; do
  echo "=== $ID"
  az resource show --ids "$ID" --query tags --output json
done
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.05`.  
> W następnym module zorganizujemy kod w funkcje — skrypt stanie się czytelniejszy i łatwiejszy do rozbudowy.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 05 ukończony"
```
