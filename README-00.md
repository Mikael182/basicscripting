# Lab 00 — Przygotowanie środowiska i git

## Wymagania wstępne

- Konto Azure z aktywną subskrypcją.
- Dostęp do **Azure Cloud Shell** (portal.azure.com → ikona `>_`) lub lokalne środowisko z bash i git.
- Podstawowa znajomość terminala: nawigacja katalogami, uruchamianie poleceń.

Nie musisz znać bash ani git przed rozpoczęciem kursu — wszystko jest wyjaśniane krok po kroku.

## Klonowanie repozytorium

Otwórz Cloud Shell (lub terminal) i sklonuj repozytorium:

```bash
git clone <URL_REPOZYTORIUM>
cd basicscripting
```

Zastąp `<URL_REPOZYTORIUM>` adresem udostępnionym przez prowadzącego.

## Stwórz własną gałąź

Każdy student pracuje na osobnej gałęzi, żeby zmiany nie kolidowały ze sobą i z materiałami kursu.

```bash
git checkout -b student/imie-nazwisko
```

Przykład:

```bash
git checkout -b student/jan-kowalski
```

Konwencja nazwy: `student/` + imię i nazwisko małymi literami, z myślnikiem zamiast spacji.

Sprawdź, że jesteś na właściwej gałęzi:

```bash
git branch
```

Aktywna gałąź jest oznaczona gwiazdką `*`.

## Struktura repozytorium

```
basicscripting/
├── README-00.md          # ten plik — przygotowanie
├── README-01.md          # Lab 01
│   ...
├── README-09.md          # Lab 09
├── tag.sh.01             # gotowy skrypt referencyjny do Lab 01
│   ...
├── tag.sh.09             # gotowy skrypt referencyjny do Lab 09
└── tag.sh                # twój plik roboczy (tworzysz go w Lab 01)
```

**Skrypty referencyjne** (`tag.sh.01`–`tag.sh.09`) to wzorcowe rozwiązania każdego modułu — możesz je podejrzeć gdy utkniesz, ale spróbuj najpierw samodzielnie.

**Twój plik roboczy** to `tag.sh` — tworzysz go w Lab 01 i rozwijasz przez wszystkie kolejne moduły.

## Podstawowe komendy git używane w kursie

| Komenda | Co robi |
|---------|---------|
| `git status` | pokaż co zostało zmienione |
| `git diff tag.sh` | pokaż dokładne zmiany w pliku |
| `git add tag.sh` | przygotuj plik do commita |
| `git commit -m "wiadomość"` | zapisz zmiany z opisem |
| `git log --oneline` | historia commitów w zwartej formie |
| `git branch` | sprawdź aktywną gałąź |

## Przepływ pracy w każdym module

1. Przeczytaj README modułu.
2. Wykonaj instrukcje krok po kroku — pisz i modyfikuj `tag.sh`.
3. Przetestuj skrypt w Cloud Shell.
4. Zatwierdź zmiany w git (sekcja **Zapisz swoją pracę** na końcu każdego modułu).
5. Przejdź do następnego modułu.

Commituj po każdym module — nie czekaj do końca kursu. Dzięki temu masz historię swojego postępu i możesz wrócić do wcześniejszego stanu jeśli coś pójdzie nie tak.

## Przejdź do Lab 01

```bash
cat README-01.md
```
