# Raport testów

## 0.9.0 · Release Candidate

Godot 4.7.2 na Linuksie x86_64. Próby zakupowe i reklamowe korzystały z kontrolowanych odpowiedzi. Okno Godota z Mesa llvmpipe rejestrowało rzeczywisty obraz i interakcję. [Audyt usterek i oceny](docs/RELEASE_AUDIT.md) · [Pomiary](docs/performance-0.9.0.md) · [Bezpieczeństwo](docs/SECURITY_RC.md)

| Próba | Wynik |
| --- | --- |
| Import całej gry, zasoby i tłumaczenia | 2275/2275. Wczytanie skryptów, modeli, scen, shaderów, obrazów, audio i fontów. Zgodność 592 kluczy PL i EN. |
| Ekonomia, zapis, stacja i samochody | 70/70 w gospodarce, 27/27 w stacji, 30/30 dla tras. |
| Misje, wydarzenia i kontrakty | 202/202 kariery, 64/64 ekspansji, 93/93 regionów. Logika obsługi i jednokrotnej wypłaty z 590 misji rozdziałowych. |
| Przejście okienkowe wszystkich map | 164/164. Realny atlas, obsługa usług, animacje, powrót do wcześniejszej lokalizacji i zarobki offline. |
| Grafika i prezentacja | 113/113 kontroli zasobów 3D, 278/278 danych i ustawień, 81/81 przejścia prezentacji w oknie. Próby niskiego, średniego, wysokiego i Ultra. |
| Dostępność i układ | 15/15 ustawień na trzech proporcjach z wcięciami. 11/11 dla dwóch rozmiarów tabletu i angielskiego tytułu. |
| BOOST, reklamy i sklep | 86/86 granicy logiki. 49/49 w oknie. Potwierdzenie przyznania, odmowy i braku sieci na adapterze testowym. |
| Kampania i monetyzacja | 55/55 kampanii bez reklam i płatności, 21/21 przebiegów z różnym użyciem reklam lub pakietów. [Balans](docs/balance-0.9.0.md) |
| Ruch pod obciążeniem i presety | 241/241. Dodatkowe 4/4 dla symulacji 20, 50, 100 i 200 pojazdów. Cztery regionalne próby ruchu po 25 symulowanych minut bez odzyskiwania zakleszczonych tras. |
| Zapis obu starszych wersji | Dwa zapisy utworzono oryginalnym kodem. 6/6 odczytu dla każdego z 0.7.0 i 0.8.0. Weryfikacja zachowała sześć map, waluty, postęp, menedżerów, zdarzenia, BOOST i trwałe uprawnienia. |
| Przerwanie zapisu i procesu | Uszkodzony plik główny i częściowy zapis odzyskane z kopii. Rzeczywiste `SIGKILL` na Linuksie pozostawiło poprawny zapis oraz kopię. Ponowne uruchomienie odczytało sześć regionów. |
| Weryfikator | 15/15 testów z kontrolowanym dostawcą Google. Lokalny HTTPS przekazał do WSGI zapytania, które otrzymały oczekiwane statusy 200, 401, 404 i 400 dla zbyt dużej treści. |
| Podpis Android | Testowy APK ARM64 kod 9000 z certyfikatem 0.7.0 i 0.8.0. Target API 36, min. 24, wyrównanie ZIP i ELF 16 KiB. |
| Materiały | 88 ujęć po zmianach, 15 bazowych, porównanie, 616 klatek filmu, grafika promocyjna, ikona i 12 zrzutów karty Google Play. [Galeria](screenshots/0.9.0/README.md) · [Materiały](release/play/README.md) |

Pełna próba przez 900 s na Linuksie przy zmianach map co 45 s miała 107 obsłużonych klientów, 92 zakończone wyjazdy, 16 podróży, 4 restarty sceny, 129 otwarć paneli i 29 wymuszonych zapisów. Zaliczyła 21/22 warunków. Wyjazdy pozostały poniżej progu 100. Powtórka co 90 s zaliczyła 18/18 sprawdzeń i 110 zakończonych wyjazdów. [Stabilność](docs/stability-0.9.0.md)

W próbach nie było dostępnego fizycznego Androida. Certyfikat i odczyt zapisów potwierdzono oddzielnie. Próby instalacji z Play, wydajność sprzętowa, faktyczne reklamy SDK, formularz UMP, testy z kontem licencyjnym i podpisany produkcyjny AAB pozostają otwarte. [Instrukcja testów w Play](docs/PLAY_CONSOLE_RC.md)

## 0.8.0 · Wydajność, stabilność i Android

Godot 4.7.2 Stable, Linux x86_64, izolowane profile i rzeczywiste renderowanie Mesa w próbach okienkowych. Bazę do pomiaru stanowił osobny checkout `aec0754`. [Wydajność](docs/performance-0.8.0.md) · [Stabilność](docs/stability-0.8.0.md) · [Galeria i film](screenshots/0.8.0/README.md)

| Próba | Wynik |
| --- | --- |
| Profile, pamięć wyboru ręcznego, oszczędzanie baterii, Boost po pauzie, 41 dokładnych kosztorysów, obciążenie 20–200 pojazdami | 241/241 |
| Czas dispatchera z 20, 50, 100 i 200 rzeczywiście aktywnymi instancjami | 4/4 w obu wersjach |
| 30 minut i 120 minut na 41 maksymalnie rozwiniętych usługach | Dwa rzeczywiste przebiegi headless, po 33/33. Końcowa próba miała 941 wyjazdów, 936 rozliczeń i 32 podróże. |
| Końcowe rundy w renderowanej grze | Trzy pełne rundy. Jedna aktywna scena i stabilne liczniki węzłów, zasobów oraz alokatora po powrocie. |
| Trzy rozmiary okna i zasymulowane wcięcia, ekran diagnostyczny i panel FPS | 15/15, bez pozostających uchwytów audio przy zamknięciu |
| Autentyczny zapis 0.7.0, uszkodzony plik i niedokończony zapis | 7/7 na oryginalnym kodzie przy tworzeniu, 6/6 przy migracji i odzyskiwaniu |
| Rzeczywiste nagłe zamknięcie procesu na Linuksie | `SIGKILL`, kod 137, dwie poprawne kopie i nowy start z tym samym plikiem |
| BOOST, tryb offline, kontrakty i lokalne rozliczenia | 67/67, 69/69 dla gospodarki i zapisu, 93/93 dla regionów |
| Przeciętny ruch, stacja, grafika i animacje | 30/30, 27/27 i 113/113 |
| Kampania, kariera, UI i wczytanie od tytułu | 202/202 i 44/44 dla kariery. 278/278 i 49/49 dla prezentacji. Zimny start zaliczony. |
| Ekspansja i przebiegi ekonomii | 64/64 i 45/45 dla ekspansji, po 45/45 dla bazowej, Desert i pełnej kampanii, 20/20 dla monetyzacji. |
| Weryfikator płatności i kopia SQLite | 10/10 testów. Lokalny Caddy przesłał poprawnie HTTPS do WSGI, blokował niedozwolone trasy i zbyt duże żądania. |
| Obraz i film | 35 nowych ujęć, 12 ujęć odniesienia, 608 klatek filmu. Próba potwierdziła opłaconą dostawę i przejazd do Green Valley. |
| APK | Oba ABI mają osobne pliki z kodem 8000, stałym certyfikatem, min API 24, target API 36 i potwierdzoną zgodnością ELF/ZIP 16 KiB. |

ADB i oficjalne emulatory nie udostępniły działającego urządzenia w Cloud. Weryfikacja reklam, rzeczywistych transakcji Play, instalacji, powrotu z tła na Androidzie, temperatury i FPS poszczególnych telefonów pozostaje otwarta. Przepływ płatności w bieżących próbach korzystał z kontrolowanych odpowiedzi. Publiczny weryfikator oraz AAB wymagają konfiguracji właściciela. [Android QA](docs/ANDROID_QA.md) · [Podpis](docs/ANDROID_SIGNING.md) · [Rozmiar](docs/app-size-0.8.0.md) · [Status etapu](docs/STAGE7_STATUS.md)

## 0.7.0 · BOOST, sklep i przepustka

Godot 4.7.2 uruchomiono na Linuksie z odizolowanymi zapisami i rendererem Compatibility (Mesa llvmpipe). Do kompilacji kodu natywnego użyto Android SDK 36 i JDK 21. [Galeria 30 ujęć i film](screenshots/0.7.0/README.md) · [Balans](docs/balance-0.7.0.md) · [Stan etapu](docs/STAGE6_STATUS.md)

| Próba | Wynik |
| --- | --- |
| Uprawnienia reklamowe, 5 minut i limit 30 minut, wielokrotne zdarzenie, restart, zmiana czasu, przełączanie map, dochód na żywo i offline, zakupy i zapis | 67/67 |
| Rozgrywka w oknie, panel BOOST, sklep, kalendarz, przepustka, pojazdy bonusowe i wariant offline | 49/49, w tym 30 zrzutów |
| Weryfikator zakupów WSGI i SQLite z kontrolowanymi odpowiedziami Play, stany oczekujące, ponowienia, spójność konta i zwroty | 9/9 |
| Cztery scenariusze ekonomii w horyzontach 1 h, 1 dzień, 7 i 30 dni | 21/21 |
| Autentyczny profil z tagu `v0.6.1` | 5/5 przy przygotowaniu, 6/6 po migracji do schematu 8 i ponownym uruchomieniu |
| Ekonomia i zapis, ruch, stacja, grafika i animacje | 69/69, 30/30, 27/27, 113/113 |
| Obsługa kariery i prezentacja gry, w tym rzeczywiste przejścia w oknie | 202/202, 44/44, 278/278, 49/49 oraz zimny start zaliczony |
| Regiony, ekspansja i trzy dotychczasowe przebiegi balansu | 93/93, 64/64, 45/45 oraz po 45/45 dla Stacji Północ, Desert Highway i kampanii |
| Film w Movie Maker | 385 klatek, 486 × 864, 30 FPS, H.264 i AAC. Naliczono 70 zł przy bazowej stawce 35 zł. |

Testy okien i nagranie podają kontrolowane, jawnie oznaczone zdarzenia na granicy adaptera SDK. Sprawdzają m.in. anulowanie bez wypłaty, podwójną dostawę potwierdzenia oraz rozliczenie offline proporcjonalnie do aktywnego BOOST. Próbę offline wykonano bez mostu reklamowego. Model bez płatności i reklam otworzył wszystkie sześć lokalizacji i 41 usług do siódmego dnia symulacji.

Podpisany APK przeszedł kontrolę archiwum, klas natywnego mostu, manifestu i podpisu v2/v3. Ma `applicationId` `pl.krystiandevelopment.highwaytycoon`, kod `7000`, obsługuje `arm64-v8a` i `x86_64` oraz ma ten sam certyfikat co lokalne `0.6.1` (kod `6001`). Emisja reklamy, formularz UMP, zakup z testowym kontem Play i aktualizacja na fizycznym Androidzie pozostają do sprawdzenia. W środowisku nie było osiągalnego urządzenia ani emulatora z akceleracją. AAB wymaga konfiguracji właściciela. [Podpis](docs/ANDROID_SIGNING.md) · [Google Play Billing i bezpieczeństwo](docs/PLAY_BILLING.md) · [Data Safety](docs/DATA_SAFETY.md)

## 0.6.1 · Sześć lokalizacji

Godot 4.7.2 Stable zaimportował projekt i uruchomił próby na Linuksie. Do testów użyto izolowanych profili. Renderowanie okien działało w Compatibility na Mesa llvmpipe. [Galeria 51 kadrów i film](screenshots/0.6.1/README.md) · [Balans kampanii](docs/balance-0.6.1.md) · [Wydajność](docs/performance-0.6.1.md)

| Próba | Wynik |
| --- | --- |
| Ruch, lokalne kontrakty, misje, menedżerowie, zapis sześciu regionów i rozliczenia Metro | 93/93 |
| Gra w oknie, rzeczywiste podróże przez atlas, aktywni pracownicy, płatności i 51 ujęć | 164/164 |
| Kampania 30 dni w trzech przebiegach i sześciu horyzontach | 46/46, 41 czynnych usług do siódmego dnia |
| Autentyczny zapis z tagu `v0.6.0` | 5/5 przy przygotowaniu na starym kodzie, 6/6 przy migracji i ponownym odczycie |
| Trasy Stacji Północ, rezerwacje i cierpliwość | 30/30 |
| Ekonomia, zapis i awaryjne odtwarzanie | 69/69 |
| Gra na stacji oraz kontrola grafiki i animacji | 27/27 i 113/113 |
| Kariera, starsze migracje i pełne przejście karierowe | 199/199 i 44/44 |
| Preferencje, dźwięk, kalendarz, panele i zimny start | 278/278 i 49/49, zimny start zaliczony |
| Podróże Copper Mile, sezonowe programy, kontrakty, kolekcje i prestiż | 64/64 i 45/45 |
| Regresja balansu North i Desert, bez zapisu dodatkowego pliku raportowego | 45/45 i 45/45 |
| Próba wydajności sześciu lokalizacji i trzech ustawień jakości | 112/112, 18 próbek klatek i maksimum RSS |
| Nagranie w Movie Maker | 605 klatek, 486 × 864 przy 30 FPS, H.264 i dźwięk stereo AAC. Test potwierdził rozliczenie dostawy. |

| Nowa trasa | Wyjazdy w 25 min próby | Awaryjne usuwanie | Szczyt kolejki |
| --- | ---: | ---: | ---: |
| Green Valley | 145 | 0 | 3 |
| Alpine Pass | 130 | 0 | 3 |
| Ocean Coast | 141 | 0 | 3 |
| Metro City | 235 | 0 | 5 |

Każda nowa usługa przeszła osobną próbę z wjazdem, rezerwacją, pracownikiem, płatnością i zwolnieniem stanowiska. Mieszane próby rozliczyły lokalne kontrakty. Magazyn i logistyka utrzymały stan równy przyjęciom pomniejszonym o wydania. Salon testował sprzedaż oraz odnowę zapasu. Crossline zarejestrowało obsłużonych kupujących. Wszystkie cztery nowe biznesy pokazują pięć stanów geometrii.

Próby zapisu potwierdziły lokalny koszt pierwszej podróży, wycofanie przy nieudanym zapisie, powrót z ulepszeniami i pojedynczą wypłatę offline. W migracji porównano rzeczywiste pola obu gospodarek, kontrakty, posiadane karty, załogi, kalendarz, misje, waluty i preferencje. Nowe zapisy mają schemat 7.

APK przeszedł kontrolę integralności. `applicationId` to `pl.krystiandevelopment.highwaytycoon`, a `versionCode` to `6001`. Certyfikat zgadza się ze stabilnym lokalnym podpisem `0.5.0` i `0.6.0`. Kontrola manifestów potwierdziła rosnący kod, Android od API 24 oraz architektury arm64-v8a i x86_64. Próba instalacji i pomiary na fizycznym Androidzie pozostają otwarte. [Podpis i dystrybucja](docs/ANDROID_SIGNING.md)

## 0.6.0 · Ekspansja Copper Mile

Godot 4.7.2 Stable, Compatibility, Linux i Mesa llvmpipe. Import oraz wszystkie próby przeprowadzono z izolowanymi ścieżkami danych. Blender 4.3.2 wyeksportował 31 nowych modeli. [39 zrzutów z silnika](screenshots/0.6.0/README.md) · [Balans](docs/balance-0.6.0.md) · [Wydajność](docs/performance-0.6.0.md)

| Próba | Wynik |
| --- | --- |
| Kampania, opłata za wjazd, offline, wydarzenia, kontrakty, kolekcje i prestiż | 64/64 |
| Przejście ekspansji bez okna | 45/45 |
| Przejście w oknie | 84/84, w tym 39 kadrów |
| Balans Copper Mile, trzy ziarna i sześć horyzontów | 46/46 |
| Balans Trasy 17 | 46/46, raport identyczny z 0.4.0 |
| Ekonomia i awaryjne odzyskiwanie zapisu | 69/69 |
| Ruch na Trasie 17 | 30/30 |
| Gra na stacji, geometria i animacje | 27/27, 113/113 |
| Kariera, zapis i gra w kompleksie | 192/192, 44/44 |
| Kalendarz 0.5.0, odznaki, miks i przejście interfejsu | 278/278, 49/49 |
| Migracja pliku utworzonego przez 0.5.0, commit `e121e14` | Zgodność 29 pól, w tym otwarta usługa, awans pracownika, menedżer, kalendarz, odznaki, oczekujące offline i preferencje. Kolejny zapis ma schemat 6. |
| Podpisany APK 0.6.0 | Ten sam identyfikator i certyfikat co lokalny 0.5.0. Kod 6000 wobec 7. Zgodność podpisu v2/v3, Android od API 24, arm64-v8a i x86_64, manifest z `VIBRATE`. |

W odrębnej próbie mieszanego ruchu Desert Highway ukończono 182 przejazdy przy szczycie pięciu pojazdów w kolejce i zerze awaryjnych przerwań. Każda z dziesięciu usług zrealizowała osobną próbę z dojazdem, pracownikiem, płatnością i zwolnieniem stanowiska. Gra w oknie sprawdziła zakup dostępu przez atlas, powrót z zachowaniem ustawień i wypłatą offline, sześć paneli wydarzeń, kontrakt, kolekcję i anulowanie prestiżu. Próba stanu potwierdziła wykonanie resetu wyłącznie przy potwierdzeniu i jednokrotne wydanie nagród. Próba błędnego zapisu wycofała zmianę mapy.

Nagranie obejmuje 434 klatki 486 × 864 przy 30 FPS i ścieżkę stereo 48 kHz. Skrypt przechodzi z istniejącego profilu z kwalifikacją do Desert Highway, płaci za podróż, obsługuje klienta i kupuje poziom. [Nagranie](screenshots/0.6.0/podroz-copper-mile.mp4)

APK ma 76 247 383 bajty. SHA-256 `e1f718328619fb42d92a52f043c494b9d1419fe6d2163e78548f6906ff509c13`. Weryfikator pary wersji potwierdził zgodność lokalnej kompilacji 0.5.0 i odrzucił parę z GitHub 0.5.0 ze względu na odmienny podpis. Próba instalacji na Androidzie pozostaje otwarta. [Procedura podpisywania i migracji](docs/ANDROID_SIGNING.md)

Świeży import archiwum tagu `v0.6.0` przeszedł 64/64 kontroli kampanii i test zimnego startu. Przebieg GitHub Actions z commitu `af78f35` zatrzymał się na kontroli brakujących sekretów przed wygenerowaniem pakietu. [Przebieg publikacji](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45664015493)

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
