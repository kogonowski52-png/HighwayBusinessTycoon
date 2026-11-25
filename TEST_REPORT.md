# Raport testów

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
