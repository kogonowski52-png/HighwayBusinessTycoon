# Wydajność 0.6.1

Pomiary wykonano w działającej grze na Linuksie z Godotem 4.7.2, OpenGL Compatibility i Mesa llvmpipe. Jest to programowy renderer CPU. Profil obejmuje sześć lokalizacji w oknie 640 × 1138, widok stacji z czynnymi usługami i włączony ruch. Próbka to 38 kolejnych klatek po zmianie opcji. Skala dotyczy obrazu 3D. Liczniki Godota raportują widoczną geometrię i wywołania rysowania w tej próbce.

| Region | Jakość i skala | Mediana klatki, ms | P95, ms | Maks. wywołania rysowania | Maks. prymitywy | Pamięć alokatora Godota, MiB |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Stacja Północ | Niska (.74) | 104.85 | 131.86 | 616 | 131511 | 71 |
| Stacja Północ | Średnia (.88) | 110.01 | 120.70 | 643 | 137759 | 71 |
| Stacja Północ | Wysoka (1.00 + 2× MSAA) | 384.88 | 410.25 | 654 | 140111 | 71 |
| Desert Highway | Niska (.74) | 86.33 | 95.42 | 601 | 95700 | 77 |
| Desert Highway | Średnia (.88) | 92.04 | 153.29 | 607 | 96512 | 77 |
| Desert Highway | Wysoka (1.00 + 2× MSAA) | 315.65 | 407.75 | 585 | 99458 | 77 |
| Green Valley | Niska (.74) | 84.62 | 99.89 | 399 | 58708 | 77 |
| Green Valley | Średnia (.88) | 102.75 | 192.50 | 366 | 57062 | 77 |
| Green Valley | Wysoka (1.00 + 2× MSAA) | 311.03 | 389.03 | 436 | 69914 | 77 |
| Alpine Pass | Niska (.74) | 62.99 | 70.61 | 327 | 46474 | 78 |
| Alpine Pass | Średnia (.88) | 78.99 | 103.64 | 346 | 53268 | 78 |
| Alpine Pass | Wysoka (1.00 + 2× MSAA) | 224.47 | 267.45 | 424 | 64522 | 78 |
| Ocean Coast | Niska (.74) | 70.06 | 73.81 | 418 | 71445 | 80 |
| Ocean Coast | Średnia (.88) | 78.14 | 82.69 | 399 | 70941 | 80 |
| Ocean Coast | Wysoka (1.00 + 2× MSAA) | 202.97 | 216.07 | 429 | 76783 | 80 |
| Metro City | Niska (.74) | 106.43 | 119.99 | 659 | 115486 | 83 |
| Metro City | Średnia (.88) | 129.22 | 148.13 | 630 | 122784 | 83 |
| Metro City | Wysoka (1.00 + 2× MSAA) | 357.24 | 377.37 | 621 | 119632 | 84 |

Największy zaobserwowany `VmHWM` procesu Linux w całej podróży wyniósł 1211 MiB. Obejmuje alokacje Godota, biblioteki i programowy sterownik grafiki. Wewnętrzny licznik silnika osiągnął 84 MiB. Tryb niski zmniejsza we wszystkich nowych regionach medianę czasu klatki względem wysokiego. Okluzja wypalona w kolorach, osobne progi widoczności i instancje dla oznakowania oraz roślin ograniczają pracę renderera. Przekroczenie budżetu 16,7 ms w pomiarze llvmpipe określa wydajność tego środowiska. Płynność 30/60 FPS, RAM, instalacja i temperatura na urządzeniu pozostają do sprawdzenia na Androidzie z GPU.

W równoległej analizie ruchu cztery nowe trasy osiągnęły 651 wyjazdów w oddzielnych próbach po 25 minut symulowanych. Awaryjne usuwanie auta nie wystąpiło. Rozgrywka w oknie bez zapisu kadrów sprawdziła 112 warunków. [Raport testów](../TEST_REPORT.md)

```bash
godot --path . --script tests/regional_window.gd -- --sample-performance
```
