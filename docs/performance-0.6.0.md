# Wydajność 0.6.0

Pomiary wykonano na Linuksie w rzeczywistym oknie Godota 4.7.2 Stable. Renderer Compatibility używał OpenGL 4.5 i Mesa llvmpipe. Próba rozpoczęła się na Stacji Północ, otworzyła atlas, wczytała drugi region, rozbudowała usługi, zapisała 39 kadrów, odwiedziła panele i wróciła na pierwszą mapę. [Przejście](../screenshots/0.6.0/README.md)

| Kadr | Okno | Wywołania rysowania | Prymitywy | Obiekty Godota | Zasoby Godota |
| --- | --- | ---: | ---: | ---: | ---: |
| Początek Stacji Północ | 640 × 1138 | 320 | 96 207 | 5 390 | 530 |
| Copper Mile, szeroki kadr | 1180 × 812 | 724 | 87 726 | 8 361 | 897 |
| Copper Mile, aktywny kadr telefonu | 640 × 1138 | 384 | 75 824 | 8 170 | 899 |

Liczniki obejmują HUD i aktywną scenę. Wartość szczytowa RSS procesu z `/proc` to 860 672 KiB, około 841 MiB, podczas całej próby okienkowej. Pomiar obejmuje interpreter, programowy renderer, pamięć zasobów obu odwiedzonych map i zapis klatek. Panele atlasu i kolekcji renderują podglądy 3D w osobnych viewportach z jednokrotną aktualizacją oraz odświeżają je po zmianie zawartości. Obie mapy mają jeden wspólny zapis, a fizyka poprzedniej sceny kończy się przy podróży.

Pustynne skały, roślinność i linie placu używają MultiMesh. Liczba cząstek pogody w trybach niskim, średnim i wysokim wynosi 18, 31 i 48. Limit FPS i skalowanie renderera pozostają ustawieniami wersji mobilnej. Panorama ma wyższy koszt wywołań niż domyślne zbliżenie telefonu. Pomiar wydajności i zużycia pamięci na fizycznym Androidzie, w tym zachowania po rozgrzaniu, pozostaje otwarty.
