# Rozmiar APK · 0.8.0

Wartości są w bajtach. Kategorie to sumy skompresowanych wpisów ZIP. Całkowity rozmiar obejmuje również manifest, podpis, wyrównanie ZIP i pozostałe pliki Androida.

| Podpisany pakiet | Całe APK | Biblioteki natywne | Zasoby Godota | DEX |
| --- | ---: | ---: | ---: | ---: |
| 0.7.0 ARM64 + x86_64 | 200 666 072 | 160 080 240 | 30 719 349 | 8 462 734 |
| 0.8.0 ARM64 | 118 068 090 | 77 555 944 | 30 655 375 | 8 463 491 |
| 0.8.0 x86_64 | 123 040 516 | 82 524 296 | 30 655 375 | 8 463 491 |

APK telefonu zajmuje **118.07 MB**, czyli około 41.2% mniej niż testowe `0.7.0`. Największy składnik to `libgodot_android.so` dla pojedynczego ABI. Obie biblioteki w APK są nieskompresowane i wyrównane do stron 16 KiB. Osobny plik `x86_64` ułatwia próby na emulatorach obsługujących akcelerację tego ABI. Preset AAB zachowuje obie architektury do dystrybucji rozdzielonej przez Play.

Porównanie list zasobów usunęło wyłącznie trzy modele źródłowe ilustracji `builder.glb`, `gems.glb` i `season.glb` wraz z odpowiednikami importu. Ilustracje i modele bonusów z mapy pozostały. Archiwum pomija `tests`, `tools`, dokumentację, obrazy z testów i źródła weryfikatora. Rozmiar grafiki gry zmniejszył się o mniej niż 0.1 MB, ponieważ źródłem głównej redukcji jest osobne ABI. [Weryfikacja pakietu](ANDROID_QA.md) · [Podpis](ANDROID_SIGNING.md)
