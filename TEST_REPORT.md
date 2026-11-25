# Raport testów

## 0.5.0 · Interfejs i rytm Trasy 17

Godot 4.7.2 Stable na Linuxie, renderer Compatibility i Mesa llvmpipe. Próby używają oddzielnych lokalnych profili. [30 zrzutów](screenshots/0.5.0/README.md) · [Porównanie z 0.4.0](screenshots/0.5.0/porownanie-0.4.0.jpg) · [Wydajność](docs/performance-0.5.0.md)

| Próba | Wynik |
| --- | --- |
| Kalendarz, osiągnięcia, doświadczenie kart, miks i zapis | 278/278 |
| Przejście interfejsu bez okna | 49/49 |
| Zimny start przez przycisk Graj w oddzielnych procesach | 6/6 |
| Przejście interfejsu w oknie z wejściami gracza i zapisem 30 kadrów | 81/81 |
| Pętla istniejącej stacji, w tym myjnia i odczyt zapisu | 27/27 |
| Pętla kariery, rozdziały, wypłata i 11 usług | 44/44 |
| Regresja modeli, sylwetek i animacji | 113/113 |
| Ekonomia, odzyskiwanie zapisu i dochód offline | 69/69 |
| Ruch i rezerwacje | 30/30 |
| Kariera, pracownicy, menedżerowie i starsze zapisy | 192/192 |
| Balans w 18 scenariuszach | 46/46 |
| Migracja pliku zapisanego w 0.4.0 z `5161601` | Zapis schematu 5 zachował wszystkie 27 porównanych pól, w tym rozbudowę, awanse, akcje menedżera, aktywną premię, limit 4 h i oczekującą wypłatę. Dawne wyciszenie i brak wibracji zostały przeniesione do osobnych ustawień. |
| Lokalny APK debug | Wersja 0.5.0, kod 7, arm64-v8a i x86_64, Android od API 24, cel API 36. Podpis v2/v3, integralność i uprawnienie `VIBRATE` zweryfikowane. |

Sprawdzono wszystkie 30 dni kalendarza i 50 odbiorów odznak, pominięcie dni, cofnięcie czasu oraz ponowne otwarcie zapisu po każdej nagrodzie. Test okienkowy objął start, kliknięcia w panele, płynny powrót kamery po zmianie wiaty, zakup za walutę gry, suwak każdego kanału i blokadę gestu pod panelem. Animacja bramy wynikała z aktywnej rezerwacji, klient wysiadł przy sklepie, a zakończona sprzedaż uruchomiła dostawę z paczką. Symulacja balansu bez odbierania nowych nagród dała identyczny raport JSON jak 0.4.0. [Raport balansu](docs/balance-0.4.0.md)

Film pokazuje wejście z menu, tankowanie, rozbudowę, zatrudnienie i odebranie nagrody. Zapis zawiera 464 klatki w rozdzielczości 486 × 864 przy 30 FPS oraz kompletną ścieżkę stereo z silnika. Godot Movie Maker zgłosił pozostające zasoby audio przy zamykaniu nagrywania. Zimny start, scenariusz bez nagrywania i przejście galerii zakończyły się bez tego ostrzeżenia. [Nagranie](screenshots/0.5.0/rozgrywka.mp4)

Lokalny APK ma 74 349 357 bajtów i SHA-256 `de17431cbf726a20287e7cb470765b693b35137b30f7f7148aea88345df28780`. Podpis odpowiada lokalnej wersji 0.4.0. Manifest domyślnej kompilacji Android obejmuje wibracje i działanie offline. Fizyczna instalacja, głośność na głośniku telefonu, wibracje i FPS pozostają do sprawdzenia. Po pełnym zamknięciu aplikacji kalendarz offline ufa lokalnemu zegarowi i zachowuje najwyższy znacznik. Cofnięcie nie odnawia wykorzystanej nagrody.

### APK z GitHuba

Plik pobrano z wydania `v0.5.0` zbudowanego z commitu `75de278`. APK ma 74 349 357 bajtów i SHA-256 `ed53c7dc514448e59199a284721aa6998911ec186d2758c95d333fbbcdf17d4f`, zgodne z notą wydania. Pobrany pakiet przeszedł weryfikację archiwum, podpisu v2/v3, wersji i obu architektur. Manifest deklaruje jedynie uprawnienie `VIBRATE`. [APK](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.5.0/HighwayBusinessTycoon-0.5.0-debug.apk) · [GitHub Actions](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45652573648)

Debug APK z GitHub Releases 0.4.0 i 0.5.0 mają różne certyfikaty. Aktualizacja istniejącej instalacji na Androidzie wymaga zgodnego certyfikatu. Migrację danych sprawdzono przez bezpośredni odczyt profilu, a para lokalnych APK korzysta z tego samego certyfikatu debug.

## 0.4.0 · Rozwój Trasy 17

Próby wykonano w Godocie 4.7.2 Stable na Linuxie. Okno gry korzystało z renderera Compatibility i Mesa llvmpipe. Modele i portrety wykonano w Blenderze 4.3.2. [Galeria 19 zrzutów](screenshots/0.4.0/README.md)

| Zestaw | Wynik |
| --- | --- |
| Ekonomia, odczyt awaryjny i offline | 69/69 |
| Ruch i rezerwacje 26 stanowisk | 30/30 |
| Balans na trzech ziarnach i w sześciu horyzontach | 46/46 |
| Kariera, 120 nagród, 15 kart, offline i migracja | 192/192 |
| Samouczek i kompleks bez okna | 44/44 |
| Samouczek i kompleks w oknie | 63/63, w tym 19 zapisanych zrzutów |
| Pętla istniejącej stacji bez okna | 27/27 |
| Pętla istniejącej stacji w oknie | 36/36 |
| Regresja istniejących modeli i animacji bez okna | 113/113 |
| Zapis utworzony przez 0.3.2 z `894e8de` | Zachowane waluty, poziomy, pracownik po awansie, karta Ady, misje, ustawienia, limit 8 h i oczekująca wypłata. Kolejny zapis ma schemat 4. |
| Lokalny APK debug | 0.4.0, kod 6, arm64-v8a i x86_64, Android od API 24, cel API 36. Podpis v2/v3 i integralność zweryfikowane. |

W teście ruchu trwającym 20 minut pojazdy wykonały 215 usług. Osiem odjechało bez obsługi. Wszystkie jedenaście usług miało klientów, wszystkie rezerwacje się zwolniły, a awaryjne odzyskiwanie ruchu uruchomiło się wyłącznie w osobnej próbie z celową przeszkodą. Próba w oknie przeszła przez prawdziwe kliknięcia samouczka, dodanie pracownika, wypłatę, odebranie misji rozdziału, awans menedżera, zakup czterogodzinnego limitu i ponowny odczyt stanu. Każda z trzech nowych usług obsłużyła rzeczywisty pojazd. Kabel EV i animacje obsługi odzwierciedlały stan wizyty.

Na rozbudowanym kompleksie z HUD-em w kadrze 1600 × 1080 zarejestrowano 704 wywołania rysowania i 132 623 prymitywy. Uruchomienie instalatora, pomiar FPS, dźwięku i wibracji na fizycznym Androidzie pozostają do sprawdzenia. Wznawianie gry porównuje czas z zegarem monotonicznym tego samego procesu. Naliczanie po zamknięciu aplikacji korzysta z lokalnego znacznika czasu i limitu wypłaty.

Lokalny APK ma 71 798 549 bajtów. SHA-256 pliku to `d2edcd1ab7314d4b49a25161afc591ce04c84d852704520a91bee5cd80cc22d8`. Certyfikat zgadza się z lokalną kompilacją 0.3.2. Manifest zawiera uprawnienie `VIBRATE`. Gra działa bez uprawnienia do internetu. Eksport pomija galerię i zestawy testów. [Raport balansu](docs/balance-0.4.0.md)

### APK z GitHuba

Pobrano APK 0.4.0 z tagu `v0.4.0` i commitu `b6a6cf8`. Archiwum ma 71 798 549 bajtów. SHA-256 `eb835315f725fd5d2b91f80a15df3e6dc9913543cefe3e860c578bda7448fe73` zgadza się z wydaniem. Sprawdzono podpis v2/v3, wersję 0.4.0, kod 6, obie architektury i uprawnienie do wibracji. Certyfikat kompilacji GitHuba jest nowy. Aktualizacja na urządzeniu wymaga zgodnego certyfikatu starego i nowego APK. [Wydanie](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v0.4.0) · [Przebieg GitHub Actions](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45643795824)

## 0.3.2 · Przebudowa Trasy 17

Testy wykonano w Godocie 4.7.2 Stable na Linuxie, w rendererze Compatibility z Mesa llvmpipe. Modele wygenerowano w Blenderze 4.3.2. Galeria zawiera 22 kadry z uruchomionej gry i plansz modeli, trzy ujęcia wariantów w tej samej scenie oraz porównanie z ujęciami z commitu `7ea8bf9`. [Galeria 0.3.2](screenshots/0.3.2/README.md)

| Próba | Wynik |
| --- | --- |
| Import projektu i start sceny | Zakończone bez błędów |
| Ekonomia, zapis i dochód offline | 63/63 |
| Ruch i rezerwacje stanowisk | 23/23 |
| Symulacja balansu | 46/46 |
| Pętla rozgrywki bez okna | 27/27 |
| Pętla rozgrywki w oknie | 36/36, w tym kliknięcie zakupu w nowym panelu etapów i ponowny odczyt zapisu |
| Geometria i animacje bez okna | 98/98 |
| Geometria i animacje w oknie | 119/119, wraz z zapisem 21 kadrów, ruchem klienta sklepu i obsługą w warsztacie |
| Trzy warianty stacji w oknie | 6/6, w tym zapis trzech kadrów |
| Zapis utworzony przez uruchomioną wersję 0.3.1 | Zachowane saldo, 11 diamentów, poziom 5 stacji, otwarty sklep, pracownik, język angielski i limit 30 FPS. Scena pokazała właściwe zadaszenie wczytanego poziomu. |
| APK debug | Pakiet `pl.krystiandevelopment.highwaytycoon`, wersja 0.3.2, kod 5, arm64-v8a i x86_64, min. API 24, cel API 36, podpis v2/v3 |

W 20-minutowym teście ruchu ukończono 253 obsługi we wszystkich ośmiu usługach. Sześć pojazdów odjechało bez obsługi. Nie wystąpiło awaryjne zwalnianie rezerwacji. W próbie okienkowej sprawdzono tankowanie, zatrudnienie, wypłatę, zakup ulepszenia i widok tabletowy w rzeczywistych kontrolkach.

### Geometria modeli

W tabeli podano liczbę indeksowanych trójkątów przed LOD. Każdy z trzech wariantów dachu ma własną geometrię. W wariantach Łuk, Przełęcz i Taras policzono odpowiednio 3 528, 6 288 i 6 448 trójkątów. Początkowa wiata ma 3 906 trójkątów.

| Model | 0.3.1 | 0.3.2 |
| --- | ---: | ---: |
| Otwarty sklep | 30 660 | 35 548 |
| Warsztat | 8 320 | 13 544 |
| Samochód miejski Sprint | 5 042 | 6 530 |
| Ciężarówka Cargo z naczepą | 9 502 | 14 090 |
| Kierowca | 7 636 | 8 188 |
| Drzewo liściaste | 2 284 | 2 752 |

### Koszt renderowania

Liczniki viewportu z tej samej maszyny. Zbliżenie w formacie telefonu używa ustawień kamery danej wersji. Pozostałe ujęcia zachowują wspólne kadry. Liczniki pozwalają porównać obciążenie sceny. Pomiar FPS, zużycia energii i instalacja APK na fizycznym Androidzie pozostają do wykonania.

| Ujęcie | Wywołania 0.3.1 | Wywołania 0.3.2 | Prymitywy 0.3.1 | Prymitywy 0.3.2 |
| --- | ---: | ---: | ---: | ---: |
| Start, 756 × 1344 | 271 | 282 | 92 229 | 96 821 |
| Mapa za dnia, 1440 × 960 | 360 | 373 | 102 061 | 99 673 |
| Stacja nocą, 1440 × 960 | 306 | 313 | 111 751 | 108 737 |
| Rozbudowany kompleks, 1728 × 1010 | 464 | 478 | 117 415 | 124 355 |

Lokalny APK ma 68 812 692 bajty. SHA-256 pliku to `1105c169e28b970c155ec3743eb162d199627b94581d2c8507a6e9a72e2dced8`. Certyfikat jest zgodny z lokalnym testowym APK 0.3.1. Zweryfikowano integralność archiwum i wyłączenie galerii z eksportu.

### APK z GitHuba

Pakiet pobrany z wydania `v0.3.2` zbudowanego z commitu `8cc68eb` ma 68 812 692 bajty. SHA-256 `0f45b22dc21ca33b992be26342f9ece590476ba4fe14e87b04d09a409ed51fc6` zgadza się z sumą publikacji. `apksigner` potwierdził v2 i v3, a manifest wskazuje wersję 0.3.2, kod 5, architektury arm64-v8a i x86_64 oraz brak uprawnienia do internetu. Wydanie ma nowy certyfikat debug. Android wymaga zgodnego certyfikatu przy aktualizowaniu wcześniej zainstalowanej kompilacji. [Wydanie GitHub](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v0.3.2) · [Przebieg GitHub Actions](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45597974439)

## 0.3.1 · Modernizacja wizualna

Godot 4.7.2 Stable, Blender 4.3.2 oraz Mesa llvmpipe z rendererem Compatibility. Zrzuty pochodzą z uruchomionej sceny, plansz modeli i testu sterowanego kliknięciami. Przejrzano widoki dzienny, nocny, telefon, tablet i rozbudowany kompleks. W drugiej iteracji skorygowano import kolorów GLB i jasność materiałów. Kolejna próba sprawdziła połączenia nasypów z terenem oraz grupowanie dachów.

| Weryfikacja | Wynik |
| --- | --- |
| Import projektu i uruchomienie GL Compatibility | Zakończone |
| Ekonomia, zapis i dochód offline | 63/63 |
| Ruch i rezerwacje stanowisk | 23/23 |
| Symulacja balansu z raportem | 46/46 |
| Pętla rozgrywki bez okna | 26/26 |
| Pętla rozgrywki w oknie z kliknięciami, myjnią, obsługą TIR i tabletem | 34/34 |
| Test oprawy i progów dachów bez okna | 90/90 |
| Test oprawy z zapisem 16 kadrów z silnika | 106/106 |
| Porównanie kamery w trzech ustawieniach | 3/3 |
| APK debug 0.3.1 | Podpis v2/v3, arm64-v8a i x86_64, portret, min. API 24, cel API 36 |

W 20-minutowym teście ruchu ukończono 253 obsługi we wszystkich ośmiu usługach. Sześć pojazdów zrezygnowało lub ominęło obsługę. Automatyczne odblokowanie rezerwacji nie było potrzebne. Test sceny potwierdził wybór stanowiska, tankowanie, zakup ulepszenia, zatrudnienie, uruchomienie myjni na rzeczywistym kliencie, zmianę języka, tryb 30 FPS i odczyt zapisu.

### Koszt renderowania

Liczniki viewportu z tej samej maszyny testowej. Zbliżenie startowe używa kamery wybranej dla każdej wersji. Ujęcia dzienne mapy i nocne stacji używają tych samych kadrów porównawczych.

| Ujęcie | Wywołania przed | Wywołania po | Prymitywy przed | Prymitywy po |
| --- | ---: | ---: | ---: | ---: |
| Start gry, 756 × 1344 | 301 | 271 | 86 799 | 92 229 |
| Mapa dzienna, 1440 × 960 | 395 | 360 | 94 345 | 102 061 |
| Stacja nocą, 1440 × 960 | 350 | 306 | 106 973 | 111 751 |
| Pełna rozbudowana mapa, 1728 × 1010, przed i po grupowaniu dachów | 656 | 464 | 135 263 | 117 415 |

Tryb oszczędny ogranicza lokalne źródła światła do trzech, upraszcza emitery, wyłącza animację traw i szyldów oraz zmniejsza skalę obrazu 3D. Wyniki wydajności i instalacji na fizycznym Androidzie wymagają urządzenia.

APK ma 66 243 265 bajtów. SHA-256 pliku to `f0bf9651a04ba58a731b3f108bb3ff2b687da8cdfdc58f3ed69230f44143405f`. Kolaż i galeria są wyłączone z eksportu. APK z tej próby ma podpis debug wygenerowany w środowisku lokalnym. Android wymaga zgodnego podpisu przy aktualizacji pakietu z wydania 0.3.0 pobranego z GitHuba.

[Zrzuty z silnika](screenshots/README.md) · [Ocena wizualna](ART_DIRECTION.md)

## 0.3.0 · Kompleks Idle Tycoon

Środowisko używało Godot 4.7.2 Stable na Debianie i OpenGL Compatibility z Mesa llvmpipe. Test sceny głównej korzysta z własnego pliku profilu, wykonuje kliknięcia w prawdziwe kontrolki i ogląda działające modele usług.

| Zestaw | Wynik |
| --- | --- |
| Ekonomia, pracownicy, karty, wydarzenia i zapis | 63/63 |
| Ruch, 19 stanowisk i rezerwacje | 23/23 |
| Symulacja bez płatności, trzy ziarna i sześć horyzontów | 46/46 |
| Pętla gry bez okna | 26/26 |
| Pętla gry w oknie, w tym zdjęcia i układ tabletu | 34/34 |
| Regresja oprawy i światła bez okna | 52/52 |
| Eksport APK debug 0.3.0 | Podpis v2/v3 zweryfikowany, arm64-v8a i x86_64, bez uprawnienia do internetu |
| Kompilacja i publikacja APK debug przez GitHub Actions | Pobrano APK z wydania `v0.3.0`. Zgodność SHA-256, podpis v2/v3, wersja i obie architektury potwierdzone. [Przebieg](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45584178197) |
| Kompilacja opcjonalnego modułu reklamowego | Gradle 8.13 zakończył `assembleRelease` i wytworzył AAR |
| Testowy eksport Android z reklamą | Gradle z szablonu Godot zapakował moduł, a w podpisanym APK sprawdzono rejestrację wtyczki, oba testowe identyfikatory i uprawnienie do internetu |
| Działanie na fizycznym Androidzie | Próba instalacji, wyświetlenie reklamy i pomiar FPS wymagają urządzenia |

W 20-minutowej próbie ruchu obsłużono **253 klientów** we wszystkich ośmiu usługach. Sześciu klientów zrezygnowało lub odjechało bez obsługi. Maksymalnie sześć pojazdów zajmowało dwie kolejki. Po odcięciu przyjazdów każdy pojazd opuścił teren, a wszystkie rezerwacje zostały zwolnione bez interwencji awaryjnej. Osobny test z celową przeszkodą potwierdził zwolnienie zablokowanego wjazdu.

Test zapisu obejmuje stare profile 0.1–0.2, wartości 200-cyfrowe, powrót z pliku tymczasowego po przerwanym zapisie, kopię po uszkodzeniu pliku głównego oraz ochronę nowszego schematu. Test offline sprawdza limit ośmiu godzin, powtarzane i cofnięte czasy, weryfikację monotoniczną oraz jednokrotne przyjęcie potwierdzenia nagrody.

[Galeria rozgrywki](docs/gameplay-0.3.0/README.md) · [Raport symulacji](docs/balance-0.3.0.md)

## 0.2.0 · Przebudowa oprawy

Godot 4.7.2 Stable, Blender 4.3.2 i Mesa llvmpipe z rendererem Compatibility. Przejrzano zbliżenia oraz przebieg gry w trybach telefonu i tabletu.

| Weryfikacja | Wynik |
| --- | --- |
| Import zasobów z nowymi scenami GLB i start sceny głównej | Zakończone |
| Test rozgrywki i zapisu bez okna | 24/24 |
| Test rozgrywki w oknie, w tym układ tabletowy | 29/29 |
| Testy oprawy bez okna | 52/52 |
| Testy oprawy w oknie | 67/67, w tym 15 zapisanych zrzutów |
| Eksport i podpis debug Androida | 0.2.0, min. API 24, cel 36, v2/v3, arm64-v8a i x86_64 |
| Zawartość APK | 56 importów GLB, katalog pojazdów, orientacja pionowa, bez uprawnienia do internetu |
| Pomiar FPS i uruchomienie Androida na sprzęcie | Niewykonane w środowisku chmurowym |

Testy oprawy sprawdzają światła i kierunkowskazy, obrót kół, obecność 20 modeli, szkielet i dziewięć animacji dla każdej roli, pozycję kończyny w biegu, wąż przy tankowaniu, cztery ustawienia światła, cykl wody i piany oraz osobny moduł na każdym poziomie. Zapisy są izolowane od profilu gracza. Test awaryjnego zapisu odtwarza spodziewany komunikat parsera. Sterownik wirtualny zgłasza brak zmiany V-Sync.

## Pomiar sceny

| Kadr renderera Compatibility | Wywołania rysowania | Przetworzone prymitywy |
| --- | ---: | ---: |
| Stacja na telefonie 756 × 1344, dzień | 393 | 103 925 |
| Cała lokalizacja 1440 × 960, dzień | 506 | 125 125 |
| Stacja i część otoczenia 1440 × 960, noc | 470 | 151 065 |

Instancje kół i przewodów ograniczyły liczbę wywołań w porównaniu z pierwszym renderem tego etapu. Import Godota ma włączone generowanie geometrii LOD. Profil 30 FPS obniża rozdzielczość renderu 3D do 80%, pozostawiając HUD w pełnej rozdzielczości i ograniczając emitery oraz lokalne światła. Liczniki viewportu opisują obciążenie sceny na Linuxie. Wydajność GPU i zużycie energii na telefonie wymagają osobnego pomiaru.

[Galeria z silnika](docs/art-gallery/README.md) · [Ocena modeli i materiałów](ART_DIRECTION.md)

## Weryfikacja 0.1.0 · Pierwsza grywalna stacja

Testy wykonano w Godot 4.7.2 Stable na Debianie 13. Tryb okienkowy korzystał z renderera Compatibility i Mesa llvmpipe pod Xorg.

| Sprawdzenie | Wynik |
| --- | --- |
| Import zasobów i uruchomienie sceny głównej | Zakończone |
| `godot --headless --path . --script tests/station_smoke.gd` | 24/24 |
| Test okienkowy z odczytem renderu viewportu | 29/29, w tym cztery zapisane PNG i sprawdzenie przycisków na tablecie |
| Android SDK Build Tools 36.0.0, Java 21, eksport debug | Kod wyjścia 0 |
| Podpis debug, identyfikator pakietu, orientacja, ABI i uprawnienia | Podpis v2/v3 poprawny, pakiet `pl.krystiandevelopment.highwaytycoon`, portret, arm64-v8a i x86_64, bez uprawnienia do internetu |
| Instalacja na Androidzie, próba na iOS i wydajność 60 FPS na urządzeniu | Niewykonane, brak podłączonego urządzenia i emulatora |

Test wykonuje kliknięcia głównych przycisków, przejazd klientów, odmowę ponownego rozpoczęcia tankowania w trakcie obsługi, animację i postęp tankowania, wypłatę, zakup wszystkich poziomów, limit ulepszeń, zmianę języka i trybu FPS oraz ponowny odczyt stanu. Uszkodzenie testowego pliku zapisu celowo wywołuje komunikat parsera i potwierdza wczytanie kopii. Sterownik wirtualnego ekranu zgłasza brak zmiany trybu V-Sync.

### Zrzuty z wersji 0.1.0

- [Stacja po uruchomieniu](docs/screenshots/01-stacja.png)
- [Tankowanie w toku](docs/screenshots/02-tankowanie.png)
- [Ulepszenie i wersja angielska](docs/screenshots/03-upgrade-en.png)
- [Poziom 5 w układzie tabletowym 3:4](docs/screenshots/04-tablet.png)
