# Raport testów · 1.0.0-beta.2

Godot 4.7.2, Linux x86_64. Próby zapisu używały osobnych profili. Weryfikowano bieżące zasoby, podstawową kampanię, flotę, dotyk, treść prywatności oraz artefakty Androida.

## Próby w uruchomionej grze

| Zakres | Wynik |
| --- | --- |
| Zrzuty sklepu | 41/41 asercji. 32 prawdziwe kadry PL i EN, udokumentowana wizyta ciężarówki, dochód offline z obsadzonych biznesów, podróż do Desert Highway, otwarcie polityki z ustawień i kontrola lokalizowanej treści dla dwóch języków. |
| Ikony, grafika | 4/4 rendery ekspozycji i panoramy. Oceniono trzy stacje w 64 px i na masce. W banerze poprawiono położenie ciężarówki, aby logo jej nie przesłaniało. |
| Film | 1/1, cztery ujęcia w trzech regionach z symulacji Godot Movie Maker. Przy pierwszej próbie nie udało się przejść do Green Valley. Rozbudowano wymaganą kawiarnię w profilu zdjęciowym i powtórzono z sukcesem. |
| Dotyk | 65/65. Zdarzenia `InputEventScreenTouch` i `InputEventScreenDrag` obejmują listy, przeciąganie i budowanie. Wszystkie 13 list z nadmiarem zawartości przesunęły się po geście. Panel mieszczący treść nie przewijał się. |

Kadry telefonu mają 1080 × 1920. Tablety są osobnymi oknami Godota w rozdzielczościach 1200 × 1920 i 1600 × 2560. Po sprawdzeniu czytelności zmieniono dwa ujęcia w sekcji telefonu. Przygotowano krótkie nagłówki PL/EN i zachowano pełne proporcje zrzutów. Wydrukowane wartości pochodzą z kampanii przygotowanej do zdjęć. Próba dotykowa w Godocie nie zastępuje odbioru systemowych gestów i przerwań na Androidzie.

## Próby automatyczne

| Zakres | Asercje |
| --- | --- |
| Zasoby i lokalizacja | 4135/4135, w tym odczyt dwu języków, formatowania i kompletności 12 regionów, 84 usług i 719 misji. |
| Ekonomia, zapis, trasy i stacja | 70/70 ekonomia i offline, 30/30 ruch i rezerwacje, 27/27 stacja. |
| Regiony, kariera i prezentacja | 82/82 ekspansja, 93/93 regionalne trasy i odrębne obszary, 151/151 utrzymanie rozbudowanego ruchu, 210/210 kariera i menedżerowie, 278/278 prezentacja. |
| Systemy Advanced Gameplay | 104/104 flota i kontrakty, 95/95 teren i infrastruktura, 22/22 mini-gry, 2/2 wczytywanie przekroju, 4/4 kontrola CPU floty. |
| Reklamy i sklep | 120/120 mechaniki monetyzacji i BOOST, 54/54 powiadomienia, pierwsze kliknięcie i sklep z kontrolowanym adapterem natywnym. |
| Migracja | 14/14 generowanie i zapis odrębnego profilu w autentycznym 0.9.5 oraz 4/4 odczyt i ponowny zapis w beta.2. Dodatkowy przebieg zapisał stan w źródłowym 10001 i potwierdził 4/4 w 10002. Pokrywa 12 regionów, flotę, ustawienia, uprawnienia, historię premii i pozostały BOOST. |
| Profile i obciążenie | 468/468 symulacja i cykl aplikacji. Odrębny pomiar 12 regionów z aktywną sceną opisano w raporcie wydajności. |
| Backend | 15/15 testy izolowane serwisu transakcji i idempotentności. |
| Android | Weryfikacja APK względem 10001, walidacja AAB, eksport APK walidacyjnego, kontrola 16 KiB, ABI, API oraz wykluczenia plików deweloperskich. |

Na etapie zbiorczego uruchomienia skrypt `run_checks.gd` osiągnął limit czasu, ponieważ służy jako klasa bazowa i nie ma procedury uruchamiającej. Każdą z 17 właściwych prób Godota uruchomiono osobno, z kodem wyjścia 0. Początkowy test publikacyjny zatrzymał się na braku typu w kodzie pomocniczym scenariusza. Dodano deklarację typu, a pełna powtórka zakończyła się wynikiem 41/41.

Chromium przez lokalny HTTP otworzył oba języki polityki i 40 obrazów galerii bez poziomego przepełnienia przy szerokościach 360, 800 i 1440 px. Publiczny adres pozostaje do potwierdzenia.

Sprawdzenie adaptera transakcji to próba lokalna. Fizyczny telefon i tablety oraz tor zamknięty wymagają osobnego odbioru, w tym instalacji, aktualizacji w miejscu, reklamy testowej z UMP i powrotu do gry. AAB oczekuje na właściwy podpis upload. [Lista odbioru dla testera](../13_TESTY_ZAMKNIETE/LISTA_DLA_TESTERA.md) · [Wydajność](RAPORT_WYDAJNOSCI.md)
