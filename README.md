# Highway Business Tycoon

Mobilny tycoon 3D rozwijany w Godocie. Grywalna Stacja Północ przy trasie 17 ma autorską oprawę 3D, siedem obiektów i cztery pory dnia.

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Rozpocznij tankowanie, obserwuj klienta na mapie i odbierz przychód po zakończeniu obsługi. Pierwsza sprzedaż pozwala kupić ulepszenie. Pięć poziomów zmienia wygląd stacji, czas tankowania i stawkę za klienta. Nowe samochody wjeżdżają samodzielnie. Przełączniki języka i limitu FPS są obok nazwy stacji. Przycisk pory dnia zmienia oświetlenie i światła pojazdów, a przycisk mapy przełącza kadr stacji i otoczenia.

Postęp zapisuje się lokalnie po sprzedaży, ulepszeniu i zmianie ustawień. Ponowne uruchomienie odtwarza kasę, poziom, liczbę klientów i preferencje.

## Uruchomienie

Otwórz `project.godot` w stabilnym Godocie 4.6.3 lub zgodnym nowszym wydaniu. Etap sprawdzono w 4.7.2. W edytorze wciśnij F6 dla otwartej sceny `scenes/world/roadside.tscn` lub F5 dla całego projektu.

```sh
godot --headless --editor --import --path . --quit
godot --path .
godot --headless --path . --script tests/station_smoke.gd
godot --headless --path . --script tests/art_gallery.gd
```

Test stacji celowo uszkadza osobny plik zapisu. Komunikat parsera przed podsumowaniem potwierdza sprawdzenie awaryjnego odczytu.

## Modele i galeria

Modele GLB są częścią repozytorium. Blender jest potrzebny do ponownego wygenerowania geometrii z autorskich skryptów.

```sh
blender -b -t 2 --python-exit-code 1 --python tools/art/generate.py
godot --headless --editor --import --path . --quit
godot --path . --script tests/art_gallery.gd -- --capture-dir=/pełna/ścieżka
```

Można wygenerować pojedynczą rodzinę, dodając na końcu polecenia Blendera `-- architecture`, `-- vehicles`, `-- characters` lub `-- landscape`. Do zapisu PNG uruchom Godota z oknem i wskaż istniejący katalog. Gotowe kadry są w [galerii](docs/art-gallery/README.md).

## Android

Preset **Android** używa pakietu `pl.krystiandevelopment.highwaytycoon`, orientacji pionowej i architektur arm64 oraz x86_64. W Godocie zainstaluj szablony eksportu zgodne z wersją edytora i ustaw ścieżki Android SDK i JDK. Eksport uruchomisz z terminala.

```sh
godot --headless --path . --export-debug Android builds/highway-business-tycoon.apk
```

Wymagania kolejnych etapów opisują [PROJECT_STATUS.md](PROJECT_STATUS.md) i [ROADMAP.md](ROADMAP.md).
