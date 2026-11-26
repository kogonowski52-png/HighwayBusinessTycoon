# Highway Business Tycoon

**0.9.3 · Premium Graphics 2.0** rozwija architekturę sześciu lokalizacji, wprowadza częściowe wnętrza na Stacji Północ i zwiększa flotę do 30 modeli. Podpisane APK ARM64 ma kod 9003. [APK w GitHub Releases](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v0.9.3-rc.1) · [Porównania i film](screenshots/0.9.3/README.md) · [Raport grafiki](docs/PREMIUM_GRAPHICS_2.md)

**0.9.2** ładuje reklamy w tle i otwiera je po pierwszym dotknięciu. Sklep ma dziewięć ilustrowanych sekcji i pokazuje rzeczywisty stan Google Play. Podpisany APK na Android ARM64 ma kod 9002. [APK w GitHub Releases](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v0.9.2-rc.1) · [Galeria](screenshots/0.9.2/README.md) · [Raport](docs/ANDROID_COMMERCE_092.md)

**0.9.0 Release Candidate** · wersja testowa ARM64 z kodem 9000. Wydanie dopracowuje pierwszy kontakt z grą, czytelność map, BOOST i weryfikację zakupów. Zachowuje sześć lokalizacji, 41 usług, 590 misji i dotychczasowy zapis. [Audyt](docs/RELEASE_AUDIT.md) · [Galeria i film](screenshots/0.9.0/README.md) · [Karta Google Play](release/play/README.md) · [Instrukcja wydania](docs/PLAY_CONSOLE_RC.md)

**0.8.0** rozwija wydajność kampanii i przygotowanie Androida. Obejmuje cztery profile grafiki, asynchroniczne podróże, optymalizację ruchu, wariant APK ARM64 i diagnostykę testową. [Stan etapu 7](docs/STAGE7_STATUS.md) · [Pomiary](docs/performance-0.8.0.md) · [Galeria](screenshots/0.8.0/README.md)

**0.7.0** wprowadza globalny BOOST ×2, natywną integrację testową Androida, sklep premium i przepustki sezonowe. Grywalna kampania pozostaje dostępna bez sieci. [Stan etapu 6](docs/STAGE6_STATUS.md) · [APK i konfiguracja](docs/MONETIZATION.md) · [Galeria](screenshots/0.7.0/README.md)

**0.6.1** domyka ekspansję etapu 5. Sześć lokalizacji połączonych jest atlasem. Metro City obsługuje logistykę, magazyn, salon i centrum handlowe. Działanie gry oraz stan wydania są udokumentowane w repozytorium. [Galeria](screenshots/0.6.1/README.md) · [Audyt etapu 5](docs/STAGE5_STATUS.md) · [Podpisywanie APK](docs/ANDROID_SIGNING.md)

Mobilny tycoon 3D rozwijany w Godocie. Stacja Północ przy Trasie 17 ma autorską oprawę 3D, jedenaście działających usług i cztery pory dnia.

W 0.6.0 przycisk **Atlas** otwiera sieć lokalizacji. Copper Mile w Desert Highway to osobna scena z dziesięcioma biznesami, własnymi kasami, pracownikami i wpływami offline. Atlas prowadzi też do czasowych wydarzeń, kontraktów, kolekcji, pogody i prestiżu. [Ekspansja](docs/EXPANSION.md) · [Galeria 0.6.0](screenshots/0.6.0/README.md) · [Balans Copper Mile](docs/balance-0.6.0.md)

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Samouczek prowadzi przez pierwszą sprzedaż, zakup poziomu, odbiór nagród, zatrudnienie i wpływy z kasy. Każdy krok dzieje się w normalnej rozgrywce.

W **Rozbudowie** wybierasz usługę i sprawdzasz warunki otwarcia. W karcie **Etapy** kupisz 1, 10, 25 lub maksymalną liczbę ze 100 poziomów usługi. **Pracownicy** prowadzą do zatrudniania, szkoleń i awansów. W **Menedżerach** sprawdzisz 15 portretów, przypisanie, doświadczenie i następny bonus. **Misje** obejmują karierę, 11 rozdziałów, wydarzenia oraz 50 odznak. W **Sklepie** wymieniasz środki zdobyte w grze i aktywujesz zebrane kupony. Ikona kalendarza otwiera 30-dniowy cykl nagród. Ikona statystyk pokazuje wpływy, stan kas, aktywne premie i limit offline.

Przeciągnij mapę jednym palcem i zmień przybliżenie dwoma. W oknie komputera obsługują to przeciągnięcie myszą i kółko. Znaczniki nad budynkami przybliżają usługę albo otwierają jej ulepszenia. Ustawienia obejmują trzy kanały dźwięku, wibracje, PL i EN, cztery profile grafiki i dobór automatyczny, limit 30 lub 60 FPS oraz oszczędzanie baterii.

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
godot --headless --path . --script tests/regional_checks.gd
godot --headless --path . --script tests/campaign_balance.gd
godot --headless --path . --script tests/monetization_checks.gd
godot --headless --path . --script tests/commerce_window.gd
godot --headless --path . --script tests/monetization_balance.gd
godot --headless --path . --script tests/performance_checks.gd
godot --headless --path . --script tests/fleet_profile.gd
python -m unittest discover -s backend/play
```

Testy używają oddzielnych plików zapisu. Przebieg z galerią wymaga działającego okna graficznego. Godot Movie Maker zapisuje obraz i miks z działającej gry. [Wyniki testów](TEST_REPORT.md)

```sh
mkdir -p /tmp/hbt-gallery
godot --path . --script tests/presentation_window.gd -- --capture-dir=/tmp/hbt-gallery
godot --path . --write-movie /tmp/hbt-demo.avi --fixed-fps 30 --script tests/presentation_recording.gd
godot --path . --script tests/expedition_window.gd -- --capture-dir=/tmp/hbt-gallery
godot --path . --write-movie /tmp/copper-mile.avi --fixed-fps 30 --script tests/expedition_recording.gd
godot --path . --script tests/regional_window.gd -- --capture-dir=/tmp/hbt-061-gallery
godot --path . --script tests/regional_window.gd -- --sample-performance
godot --path . --write-movie /tmp/meridian.avi --fixed-fps 30 --script tests/regional_recording.gd
godot --path . --script tests/performance_window.gd -- --capture-dir=/tmp/hbt-080-gallery --report=/tmp/hbt-080-performance.json
godot --path . --script tests/quality_layout_window.gd -- --capture-dir=/tmp/hbt-080-layout
godot --headless --path . --script tests/stability_run.gd -- --report=/tmp/hbt-080-endurance.json
godot --path . --script tests/monetization_window.gd -- --capture-dir=/tmp/hbt-070-gallery
godot --path . --script tests/commerce_window.gd -- --capture-dir=/tmp/hbt-092-shop
godot --path . --write-movie /tmp/hbt-092-ad.avi --fixed-fps 20 --script tests/commerce_window.gd -- --record
godot --path . --write-movie /tmp/hbt-093.avi --fixed-fps 20 --script tests/premium_graphics_recording.gd
godot --path . --write-movie /tmp/hbt-070-boost.avi --fixed-fps 30 --script tests/monetization_recording.gd
```

## Modele i galeria

Modele GLB są częścią repozytorium. Blender jest potrzebny do ponownego wygenerowania geometrii z autorskich skryptów.

Raport Premium Graphics 2.0 opisuje zmienione modele, geometrię etapów i sposób odtworzenia porównań na tej samej kamerze. [Modele i technika](docs/PREMIUM_GRAPHICS_2.md) · [Pomiary](docs/PERFORMANCE_093.md)

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

## Odtwarzanie dowodów RC

```bash
godot --headless --path . --script tests/release_inventory.gd
godot --headless --path . --script tests/campaign_balance.gd -- --release-horizons --report=/tmp/hbt-campaign-090.json
godot --path . --script tests/release_brand_view.gd -- --capture-dir=/tmp/hbt-brand-090
godot --path . --script tests/release_tablet_view.gd -- --capture-dir=/tmp/hbt-tablet-090
python tools/release/brand.py /tmp/hbt-brand-090
```

Kompozycja znaku i grafiki wymaga Pillow. Lista materiałów Play opisuje ujęcia telefonu, tabletów i pliki do publikacji. [Materiały Play](release/play/README.md) · [Odbiór na Androidzie](docs/PLAY_CONSOLE_RC.md)

Test przewijania natywnymi zdarzeniami dotykowymi oraz zapis galerii 0.9.1.

```bash
godot --path . --script tests/mobile_input_window.gd -- --capture-dir=/tmp/hbt-091-touch
godot --path . --write-movie /tmp/hbt-091-scroll.avi --fixed-fps 30 --script tests/mobile_input_window.gd -- --record
```
