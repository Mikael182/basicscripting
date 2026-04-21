# Lab 02 — Zmienne

## Wymagania

- Ukończony Lab 01 — działający plik `tag.sh` w katalogu `tagging-lab`.
- Aktywna subskrypcja w Azure z uprawnieniami Tag Contributor lub Contributor.

## Wstęp

### Cel

Zastąpienie hardcoded wartości zmiennymi bashowymi. Skrypt działa tak samo jak po Lab 01, ale jest łatwiejszy do modyfikacji — wystarczy zmienić wartość w jednym miejscu na górze pliku.

Czas trwania: 60 minut

## Teoria — zmienne w Bash

### Deklaracja i użycie

```bash
NAZWA="wartość"
echo "$NAZWA"
```

- Bez spacji wokół `=`
- Do odczytania zmiennej używamy `$NAZWA` lub `${NAZWA}`
- Zawsze otaczaj zmienne podwójnym cudzysłowem: `"$NAZWA"` — chroni przed problemami ze spacjami

### Podstawianie komend

Wynik polecenia można przypisać do zmiennej:

```bash
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Moja subskrypcja: $SUBSCRIPTION_ID"
```

### Cudzysłowy: `"` vs `'`

| Cudzysłów | Zachowanie |
|-----------|-----------|
| `"tekst"` | Zmienne są interpretowane: `"Cześć $USER"` |
| `'tekst'` | Zmienne NIE są interpretowane: `'Cześć $USER'` |

## Instrukcje

### Krok 1 — Otwórz skrypt z poprzedniego modułu

```bash
cd tagging-lab
code tag.sh
```

### Krok 2 — Dodaj zmienne

Zastąp całą zawartość pliku poniższym kodem:

```bash
#!/bin/bash

RESOURCE_ID="PEŁNE_ID_ZASOBU"
TAG_KEY="env"
TAG_VALUE="prod"

az tag update \
  --operation Merge \
  --resource-id "$RESOURCE_ID" \
  --tags "${TAG_KEY}=${TAG_VALUE}"
```

> Zwróć uwagę na `"${TAG_KEY}=${TAG_VALUE}"` — klamry `{}` pozwalają bezpiecznie łączyć zmienną z innymi znakami.

Zapisz: `Ctrl+S`, zamknij: `Ctrl+Q`.

### Krok 3 — Uruchom i zweryfikuj

```bash
./tag.sh
az resource show --ids "$RESOURCE_ID" --query tags --output json
```

### Krok 4 — Pobierz ID subskrypcji dynamicznie

Zamiast wklejać ID subskrypcji ręcznie, możemy je pobrać automatycznie.  
Otwórz skrypt i dodaj zmienną z podstawieniem komendy:

```bash
code tag.sh
```

```bash
#!/bin/bash

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
RESOURCE_GROUP="NAZWA_TWOJEJ_GRUPY_ZASOBÓW"
RESOURCE_NAME="NAZWA_TWOJEGO_ZASOBU"
RESOURCE_TYPE="PROVIDER/TYPE"

RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/${RESOURCE_TYPE}/${RESOURCE_NAME}"

TAG_KEY="env"
TAG_VALUE="prod"

echo "Subskrypcja: $SUBSCRIPTION_ID"
echo "Zasób: $RESOURCE_ID"

az tag update \
  --operation Merge \
  --resource-id "$RESOURCE_ID" \
  --tags "${TAG_KEY}=${TAG_VALUE}"
```

> Przykładowe wartości `RESOURCE_TYPE`: `Microsoft.Compute/virtualMachines`, `Microsoft.Storage/storageAccounts`, `Microsoft.Web/sites`

### Krok 5 — Uruchom i sprawdź

```bash
./tag.sh
```

### Krok 6 — Ćwiczenie: dodaj drugi tag

Zmień linię z tagami, aby dodać dwa tagi jednocześnie:

```bash
--tags "${TAG_KEY}=${TAG_VALUE}" owner=jan.kowalski
```

Uruchom i zweryfikuj:

```bash
./tag.sh
az resource show --ids "$RESOURCE_ID" --query tags --output json
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.02`.  
> W następnym module skrypt będzie przyjmował dane jako argumenty wiersza poleceń.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 02 ukończony"
```
