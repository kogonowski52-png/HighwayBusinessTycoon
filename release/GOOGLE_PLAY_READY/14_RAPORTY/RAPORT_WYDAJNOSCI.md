# Wydajność 10001 → 10002

Godot 4.7.2, Intel Xeon Platinum 8573C, Linux x86_64, Compatibility i Mesa llvmpipe 25.0.7. Okno 486 × 864, profil Średni, skala 88%, MSAA wyłączone. Do każdej rozbudowanej mapy podróżowano asynchronicznie. Obie wersje używają skryptu `tests/performance_window.gd` z tym samym plikiem konfiguracji wyświetlacza, widokiem i obciążeniem. Wykonano parę 10002 → 10001 po 24 klatki i parę kontrolną 10001 → 10002 po 36 klatek na region.

| Próba | Mediana FPS 12 regionów | Mediana RSS w MiB | Tytuł → gra w s | Mediana podróży w ms |
| --- | ---: | ---: | ---: | ---: |
| 24 klatek na region | 17,34 → 16,12 | 823,1 → 936,7 | 3,41 → 3,67 | 652 → 829 |
| 36 klatek na region | 17,42 → 18,50 | 837,3 → 829,0 | 3,94 → 3,67 | 652 → 644 |

Pierwsza seria wykazała niższą medianę FPS i około 114 MiB wyższy RSS w 10002. W kontroli oba odchylenia zmieniły kierunek. Najdłuższa podróż w pierwszej serii 10002 trwała 4443 ms. W kontroli maksimum wyniosło 762 ms. Pamięć statyczna Godota utrzymała medianę około 98 MiB. Wyników pojedynczej serii nie można użyć do przypisania zmiany pamięci wersji. Wyniki są wrażliwe na wydajność programowego renderera i rozrzut czasu klatek.

## Próba kontrolna 36 klatek

| Region | FPS | Mediana klatki w ms | Draw calls | Prymitywy | RSS w MiB |
| --- | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | 10,2 → 6,0 | 95,4 → 146,2 | 720 → 720 | 114587 → 114587 | 790,0 → 811,2 |
| Desert Highway | 14,0 → 15,3 | 71,9 → 63,8 | 444 → 444 | 66298 → 66298 | 809,1 → 824,0 |
| Green Valley | 16,1 → 18,1 | 60,8 → 54,7 | 322 → 322 | 75123 → 75123 | 815,2 → 825,1 |
| Alpine Pass | 19,3 → 19,5 | 50,4 → 49,2 | 252 → 252 | 57610 → 57610 | 804,1 → 825,5 |
| Ocean Coast | 16,5 → 19,1 | 58,7 → 51,6 | 262 → 262 | 50346 → 50346 | 819,0 → 826,2 |
| Metro City | 13,4 → 15,6 | 68,6 → 59,8 | 393 → 393 | 84546 → 84546 | 837,0 → 826,8 |
| Tropical Island | 16,4 → 17,0 | 60,3 → 59,4 | 377 → 377 | 46966 → 46966 | 837,7 → 831,2 |
| Route 66 | 25,8 → 26,2 | 37,8 → 38,0 | 310 → 310 | 26110 → 26110 | 837,7 → 831,5 |
| Industrial Harbor | 23,4 → 25,2 | 41,8 → 39,6 | 302 → 302 | 29982 → 29982 | 837,8 → 831,5 |
| Luxury City | 18,4 → 18,0 | 52,5 → 54,3 | 430 → 430 | 49438 → 49438 | 846,0 → 834,5 |
| Japan Highway | 19,5 → 18,9 | 49,0 → 53,6 | 432 → 432 | 44930 → 44930 | 846,5 → 839,4 |
| Northern Wilderness | 19,2 → 19,6 | 50,7 → 52,1 | 329 → 329 | 42682 → 42682 | 846,4 → 845,7 |

Licznik prymitywów i wywołań pochodzi z widoku Godota. API silnika pokazuje także szacowaną pamięć renderera w surowych danych. RSS obejmuje cały proces Linuksa. Pomiary nie pochodzą z telefonu. Przed odbiorem zamkniętego wydania potrzebne są pomiary płynności, zużycia pamięci oraz zachowania przy powrocie z reklamy na fizycznym Androidzie.

[10001 · 24 klatki](Pomiary-10001-24-klatki.json) · [10002 · 24 klatki](Pomiary-10002-24-klatki.json) · [10001 · 36 klatek](Pomiary-10001-36-klatek.json) · [10002 · 36 klatek](Pomiary-10002-36-klatek.json)
