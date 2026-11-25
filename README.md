# Highway Business Tycoon

Mobilny tycoon 3D rozwijany w Godocie. Stacja Północ przy Trasie 17 ma autorską oprawę 3D, jedenaście działających usług i cztery pory dnia.

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Samouczek prowadzi przez pierwszą sprzedaż, zakup poziomu, odbiór nagród, zatrudnienie i wpływy z kasy. Każdy krok dzieje się w normalnej rozgrywce.

W menu **Obiekty** wybierasz usługę i sprawdzasz warunki otwarcia. Każdy obiekt ma 100 poziomów, kupowanych pojedynczo, po 10, po 25 albo za maksymalną dostępną kwotę. **Zespół** zawiera zatrudnianie, szkolenia, awanse i 15 rozwijanych kart menedżerów. **Cele** pokazują poziom gracza, 110 misji w 11 rozdziałach, wcześniejsze cele i wydarzenia dzienne. **Finanse** pokazują zarobek z ostatniej minuty, premię czasową, stan kas i rozwój limitu offline. Wulkanizacja, parking TIR i ładowarki EV działają w tym samym systemie przyjazdów oraz rezerwacji co wcześniejsze obiekty.

Stan zapisuje się automatycznie i przy wyjściu. Nowe profile naliczają dochód offline przez maksymalnie dwie godziny. Limit można rozbudować do dwunastu godzin. Profile z edycji z limitem ośmiu godzin zachowują go przy migracji. Gotówka, diamenty, reputacja i punkty wydarzeń są zapisywane jako dokładne liczby dziesiętne.

[Galeria rozgrywki 0.4.0](screenshots/0.4.0/README.md) · [Balans i symulacja](docs/balance-0.4.0.md)

## Uruchomienie

Otwórz `project.godot` w stabilnym Godocie 4.6.3 lub zgodnym nowszym wydaniu. Etap sprawdzono w 4.7.2. W edytorze wciśnij F6 dla otwartej sceny `scenes/world/roadside.tscn` lub F5 dla całego projektu.

```sh
godot --headless --editor --import --path . --quit
godot --path .
godot --headless --path . --script tests/economy_checks.gd
godot --headless --path . --script tests/dispatch_routes.gd
godot --headless --path . --script tests/balance_simulation.gd
godot --headless --path . --script tests/station_smoke.gd
godot --headless --path . --script tests/art_gallery.gd
godot --headless --path . --script tests/career_checks.gd
godot --headless --path . --script tests/career_window.gd
```

Test zapisu korzysta z własnego pliku i obejmuje migrację, uszkodzenie pliku głównego oraz wczytanie kopii po przerwanym zapisie. Test sceny `tests/career_window.gd` można uruchomić w oknie z opcją `-- --capture-dir=/pełna/ścieżka`. [Wyniki testów](TEST_REPORT.md)

## Modele i galeria

Modele GLB są częścią repozytorium. Blender jest potrzebny do ponownego wygenerowania geometrii z autorskich skryptów.

Galeria 0.3.2 zawiera test trzech pełnych modeli stacji oraz ujęcia przebudowy. Do ponownego porównania wariantów w oknie użyj `godot --path . --script tests/art_gallery.gd -- --suite=stations --capture-dir=/pełna/ścieżka`. [Galeria przebudowy](screenshots/0.3.2/README.md)

```sh
blender -b -t 2 --python-exit-code 1 --python tools/art/generate.py
godot --headless --editor --import --path . --quit
godot --path . --script tests/art_gallery.gd -- --capture-dir=/pełna/ścieżka
```

Można wygenerować pojedynczą rodzinę, dodając na końcu polecenia Blendera `-- architecture`, `-- vehicles`, `-- characters` lub `-- landscape`. Do zapisu PNG uruchom Godota z oknem i wskaż istniejący katalog.

Wersja 0.3.1 ma osobną galerię z ujęciami przed i po modernizacji. Trzy kąty kamery można zapisać poleceniem `godot --path . --script tests/art_gallery.gd -- --suite=camera --capture-dir=/pełna/ścieżka`. [Porównanie grafiki](screenshots/README.md)

Teksturę gruntu i panele generuje `python3 tools/art/surfaces.py` z biblioteką Pillow. Ikony renderuje `blender -b -t 4 --python-exit-code 1 --python tools/art/hud_icons.py`. Czcionkę liczników odtwarza `python3 tools/art/display_font.py` z biblioteką fontTools.

Modele nowych usług i personelu odtwarza ten sam generator Blendera z rodzinami `extensions` i `expansion_characters`. Portrety kart renderuje `blender -b -t 3 --python-exit-code 1 --python tools/art/portraits.py`, a dźwięki odtwarza `python3 tools/art/feedback_audio.py`.

## Android

Preset **Android** używa pakietu `pl.krystiandevelopment.highwaytycoon`, orientacji pionowej i architektur arm64 oraz x86_64. W Godocie zainstaluj szablony eksportu zgodne z wersją edytora i ustaw ścieżki Android SDK i JDK. Eksport uruchomisz z terminala.

```sh
godot --headless --path . --export-debug Android builds/highway-business-tycoon.apk
```

Dodatkowy wariant eksportu z reklamą nagradzaną jest opisany w [instrukcji modułu Android](docs/ANDROID_REWARDED.md).

Wymagania kolejnych etapów opisują [PROJECT_STATUS.md](PROJECT_STATUS.md) i [ROADMAP.md](ROADMAP.md).
