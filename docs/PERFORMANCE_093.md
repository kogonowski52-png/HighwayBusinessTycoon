# Wydajność Premium Graphics 2.0

Porównanie 0.9.2 z commita dad4e74 i 0.9.3 w Godocie 4.7.2. Maszyna Cloud z procesorem Intel Xeon Platinum 8573C miała limit czterech rdzeni w cgroup. Renderowanie wykonywało Mesa llvmpipe 25.0.7 z OpenGL 4.5, bez sprzętowego GPU. Test używał portretowego okna 486 × 864, Compatibility, tego samego scenariusza zakupów, ruchu i ustawień kamery. Profil średni ma skalę 3D 0,88 i wyłączone MSAA. W każdym regionie zapisano 36 kolejnych klatek po rozgrzaniu widoku. Próba Ultra na Północy obejmowała 18 klatek w każdej wersji.

## Widok gry

| Lokalizacja i profil | FPS | Mediana klatki ms | P95 ms | Draw calls | Prymitywy | RSS MiB | Pamięć renderera MiB |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 8,1 → 9,8 | 104,4 → 100,5 | 254,0 → 112,4 | 720 → 782 | 89 502 → 112 903 | 680 → 767 | 61,0 → 63,7 |
| Desert Highway | 9,8 → 15,4 | 90,3 → 64,5 | 199,4 → 69,6 | 562 → 570 | 53 294 → 58 362 | 698 → 784 | 57,9 → 60,1 |
| Green Valley | 16,5 → 16,2 | 57,4 → 60,0 | 100,9 → 65,8 | 379 → 411 | 39 429 → 73 041 | 719 → 788 | 60,1 → 62,0 |
| Alpine Pass | 18,4 → 19,3 | 51,8 → 51,4 | 73,6 → 56,3 | 325 → 349 | 37 292 → 54 506 | 724 → 794 | 59,6 → 61,4 |
| Ocean Coast | 19,4 → 17,6 | 51,2 → 56,7 | 60,8 → 60,1 | 355 → 366 | 39 569 → 51 676 | 736 → 795 | 60,7 → 62,9 |
| Metro City | 13,5 → 12,5 | 72,5 → 75,7 | 120,8 → 123,4 | 546 → 573 | 70 806 → 83 404 | 784 → 820 | 64,6 → 67,3 |
| Stacja Północ · Ultra | 2,4 → 2,2 | 427,1 → 453,8 | 475,6 → 472,0 | 719 → 781 | 161 598 → 199 329 | 848 → 891 | 74,2 → 82,2 |

Wartości po strzałce pochodzą z 0.9.3. Pamięć procesu odczytano z Linuksa, a ostatnią kolumnę z licznika Godota. Pomiar programowy zależy od obciążenia CPU i stanu pamięci podręcznej. Liczba klatek spadła w 3 z 6 regionów od 2,1% do 9,1%. W 3 regionach wzrosła, najbardziej w Desert Highway o 57,5%.

Rozrzut między próbami był znaczny. W pierwszej, 18-klatkowej próbie Północy uzyskano 11,7 → 10,3 FPS, a w 36-klatkowej 8,1 → 9,8 FPS. Po zapisaniu końcowej tabeli skrypt pomiaru zgłosił 12 instancji i 3 zasoby podczas zamykania procesu. Wynik wyjścia wymaga oddzielnego pomiaru długiej sesji i pamięci na telefonie.

W standardowym kadrze Północy kontrola wizualna zarejestrowała 321 → 326 draw calls oraz 98 408 → 114 563 prymitywy. W szerokim kadrze rozbudowanego kompleksu zarejestrowano 682 → 744 draw calls oraz 144 530 → 188 406 prymitywów. Widać koszt nowych świetlików, wyposażenia, koron i dodatkowych stanowisk. Drzewa są grupowane w mniejszych komórkach, które silnik może pomijać poza kadrem. Tryb Ultra w teście miał skalę 1,00 → 1,10 oraz MSAA 4× w obu wersjach. Rzeczywista płynność, temperatura i pamięć GPU wymagają pomiaru na Androidzie.

## Wczytywanie

| Pomiar | 0.9.2 → 0.9.3, ms |
| --- | ---: |
| Pierwszy kadr tytułu | 151 → 145 |
| Tytuł do rozgrywki | 3 499 → 2 900 |
| Alpine Pass | 699 → 827 |
| Desert Highway | 1 489 → 1 936 |
| Metro City | 877 → 862 |
| Ocean Coast | 774 → 742 |
| Green Valley | 1 241 → 901 |

W czasy podróży wliczone jest przejście interfejsu. Każdy czas dotyczy konkretnego przebiegu z cache roboczym. Test zapisu i powrotu do regionów opisano w osobnym raporcie. [Testy](../TEST_REPORT.md)

## APK ARM64

| Wersja | Bajty pliku | MiB |
| --- | ---: | ---: |
| 0.9.2 | 119 942 564 | 114,4 |
| 0.9.3 | 126 256 615 | 120,4 |

Pakiet urósł o 6 314 051 bajtów, głównie w imporcie Godota. Biblioteki natywne zachowały rozmiar. Zrzuty i film są wyłączone z eksportu. [Weryfikacja podpisu i pakietu](ANDROID_SIGNING.md#testowy-apk-093)

[Dane 0.9.2](qa-0.9.3/before.json) · [Dane 0.9.3](qa-0.9.3/after.json) · [Ultra 0.9.2](qa-0.9.3/before-ultra.json) · [Ultra 0.9.3](qa-0.9.3/after-ultra.json) · [Geometria](qa-0.9.3/geometry.json) · [Skrypt próby](../tests/performance_window.gd) · [Kadry](../screenshots/0.9.3/README.md)
