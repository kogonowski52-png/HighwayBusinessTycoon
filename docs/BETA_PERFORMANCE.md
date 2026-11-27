# Wydajność i podróże · 9005 → 10001

W dwóch parach przebiegów uruchomiono wszystkie 12 map. Podstawowa wersja to commit `a8ce73a`. Ten sam Godot 4.7.2, okno Linuksa 486 × 864, Compatibility z Mesa llvmpipe, profil Średni, skala 88%, bez MSAA. Za każdym razem rozbudowano usługi do tego samego poziomu i ustawiono ten sam widok. Dane pochodzą z dwóch różnych uruchomień obu wersji, najpierw 9005 → 10001 po 24 klatki i następnie 10001 → 9005 po 36 klatek na mapę.

Mediana FPS z dwunastu regionów to 17,41 → 16,49 w pierwszej parze i 17,06 → 18,03 w kontroli. W pierwszym przebiegu 10001 Industrial Harbor zanotował 15,8 FPS, a Luxury City 10,9 FPS. W powtórce osiągnęły odpowiednio 25,1 i 16,6 FPS. Wyniki pojedynczych ujęć mają zmienność typową dla tej maszyny z rendererem programowym. Wywołania rysowania i czasy kroku symulacji z obu prób są w surowych danych.

| Mapa | FPS · próba kontrolna | Mediana klatki w ms | Draw calls | Symulacja w ms | RSS w MiB |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 10,3 → 10,2 | 94,6 → 91,9 | 720 → 720 | 0,479 → 0,490 | 702 → 720 |
| Desert Highway | 15,7 → 14,5 | 63,0 → 65,8 | 444 → 444 | 0,374 → 0,401 | 712 → 731 |
| Green Valley | 15,4 → 16,3 | 62,5 → 61,8 | 322 → 322 | 0,394 → 0,328 | 716 → 735 |
| Alpine Pass | 20,4 → 20,0 | 48,8 → 48,8 | 252 → 252 | 0,327 → 0,296 | 717 → 736 |
| Ocean Coast | 18,8 → 19,6 | 52,1 → 50,6 | 262 → 262 | 0,321 → 0,313 | 717 → 736 |
| Metro City | 16,3 → 16,5 | 60,9 → 61,0 | 393 → 393 | 0,490 → 0,447 | 733 → 736 |
| Tropical Island | 16,4 → 17,6 | 59,0 → 58,0 | 377 → 377 | 0,455 → 0,414 | 731 → 736 |
| Route 66 | 26,5 → 26,4 | 36,9 → 36,8 | 310 → 306 | 0,363 → 0,353 | 731 → 736 |
| Industrial Harbor | 24,0 → 25,1 | 42,1 → 39,1 | 302 → 302 | 0,381 → 0,408 | 731 → 736 |
| Luxury City | 14,1 → 16,6 | 61,2 → 60,0 | 430 → 430 | 0,497 → 0,487 | 726 → 732 |
| Japan Highway | 18,7 → 18,5 | 53,7 → 54,4 | 432 → 432 | 0,426 → 0,414 | 727 → 743 |
| Northern Wilderness | 17,8 → 20,6 | 55,4 → 48,5 | 329 → 329 | 0,407 → 0,412 | 734 → 743 |

Czas od ekranu tytułowego do świata wyniósł 4160 → 3303 ms w pierwszej parze i 2939 → 3626 ms w kontroli. W kontroli RSS wzrósł o około 3–19 MiB w zależności od regionu. W obu parach odwiedzono wszystkie mapy przez wbudowane asynchroniczne przejście. Próba sklepowa z gestami ma osobne wyniki w raporcie testów. Do odbioru na fizycznym Androidzie pozostaje pomiar czasu klatki, pamięci i powrotu z Google Mobile Ads. [Raport testów](../TEST_REPORT.md)

[9005 · pomiar](qa-1.0.0-beta.1/bench-9005.json) · [10001 · pomiar](qa-1.0.0-beta.1/bench-10001.json) · [9005 · kontrola](qa-1.0.0-beta.1/bench-9005-control.json) · [10001 · kontrola](qa-1.0.0-beta.1/bench-10001-control.json)
