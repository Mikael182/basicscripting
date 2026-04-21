# Lab 03 — Parametry pozycyjne

## Wymagania

- Ukończony Lab 02 — działający plik `tag.sh` ze zmiennymi.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Zastąpienie zmiennych zdefiniowanych w skrypcie parametrami przekazywanymi w wierszu poleceń.  
Po tym module skrypt będzie można wywołać tak:

```bash
./tag.sh /subscriptions/.../resourceGroups/rg1/providers/... env prod
```

Czas trwania: 60 minut

## Teoria — parametry pozycyjne

| Zmienna | Znaczenie |
|---------|-----------|
| `$0` | Nazwa skryptu |
| `$1`, `$2`, `$3` | Kolejne argumenty |
| `$#` | Liczba przekazanych argumentów |
| `$@` | Wszystkie argumenty jako osobne słowa |
| `$*` | Wszystkie argumenty jako jeden string |

### Przykład

```bash
#!/bin/bash
echo "Nazwa skryptu: $0"
echo "Pierwszy argument: $1"
echo "Drugi argument: $2"
echo "Liczba argumentów: $#"
```

Wywołanie:

```bash
./skrypt.sh hello world
# Nazwa skryptu: ./skrypt.sh
# Pierwszy argument: hello
# Drugi argument: world
# Liczba argumentów: 2
```

### Walidacja liczby argumentów

```bash
if [ "$#" -ne 3 ]; then
  echo "Błąd: oczekiwano 3 argumentów, podano $#"
  exit 1
fi
```

> `exit 1` — kończy skrypt z kodem błędu (niezerowy kod = błąd). `exit 0` = sukces.

## Instrukcje

### Krok 1 — Otwórz skrypt

```bash
cd tagging-lab
code tag.sh
```

### Krok 2 — Zastąp zmienne parametrami

Zastąp całą zawartość pliku:

```bash
#!/bin/bash

if [ "$#" -ne 3 ]; then
  echo "Użycie: $0 <resource_id> <klucz_tagu> <wartość_tagu>"
  echo ""
  echo "Przykład:"
  echo "  $0 /subscriptions/.../resourceGroups/rg1/providers/... env prod"
  exit 1
fi

RESOURCE_ID="$1"
TAG_KEY="$2"
TAG_VALUE="$3"

echo "Dodaję tag '${TAG_KEY}=${TAG_VALUE}' do zasobu..."

az tag update \
  --operation Merge \
  --resource-id "$RESOURCE_ID" \
  --tags "${TAG_KEY}=${TAG_VALUE}"

echo "Gotowe."
```

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 3 — Pobierz ID zasobu

```bash
az resource list --resource-group NAZWA_GRUPY_ZASOBÓW --query "[].id" --output tsv
```

Skopiuj ID wybranego zasobu.

### Krok 4 — Uruchom skrypt z argumentami

```bash
./tag.sh "PEŁNE_ID_ZASOBU" env prod
```

### Krok 5 — Przetestuj walidację

Wywołaj skrypt bez argumentów:

```bash
./tag.sh
```

Powinieneś zobaczyć komunikat o użyciu i błąd.

Wywołaj z za małą liczbą argumentów:

```bash
./tag.sh "PEŁNE_ID_ZASOBU"
```

### Krok 6 — Sprawdź kod wyjścia

```bash
./tag.sh
echo "Kod wyjścia: $?"
```

```bash
./tag.sh "PEŁNE_ID_ZASOBU" env prod
echo "Kod wyjścia: $?"
```

> `$?` zawiera kod wyjścia ostatniego polecenia. `0` = sukces, inne wartości = błąd.

### Krok 7 — Zweryfikuj tagi

```bash
az resource show \
  --ids "PEŁNE_ID_ZASOBU" \
  --query tags \
  --output json
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.03`.  
> W następnym module dodamy sprawdzenie, czy tag już istnieje, zanim go dodamy.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 03 ukończony"
```
