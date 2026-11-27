# Wydajność Advanced Gameplay

Pomiary 9004 i 9005 wykonano kolejno w tej samej maszynie Cloud. Godot 4.7.2, Compatibility i Mesa llvmpipe na Xeonie Platinum 8573C z limitem czterech rdzeni. Okno 486 × 864, profil Średni, skala renderowania 3D 88%, wyłączone MSAA, 72 klatki na region. Scenariusz uruchamia te same biznesy na poziomie 62, ruch z ustalonym ziarnem i ten sam kadr. Czas symulacji mierzy synchroniczny krok gry. Pełna klatka obejmuje także renderer i oczekiwanie na koniec wyświetlania.

| Region | FPS | Mediana klatki ms | P95 ms | Symulacja ms | Draw calls | Prymitywy | RSS MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 8,5 → 10,0 | 112,4 → 99,2 | 185,7 → 112,0 | 0,521 → 0,524 | 814 → 720 | 114 617 → 114 573 | 760 → 806 |
| Desert Highway | 14,1 → 13,9 | 69,3 → 68,5 | 80,2 → 106,9 | 0,412 → 0,395 | 634 → 444 | 65 326 → 66 152 | 779 → 865 |
| Green Valley | 16,3 → 16,6 | 60,4 → 60,9 | 69,8 → 66,5 | 0,338 → 0,340 | 433 → 323 | 71 401 → 75 947 | 781 → 898 |
| Alpine Pass | 19,6 → 18,7 | 50,5 → 52,6 | 57,5 → 62,2 | 0,288 → 0,283 | 356 → 251 | 51 654 → 57 596 | 782 → 917 |
| Ocean Coast | 17,2 → 18,2 | 56,5 → 54,4 | 70,2 → 66,5 | 0,358 → 0,325 | 382 → 262 | 48 960 → 50 346 | 782 → 927 |
| Metro City | 13,3 → 15,5 | 71,1 → 62,4 | 98,6 → 78,5 | 0,517 → 0,514 | 588 → 393 | 79 638 → 84 546 | 803 → 988 |

Po spakowaniu 221 modeli liczba wywołań rysowania spadła o 11,5–33,2% w sześciu kadrach. Geometria bazowa, normalne, kolor wierzchołków i oddzielne powierzchnie świecące zostały zachowane. Metaliczność i chropowatość są przechowywane w nieużywanym wcześniej kanale UV. Wstępny wariant z teksturą właściwości materiału powodował dodatkowy koszt na rendererze programowym. Profil Średni korzysta z jednej mapy cienia światła kierunkowego, a Wysoki i Ultra zachowują podział na kaskady. Silnik generuje LOD dla połączonych powierzchni, stąd różnice w liczbie prymitywów widocznych w kadrze.

Czas kroku gry stanowił poniżej 1% mediany całej klatki. W tym środowisku głównym kosztem było renderowanie programowe. FPS spadł w dwóch kadrach. Desert Highway o 1,9%, Alpine Pass o 4,6%. P95 w Desert Highway wzrósł z 80,2 do 106,9 ms.

Pierwsza klatka ekranu startowego zajęła 199 → 241 ms. Od rozpoczęcia ładowania do otwarcia Północy upłynęło 3 248 → 3 516 ms. Licznik pamięci renderera w sześciu kadrach 9005 pokazał 62,0–68,1 MiB. To wskaźnik silnika na Linuksie.

RSS obejmuje pamięć całego procesu z rendererem. Do wzrostu RSS w kolejnych kadrach przyczyniają się też rozgrzewanie i cache. Wskaźniki sterty oraz pamięci renderera zapisano osobno w surowych danych.

| Podróż do regionu | Wczytanie w ms, 9004 → 9005 |
| --- | ---: |
| Desert Highway | 1 788 → 1 486 |
| Green Valley | 939 → 987 |
| Alpine Pass | 771 → 785 |
| Ocean Coast | 769 → 915 |
| Metro City | 832 → 826 |

Test powrotu przez wszystkie dwanaście map utrzymał jedną scenę świata. Na Północy liczba węzłów po każdym obiegu wynosiła 822 → 822, RSS 888 → 946 MiB, a sterta silnika 108,8 → 108,8 MiB.

Wnętrza ładowane są asynchronicznie na żądanie. Pojazdy dostaw są dobierane z małej puli. Czas dostawy poza aktywnym regionem wynika z zapisanego terminu. Na fizycznym Androidzie do potwierdzenia pozostają czasy klatek, pamięć, temperatura i pobór energii. [Rozmiar APK](ANDROID_SIGNING.md#testowy-apk-095)

[Metryki 9004](qa-0.9.5/release-before.json) · [Metryki 9005](qa-0.9.5/release-after.json) · [Przejazd przez 12 map](qa-0.9.5/all-regions.json) · [Zrzuty porównawcze](../screenshots/0.9.5/porownanie/) · [Skrypt pomiaru](../tests/performance_window.gd)
