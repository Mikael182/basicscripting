# Lab 01 — Pierwszy skrypt: hardcoded tag

## Wymagania

- Aktywna subskrypcja w Azure i dostęp do portalu.
- Co najmniej jeden istniejący zasób w Azure (np. Storage Account, Virtual Machine, App Service).
- Uprawnienia: rola **Tag Contributor** lub **Contributor** na docelowym zasobie lub grupie zasobów.

## Uprawnienia

Aby dodawać tagi do zasobów Azure, konto musi posiadać uprawnienie `Microsoft.Resources/tags/write`.  
Uprawnienie to wchodzi w skład ról: **Tag Contributor**, **Contributor**, **Owner**.

Sprawdź, jakie role masz przypisane w bieżącej subskrypcji:

```bash
az role assignment list \
  --assignee $(az account show --query user.name -o tsv) \
  --output table
```

Jeśli brakuje uprawnień, poproś administratora o przypisanie roli **Tag Contributor** na grupie zasobów:

```bash
az role assignment create \
  --assignee <email-lub-object-id> \
  --role "Tag Contributor" \
  --scope "/subscriptions/<subscription-id>/resourceGroups/<nazwa-rg>"
```

## Wstęp

### Cel

Napisanie pierwszego skryptu bashowego, który dodaje tag do zasobu Azure przy użyciu polecenia `az tag update`.  
Wartości są na razie "hardcoded" — wpisane bezpośrednio w skrypcie.

Czas trwania: 45 minut

## Instrukcje

### Krok 1 — Uruchom Cloud Shell

Nawiguj w przeglądarce do [portal.azure.com](https://portal.azure.com), uruchom **Cloud Shell** i wybierz `Bash`.

> Oficjalna dokumentacja: [Azure Cloud Shell Quickstart](https://learn.microsoft.com/en-us/azure/cloud-shell/quickstart).

### Krok 2 — Sprawdź aktualną subskrypcję

```bash
az account show --output table
```

Jeśli chcesz przełączyć się na inną subskrypcję:

```bash
az account list --output table
az account set --subscription "NAZWA_LUB_ID_SUBSKRYPCJI"
```

### Krok 3 — Znajdź zasób do otagowania

Wyświetl listę grup zasobów:

```bash
az group list --output table
```

Wyświetl zasoby w wybranej grupie:

```bash
az resource list --resource-group NAZWA_GRUPY_ZASOBÓW --output table
```

Skopiuj wartość kolumny `id` dla wybranego zasobu — będzie potrzebna w skrypcie.

> ID zasobu ma format: `/subscriptions/<sub-id>/resourceGroups/<rg>/providers/<provider>/<type>/<name>`

### Krok 4 — Sprawdź istniejące tagi

```bash
az resource show \
  --ids "PEŁNE_ID_ZASOBU" \
  --query tags \
  --output json
```

### Krok 5 — Stwórz katalog roboczy i plik skryptu

```bash
mkdir tagging-lab
cd tagging-lab
code tag.sh
```

Wklej poniższą zawartość. Zastąp placeholder `"PEŁNE_ID_ZASOBU"` wartością skopiowaną w Kroku 3:

```bash
#!/bin/bash

az tag update \
  --operation Merge \
  --resource-id "PEŁNE_ID_ZASOBU" \
  --tags env=prod
```

Zapisz plik: `Ctrl+S`, zamknij edytor: `Ctrl+Q`.

### Krok 6 — Nadaj uprawnienia do uruchomienia

```bash
chmod +x tag.sh
```

Zweryfikuj uprawnienia:

```bash
ls -la tag.sh
```

Powinieneś zobaczyć `-rwxr-xr-x` na początku linii — litera `x` oznacza prawo do wykonania.

### Krok 7 — Uruchom skrypt

```bash
./tag.sh
```

### Krok 8 — Zweryfikuj tagi

```bash
az resource show \
  --ids "PEŁNE_ID_ZASOBU" \
  --query tags \
  --output json
```

Powinieneś zobaczyć:

```json
{
  "env": "prod"
}
```

> Gotowy skrypt dla tego modułu znajdziesz w pliku `tag.sh.01`.  
> W następnym module zastąpimy hardcoded wartości zmiennymi.

## Zapisz swoją pracę

Zatwierdź bieżący stan `tag.sh` w swojej gałęzi:

```bash
git add tag.sh
git commit -m "Lab 01 ukończony"
```
