# Wydajność World Expansion

Pomiary wykonano w Godot 4.7.2 na Linuksie x86_64, na procesorze Xeon Platinum 8573C z limitem czterech rdzeni w cgroup. Mesa 25.0.7 i llvmpipe wykonywały rysowanie programowo w OpenGL 4.5. Obie wersje używały Compatibility, portretowego okna 486 × 864, profilu Średni, skali 3D 88% i wyłączonego MSAA. Skrypt rozwijał biznesy do poziomu 62, uruchamiał ruch z tym samym ziarnem i ustawiał kadr na paliwa każdej lokalizacji. Próby 0.9.3 i 0.9.4 wykonywano kolejno, po 72 klatki na region. Nazwy kolumn pamięci odpowiadają licznikom procesu i silnika. [Pomiar 0.9.3](qa-0.9.4/matched-before.json) · [Pomiar 0.9.4](qa-0.9.4/matched-after.json) · [Skrypt](../tests/performance_window.gd)

## 0.9.3 → 0.9.4

| Lokalizacja | FPS | Mediana ms | P95 ms | Draw calls | Prymitywy widoczne | RSS MiB | Pamięć renderera MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 10,1 → 9,3 | 98,7 → 104,5 | 108,1 → 142,2 | 782 → 814 | 112 889 → 114 617 | 679 → 682 | 63,7 → 64,2 |
| Desert Highway | 15,1 → 13,4 | 65,4 → 72,8 | 75,3 → 83,2 | 570 → 634 | 58 326 → 65 326 | 701 → 696 | 62,1 → 64,1 |
| Green Valley | 13,8 → 14,5 | 69,5 → 67,2 | 119,3 → 92,1 | 412 → 433 | 73 865 → 71 401 | 717 → 716 | 62,0 → 61,8 |
| Alpine Pass | 17,6 → 19,4 | 55,9 → 51,1 | 60,5 → 54,8 | 348 → 356 | 54 492 → 51 654 | 721 → 721 | 61,4 → 61,1 |
| Ocean Coast | 16,7 → 15,9 | 57,2 → 60,6 | 76,7 → 77,7 | 366 → 382 | 51 676 → 48 960 | 742 → 721 | 62,9 → 62,5 |
| Metro City | 13,9 → 13,3 | 71,0 → 73,7 | 93,0 → 104,3 | 573 → 588 | 83 404 → 79 638 | 753 → 742 | 67,4 → 67,0 |

W tym przebiegu Green Valley i Alpine Pass przyspieszyły. Stacja Północ, Desert Highway, Ocean Coast i Metro City zwolniły odpowiednio o 8,1%, 11,1%, 4,6% i 4,0%. Modernizacja zwiększa liczbę wywołań rysowania na rozbudowanych działkach. W Desert Highway kadr miał też około 12% więcej prymitywów. Woda korzysta z wypalonej mapy fal, nawierzchnie ze współdzielonych materiałów i partii. Katalog pojazdów trzyma najwyżej 24 ostatnio użyte sceny. Wcześniejsza 36-klatkowa próba dała inny rozkład spadków, w tym większy spadek Ocean Coast. Wyniki programowego renderowania zależą od obciążenia CPU. [Krótszy przebieg 0.9.3](qa-0.9.4/compare-before.json) · [Krótszy przebieg 0.9.4](qa-0.9.4/compare-after.json)

## Nowe lokalizacje

Oddzielny przebieg używał 36 klatek na mapę, profilu Średni oraz przejazdu przez wszystkie dwanaście kompleksów. W tabeli podano również czas zmiany regionu, łącznie z animacją podróży.

| Lokalizacja | FPS | P95 ms | Draw calls | Prymitywy widoczne | Podróż ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Tropical Island | 17,4 | 64,8 | 407 | 46 648 | 898 |
| Route 66 | 24,8 | 45,0 | 325 | 24 450 | 726 |
| Industrial Harbor | 24,5 | 44,8 | 320 | 29 264 | 810 |
| Luxury City | 17,8 | 60,7 | 460 | 49 120 | 683 |
| Japan Highway | 18,6 | 67,6 | 462 | 44 612 | 771 |
| Northern Wilderness | 19,3 | 60,0 | 359 | 42 364 | 966 |

## Uruchomienie, podróże i pamięć

| Pomiar | 0.9.3 → 0.9.4 |
| --- | ---: |
| Pierwsza klatka ekranu startowego, ms | 165 → 165 |
| Od rozpoczęcia ładowania do gry, ms | 3 186 → 2 751 |
| Podróż do Alpine Pass, ms | 662 → 679 |
| Podróż do Desert Highway, ms | 713 → 779 |
| Podróż do Metro City, ms | 708 → 734 |
| Podróż do Ocean Coast, ms | 790 → 627 |
| Podróż do Green Valley, ms | 661 → 626 |

Powrót na Północ po kolejnych podróżach utrzymał 821 węzłów i dokładnie jedną aktywną scenę gry. RSS procesu zmienił się z 841,4 na 829,6 MiB, a pamięć raportowana przez silnik z 104,9 na 104,9 MiB. Licznik renderera zmienił się z 72,3 na 74,5 MiB. Próba obejmuje jeden pełny obieg po pomiarze rozgrzewkowym. Długi pobyt na urządzeniu może dać inny wynik.

APK ARM64 urósł z 126 256 615 do 155 988 497 bajtów, czyli o 23,5%, głównie przez geometrię nowych regionów, flotę i ilustracje. Galeria i film są poza eksportem. Instalacja 9004, FPS, pamięć GPU, temperatura i pobór energii nadal wymagają pomiaru na fizycznym Androidzie. [Galeria przed i po](../screenshots/0.9.4/README.md) · [Weryfikacja APK](ANDROID_SIGNING.md#testowy-apk-094)
