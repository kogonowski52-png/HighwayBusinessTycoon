# Highway Business Tycoon

Mobilny tycoon 3D rozwijany w Godocie. Pierwsza wersja zawiera Stację Północ przy trasie 17.

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Rozpocznij tankowanie, obserwuj klienta na mapie i odbierz przychód po zakończeniu obsługi. Pierwsza sprzedaż pozwala kupić ulepszenie. Pięć poziomów zmienia wygląd stacji, czas tankowania i stawkę za klienta. Nowe samochody wjeżdżają samodzielnie. Przełączniki języka i limitu FPS są obok nazwy stacji.

Postęp zapisuje się lokalnie po sprzedaży, ulepszeniu i zmianie ustawień. Ponowne uruchomienie odtwarza kasę, poziom, liczbę klientów i preferencje.

## Uruchomienie

Otwórz `project.godot` w stabilnym Godocie 4.6.3 lub zgodnym nowszym wydaniu. Etap sprawdzono w 4.7.2. W edytorze wciśnij F6 dla otwartej sceny `scenes/world/roadside.tscn` lub F5 dla całego projektu.

```sh
godot --headless --editor --import --path . --quit
godot --path .
godot --headless --path . --script tests/station_smoke.gd
```

Do testów graficznych uruchom ten sam skrypt bez `--headless` i przekaż mu istniejący katalog za pomocą `-- --capture-dir=/pełna/ścieżka`. Zrzuty powstają bezpośrednio z renderowanego okna gry. Test celowo uszkadza osobny plik zapisu, więc komunikat parsera przed podsumowaniem jest spodziewany.

## Android

Preset **Android** używa pakietu `pl.krystiandevelopment.highwaytycoon`, orientacji pionowej i architektur arm64 oraz x86_64. W Godocie zainstaluj szablony eksportu zgodne z wersją edytora i ustaw ścieżki Android SDK i JDK. Następnie wykonaj:

```sh
godot --headless --path . --export-debug Android builds/highway-business-tycoon.apk
```

Wymagania kolejnych etapów opisują [PROJECT_STATUS.md](PROJECT_STATUS.md) i [ROADMAP.md](ROADMAP.md).
