# Highway Business Tycoon

Mobilny tycoon 3D rozwijany w Godocie. Stacja Północ przy Trasie 17 ma autorską oprawę 3D, jedenaście działających usług i cztery pory dnia.

W 0.6.0 przycisk **Atlas** otwiera sieć lokalizacji. Copper Mile w Desert Highway to osobna scena z dziesięcioma biznesami, własnymi kasami, pracownikami i wpływami offline. Atlas prowadzi też do czasowych wydarzeń, kontraktów, kolekcji, pogody i prestiżu. [Ekspansja](docs/EXPANSION.md) · [Galeria 0.6.0](screenshots/0.6.0/README.md) · [Balans Copper Mile](docs/balance-0.6.0.md)

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Samouczek prowadzi przez pierwszą sprzedaż, zakup poziomu, odbiór nagród, zatrudnienie i wpływy z kasy. Każdy krok dzieje się w normalnej rozgrywce.

W **Rozbudowie** wybierasz usługę i sprawdzasz warunki otwarcia. W karcie **Etapy** kupisz 1, 10, 25 lub maksymalną liczbę ze 100 poziomów usługi. **Pracownicy** prowadzą do zatrudniania, szkoleń i awansów. W **Menedżerach** sprawdzisz 15 portretów, przypisanie, doświadczenie i następny bonus. **Misje** obejmują karierę, 11 rozdziałów, wydarzenia oraz 50 odznak. W **Sklepie** wymieniasz środki zdobyte w grze i aktywujesz zebrane kupony. Ikona kalendarza otwiera 30-dniowy cykl nagród. Ikona statystyk pokazuje wpływy, stan kas, aktywne premie i limit offline.

Przeciągnij mapę jednym palcem i zmień przybliżenie dwoma. W oknie komputera obsługują to przeciągnięcie myszą i kółko. Znaczniki nad budynkami przybliżają usługę albo otwierają jej ulepszenia. Ustawienia obejmują trzy kanały dźwięku, wibracje, PL i EN, trzy poziomy grafiki, limit 30 lub 60 FPS oraz oszczędzanie baterii.

Stan zapisuje się automatycznie i przy wyjściu. Nowe profile naliczają dochód offline przez maksymalnie dwie godziny. Limit można rozbudować do dwunastu godzin. Profile z edycji z limitem ośmiu godzin zachowują go przy migracji. Gotówka, diamenty, reputacja i punkty wydarzeń są zapisywane jako dokładne liczby dziesiętne.

[Galeria rozgrywki 0.5.0](screenshots/0.5.0/README.md) · [Porównanie z 0.4.0](screenshots/0.5.0/porownanie-0.4.0.jpg) · [Balans i symulacja](docs/balance-0.4.0.md)

## Uruchomienie

Otwórz `project.godot` w stabilnym Godocie 4.6.3 lub zgodnym nowszym wydaniu. Etap sprawdzono w 4.7.2. W edytorze wciśnij F5, aby uruchomić ekran startowy, albo F6 w scenie `scenes/world/roadside.tscn`, aby wejść bezpośrednio na mapę.

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
godot --headless --path . --script tests/presentation_checks.gd
godot --headless --path . --script tests/presentation_window.gd
godot --headless --path . --script tests/presentation_recording.gd -- --boot-check
godot --headless --path . --script tests/expedition_checks.gd
godot --headless --path . --script tests/expedition_window.gd
godot --headless --path . --script tests/desert_balance.gd
```

Testy używają oddzielnych plików zapisu. Przebieg z galerią wymaga działającego okna graficznego. Godot Movie Maker zapisuje obraz i miks z działającej gry. [Wyniki testów](TEST_REPORT.md)

```sh
mkdir -p /tmp/hbt-gallery
godot --path . --script tests/presentation_window.gd -- --capture-dir=/tmp/hbt-gallery
godot --path . --write-movie /tmp/hbt-demo.avi --fixed-fps 30 --script tests/presentation_recording.gd
godot --path . --script tests/expedition_window.gd -- --capture-dir=/tmp/hbt-gallery
godot --path . --write-movie /tmp/copper-mile.avi --fixed-fps 30 --script tests/expedition_recording.gd
```

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

Modele usług i personelu odtwarza ten sam generator Blendera z rodzinami `extensions` i `expansion_characters`. Portrety kart renderuje `blender -b -t 3 --python-exit-code 1 --python tools/art/portraits.py`. Dźwięki obsługi i awansu odtwarza `python3 tools/art/feedback_audio.py`. Nowsze zasoby odtworzysz poleceniami poniżej. Synteza audio wymaga NumPy i FFmpeg. [Wykaz licencji](ASSET_LICENSES.md)

```sh
python3 tools/art/presentation_art.py
python3 tools/art/presentation_audio.py
blender -b -t 4 --python-exit-code 1 --python tools/art/presentation_icons.py
blender -b --python-exit-code 1 --python tools/art/delivery.py
blender -b -t 3 --python-exit-code 1 --python tools/art/desert_diorama.py
blender -b -t 2 --python-exit-code 1 --python tools/art/desert_roadkit.py
```

## Android

Wydania testowe od 0.6.0 używają odcisku jednego certyfikatu, a GitHub Actions pobiera klucz z chronionych sekretów repozytorium. Instrukcja obejmuje przygotowanie kopii poza Cloud i jednorazową migrację ze starszych instalacji GitHub. [Podpisywanie Androida](docs/ANDROID_SIGNING.md)

Preset **Android** używa pakietu `pl.krystiandevelopment.highwaytycoon`, orientacji pionowej i architektur arm64 oraz x86_64. W Godocie zainstaluj szablony eksportu zgodne z wersją edytora i ustaw ścieżki Android SDK i JDK. Eksport uruchomisz z terminala.

```sh
godot --headless --path . --export-debug Android builds/highway-business-tycoon.apk
```

Dodatkowy wariant eksportu z reklamą nagradzaną jest opisany w [instrukcji modułu Android](docs/ANDROID_REWARDED.md).

Wymagania kolejnych etapów opisują [PROJECT_STATUS.md](PROJECT_STATUS.md) i [ROADMAP.md](ROADMAP.md).
