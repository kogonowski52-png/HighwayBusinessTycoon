# Wydajność · 0.7.0 i 0.8.0

Próby wykonano w renderowanym oknie Godota 4.7.2 na Cloud Linux x86_64. Maszyna miała procesor Intel Xeon Platinum 8573C, limit odpowiadający czterem vCPU i Mesa 25.0.7 llvmpipe. Główny test działał w OpenGL Compatibility, w tym samym oknie 486 × 864, na obu wersjach. 0.7.0 pochodzi z commitu `aec0754`. Każdą pozycję i profil testowano po rozgrzaniu przez 32 klatki z identyczną kamerą, przygotowanymi stanowiskami i wywołaniem symulacji 1/60 s na klatkę. Przez FPS rozumiemy przepustowość tych klatek. Liczniki VRAM są alokacjami widzianymi przez Godota w programowym sterowniku. Wyniki nie określają FPS ani rzeczywistej pamięci GPU telefonów. [Dane pomiarowe](performance-0.8.0.json) · [Porównanie obrazu](../screenshots/0.8.0/README.md)

## Porównanie sześciu lokalizacji

W każdej komórce podano 0.7.0 → 0.8.0. Mediany poniżej podsumowują sześć lokalizacji. Licznik prymitywów obejmuje trójkąty siatek 3D.

| Profil | FPS | Klatka, ms | P95, ms | Draw calls | Prymitywy | RAM procesu, MiB | Licznik VRAM, MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Niski | 15.30 → 19.87 | 63.5 → 49.3 | 81.6 → 62.1 | 475.0 → 463.0 | 64482 → 28997 | 874.6 → 798.2 | 81.2 → 58.5 |
| Średni | 12.68 → 13.28 | 74.6 → 71.6 | 109.6 → 98.4 | 483.0 → 472.5 | 64618 → 47650 | 875.1 → 807.8 | 81.9 → 59.2 |
| Wysoki | 5.24 → 4.52 | 183.7 → 206.3 | 243.1 → 281.1 | 485.5 → 471.0 | 66342 → 64144 | 878.3 → 808.0 | 85.9 → 63.2 |

We wszystkich sześciu lokalizacjach Niski skrócił medianę klatki, a jego łączna mediana spadła o około 22%. Wysoki zachowuje rozdzielczość 1.00 i 2× MSAA. Zyskał w czterech lokalizacjach, a Green Valley i Metro City miały dłuższe klatki w tej próbie. Średni skrócił medianę w pięciu lokalizacjach. W tym środowisku 30 ani 60 FPS nie został potwierdzony dla kompletnej kampanii. Godot raportował mniej pamięci graficznej po zwolnieniu poprzedniej sceny. Klasę telefonu i efekty termiczne trzeba zbadać na urządzeniu.

| Lokalizacja | Klatka Niski, ms | Klatka Średni, ms | Klatka Wysoki, ms | Draw calls Wysoki | Ładowanie po podróży, ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 145.0 → 71.0 | 144.1 → 92.8 | 343.0 → 293.9 | 705 → 718 | pierwsze wejście |
| Desert Highway | 66.2 → 53.2 | 78.9 → 73.9 | 193.3 → 192.6 | 574 → 554 | 1072 → 1417 |
| Green Valley | 55.2 → 46.4 | 61.9 → 69.7 | 172.9 → 220.0 | 389 → 388 | 862 → 926 |
| Alpine Pass | 60.9 → 41.4 | 62.8 → 58.3 | 174.1 → 144.7 | 328 → 329 | 719 → 741 |
| Ocean Coast | 57.8 → 44.1 | 73.5 → 52.8 | 170.2 → 148.2 | 397 → 373 | 615 → 770 |
| Metro City | 68.9 → 52.3 | 75.7 → 73.5 | 208.8 → 242.5 | 609 → 557 | 823 → 861 |

Od inicjalizacji bramki do pierwszej klatki tytułu zmierzono 207 → 183 ms. Od przycisku rozpoczęcia do pierwszej klatki Stacji Północ zmierzono 5291 → 3280 ms. W trakcie podróży pasek ładowania aktualizuje się podczas pobierania pakietów. Całkowity czas przejścia w tej próbie jest dłuższy na pięciu zmierzonych trasach. Etap przygotowania sceny nadal wymaga pracy w wątku głównym. Pierwszy proces bez rozgrzanej pamięci shaderów był wolniejszy. [Rozruch i tło testów](stability-0.8.0.md)

## Renderer

Na bazie 0.7.0 sprawdzono Mobile/Vulkan z Mesa lavapipe oraz Compatibility z llvmpipe. Porównanie przypadku Wysoki w Stacji Północ i Desert Highway zestawia osobne przebiegi z tym samym scenariuszem. Renderery raportują draw calls własną metodą liczenia. Większa przepustowość programowego Vulkan przy 2× MSAA wiązała się z większymi alokacjami i kompilacją potoku na zimnym starcie. Dla matrycy Androida zachowano GLES Compatibility do czasu porównania prawdziwych urządzeń. Okluzji runtime nie włączono, bo otwartą mapę ogląda się przeważnie z góry, a koszt takiej zmiany trzeba byłoby osobno zmierzyć na telefonie.

| Lokalizacja w 0.7.0 | Compatibility, klatka ms | Mobile/Vulkan, klatka ms | Compatibility, licznik MiB | Mobile/Vulkan, licznik MiB |
| --- | ---: | ---: | ---: | ---: |
| Stacja Północ | 343.0 | 105.7 | 67.1 | 204.4 |
| Desert Highway | 193.3 | 86.6 | 84.0 | 211.2 |

Niski używa skali 0.74, uproszczonych cieni, mniejszej emisji i limitu 30 FPS. Średni ma skalę 0.88, dwa podziały cienia i umiarkowane efekty. Wysoki utrzymuje skalę 1.00 i 2× MSAA. Ultra używa skali 1.00, 4× MSAA, czterech podziałów cienia i dalszej geometrii o wyższym poziomie szczegółów. Na tym sterowniku Ultra jest najkosztowniejszą opcją. Automatyka liczy rzeczywiste spóźnione klatki i nie zmienia ręcznego profilu. [Ustawienia w grze](../screenshots/0.8.0/README.md)

## Ruch poza kadrem

W osobnej próbie bez renderera 240 kroków tego samego ruchu wykonano na obu wersjach. Liczby obejmują rzeczywiste pojazdy produkcyjnego dispatchera i aktualizację instancji Godota. Niezależne pasy testowe unikają sztucznego przeciążania stanowisk w zwykłej kampanii. Jest to pomiar kodu CPU na Cloud.

| Aktywne pojazdy | Mediana kroku, ms 0.7.0 → 0.8.0 | P95, ms 0.7.0 → 0.8.0 |
| ---: | ---: | ---: |
| 20 | 0.523 → 0.402 | 0.561 → 0.449 |
| 50 | 2.179 → 0.373 | 2.330 → 0.423 |
| 100 | 7.613 → 0.733 | 8.162 → 0.845 |
| 200 | 35.724 → 1.446 | 64.936 → 1.572 |

Zmiana siatki ograniczyła porównania tras i aktualizację kół poza kamerą. Pula nie przechowuje więcej niż 24 gotowe instancje i najwyżej dwie na wariant modelu. Zwykłe rezerwacje obsługi pozostają testowane osobno.

## Rozmiar

Podpisany APK testowy spadł z 200.67 MB do około 118 MB. Główna zmiana to dostarczanie osobnego APK dla ABI. [Analiza archiwum](app-size-0.8.0.md)

```bash
godot --path . --script tests/performance_window.gd -- --report=/tmp/hbt-performance.json --roundtrips=3
godot --headless --path . --script tests/fleet_profile.gd
```
