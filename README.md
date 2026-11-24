# Highway Business Tycoon

Mobilny tycoon 3D rozwijany w Godocie. Grywalna Stacja Północ przy trasie 17 ma autorską oprawę 3D, osiem działających usług i cztery pory dnia.

## Rozgrywka

Rozpoczynasz ze 120 zł i klientem przy dystrybutorze. Tankowanie daje pierwsze 35 zł, które razem z budżetem startowym wystarczą na poziom 2. Cele wypłacają jawne nagrody. Zatrudnij pracownika, żeby obsługiwał klientów samodzielnie, i odbieraj wpływy z kasy lub przydziel menedżerkę Adę.

W menu **Obiekty** wybierasz usługę i sprawdzasz warunki otwarcia. Każdy obiekt ma 100 poziomów, kupowanych pojedynczo, po 10, po 25 albo za maksymalną dostępną kwotę. **Zespół** zawiera zatrudnianie, szkolenia, awanse i karty menedżerów. **Cele** obejmują również wydarzenia dzienne. **Finanse** pokazują rozliczenia, premie, zebrane wpływy i dochód offline. Sklep, myjnia, warsztat, parking, restauracja, motel i stanowiska TIR korzystają z tego samego systemu przyjazdów oraz rezerwacji.

Stan jest zapisywany automatycznie i przy wyjściu. Po powrocie obsadzone obiekty mogą wypłacić dochód za maksymalnie osiem godzin. Gotówka, diamenty, reputacja i punkty wydarzeń mają zapis dziesiętny. Zapis z 0.1 i 0.2 migruje przy uruchomieniu.

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
```

Test zapisu korzysta z własnego pliku i obejmuje migrację, uszkodzenie pliku głównego oraz wczytanie kopii po przerwanym zapisie. Test sceny można uruchomić w oknie z opcją `-- --capture-dir=/pełna/ścieżka`. Zrzuty aktualnej rozgrywki są w [galerii testowej](docs/gameplay-0.3.0/README.md).

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

Dodatkowy wariant eksportu z reklamą nagradzaną jest opisany w [instrukcji modułu Android](docs/ANDROID_REWARDED.md).

Wymagania kolejnych etapów opisują [PROJECT_STATUS.md](PROJECT_STATUS.md) i [ROADMAP.md](ROADMAP.md).
