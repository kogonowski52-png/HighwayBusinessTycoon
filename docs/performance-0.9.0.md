# Wydajność i rozmiar · 0.9.0 RC

Dwa rzeczywiste uruchomienia okienkowe porównały bazę `b182d4f` z 0.9.0 RC. Host Linux x86_64 na Intel Xeon Platinum 8573C z limitem czterech CPU. Godot 4.7.2, Compatibility OpenGL Mesa llvmpipe na CPU, Xorg, okno 486 × 864. Stały skrypt rozwija usługi, zatrudnia pracowników, ustawia tę samą kamerę i zapisuje po 20 klatek na punkt. Współdzielony host i kompilacja shaderów wpływają na rozrzut krótkich serii. Wyniki dotyczą tego hosta i nie przewidują wydajności telefonów. [Dane 0.8.0](qa-0.9.0/performance-before.json) · [Dane 0.9.0](qa-0.9.0/performance-after.json)

## Wysoki profil i ta sama kamera

| Lokalizacja | FPS przed → po | Mediana klatki w ms | P95 w ms | RAM procesu w MiB | Szacunek pamięci renderera w MiB | Draw calls | Prymitywy |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 3,5 → 2,3 | 283,2 → 411,2 | 287,8 → 630,9 | 1142 → 820 | 64 → 65 | 721 → 721 | 115624 → 115624 |
| Desert Highway | 5,3 → 4,8 | 183,9 → 211,1 | 204,8 → 252,1 | 1203 → 919 | 61 → 60 | 562 → 562 | 72212 → 72212 |
| Green Valley | 6,5 → 6,4 | 146,2 → 149,0 | 176,4 → 181,6 | 1260 → 1000 | 63 → 62 | 388 → 388 | 56123 → 56123 |
| Alpine Pass | 5,9 → 6,6 | 166,4 → 143,9 | 181,4 → 184,0 | 1290 → 1042 | 62 → 61 | 329 → 329 | 50854 → 50854 |
| Ocean Coast | 7,6 → 6,1 | 130,7 → 171,9 | 133,4 → 187,4 | 1306 → 1042 | 63 → 62 | 359 → 359 | 52707 → 52707 |
| Metro City | 4,8 → 4,6 | 194,7 → 202,9 | 263,9 → 240,6 | 1362 → 1041 | 68 → 66 | 557 → 557 | 101160 → 101160 |

Pamięć renderera zwracana przez Godot nie jest pomiarem fizycznego VRAM. W raporcie `primitives` korzysta z licznika renderera dla widocznego przebiegu. Obejmuje prymitywy sceny oraz renderowanego interfejsu. Czasy klatki z dwóch krótkich serii wykazały duży rozrzut CPU. Liczba wywołań i prymitywów pozostaje w podobnym przedziale, a kandydat zachowuje szczegółowość modeli. [Kadry porównawcze](../screenshots/0.9.0/README.md)

## Czasy uruchomienia i podróży

| Zdarzenie | 0.8.0 | 0.9.0 RC |
| --- | ---: | ---: |
| Pierwsza kompletna klatka tytułu | 600 ms | 259 ms |
| Od naciśnięcia Graj do pierwszej klatki Northpoint | 11341 ms | 3640 ms |
| Desert Highway | 5100 ms | 1590 ms |
| Green Valley | 2909 ms | 1427 ms |
| Alpine Pass | 1175 ms | 701 ms |
| Ocean Coast | 1674 ms | 1046 ms |
| Metro City | 1575 ms | 882 ms |

Pierwsze przejścia mierzą oba uruchomienia z ich stanem cache. Dane startu podano jako pojedyncze próbki dla poszczególnych wersji. W trzech powrotach testowych na Stację Północ RC wykazał po 752 węzły i 932 zasoby. Po pierwszej rundzie Godot raportował 93,89 MB pamięci statycznej, po drugiej 93,89 MB. RSS hosta zmieniał się w zakresie około 1,06–1,07 GiB dla rozgrzanych przejść o tym profilu. Wyższy koszt względem części pomiarów 0.8.0 obejmuje wykonanie dodatkowych próbek Ultra i cache renderera. Na każdym odcinku test odnotował jedną aktywną scenę regionu. [Pomiary wszystkich profili](qa-0.9.0/performance-after.json)

## Obciążenie i poziomy detalu

| Liczba pojazdów | Mediana kroku CPU | P95 CPU |
| --- | ---: | ---: |
| 20 | 0,411 ms | 0,477 ms |
| 50 | 0,383 ms | 0,450 ms |
| 100 | 0,762 ms | 0,945 ms |
| 200 | 1,494 ms | 1,753 ms |

Czasy pochodzą z 240 kroków symulacji headless na tym samym hoście i nie obejmują renderowania. Testy czterech profili sprawdziły rozdzielczość renderowania, ręczny wybór i utrzymanie ustawień. Oszczędzanie energii ogranicza animację powierzchni wody, cząsteczki, pracę poza kadrem i czas renderowania. Fizyczny FPS, pamięć GPU, temperatura, dotyk, cykl życia i pobór baterii wciąż wymagają próby Androida.

## Rozmiar Androida

| Składnik | Testowy APK 0.8.0 ARM64 | Testowy APK 0.9.0 ARM64 |
| --- | ---: | ---: |
| Cały plik | 118 068 090 B | 118 345 221 B |
| Natywne biblioteki w ZIP | 77 555 944 B | 77 555 944 B |
| DEX | 8 463 491 B | 8 463 545 B |
| Dane w `assets/` | 30 655 375 B | 30 385 053 B |
| Manifest i pozostałe zasoby Androida | 1 074 689 B | 1 620 211 B |

Różnicę między sumą składników a plikiem wyjaśniają nagłówki ZIP, wyrównanie i podpis. Zmieniono zestaw ikon i usunięto z eksportu dwie dawne grafiki ekranu tytułowego. Preset Play pomija dokumentację, media, testy i skrypt diagnostyki. APK RC pozostaje poniżej 150 MB. Rozmiar pobieranych splitów AAB będzie dostępny po udanym podpisaniu i przygotowaniu w Google Play. [Zgodność Androida](PLAY_CONSOLE_RC.md)
