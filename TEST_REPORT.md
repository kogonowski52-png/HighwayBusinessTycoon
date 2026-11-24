# Raport testów

## 0.2.0 · Przebudowa oprawy

Godot 4.7.2 Stable, Blender 4.3.2 i Mesa llvmpipe z rendererem Compatibility. Przejrzano zbliżenia oraz przebieg gry w trybach telefonu i tabletu.

| Weryfikacja | Wynik |
| --- | --- |
| Import zasobów z nowymi scenami GLB i start sceny głównej | Zakończone |
| Test rozgrywki i zapisu bez okna | 24/24 |
| Test rozgrywki w oknie, w tym układ tabletowy | 29/29 |
| Testy oprawy bez okna | 52/52 |
| Testy oprawy w oknie | 67/67, w tym 15 zapisanych zrzutów |
| Eksport i podpis debug Androida | 0.2.0, min. API 24, cel 36, v2/v3, arm64-v8a i x86_64 |
| Zawartość APK | 56 importów GLB, katalog pojazdów, orientacja pionowa, bez uprawnienia do internetu |
| Pomiar FPS i uruchomienie Androida na sprzęcie | Niewykonane w środowisku chmurowym |

Testy oprawy sprawdzają światła i kierunkowskazy, obrót kół, obecność 20 modeli, szkielet i dziewięć animacji dla każdej roli, pozycję kończyny w biegu, wąż przy tankowaniu, cztery ustawienia światła, cykl wody i piany oraz osobny moduł na każdym poziomie. Zapisy są izolowane od profilu gracza. Test awaryjnego zapisu odtwarza spodziewany komunikat parsera. Sterownik wirtualny zgłasza brak zmiany V-Sync.

## Pomiar sceny

| Kadr renderera Compatibility | Wywołania rysowania | Przetworzone prymitywy |
| --- | ---: | ---: |
| Stacja na telefonie 756 × 1344, dzień | 393 | 103 925 |
| Cała lokalizacja 1440 × 960, dzień | 506 | 125 125 |
| Stacja i część otoczenia 1440 × 960, noc | 470 | 151 065 |

Instancje kół i przewodów ograniczyły liczbę wywołań w porównaniu z pierwszym renderem tego etapu. Import Godota ma włączone generowanie geometrii LOD. Profil 30 FPS obniża rozdzielczość renderu 3D do 80%, pozostawiając HUD w pełnej rozdzielczości i ograniczając emitery oraz lokalne światła. Liczniki viewportu opisują obciążenie sceny na Linuxie. Wydajność GPU i zużycie energii na telefonie wymagają osobnego pomiaru.

[Galeria z silnika](docs/art-gallery/README.md) · [Ocena modeli i materiałów](ART_DIRECTION.md)

## Weryfikacja 0.1.0 · Pierwsza grywalna stacja

Testy wykonano w Godot 4.7.2 Stable na Debianie 13. Tryb okienkowy korzystał z renderera Compatibility i Mesa llvmpipe pod Xorg.

| Sprawdzenie | Wynik |
| --- | --- |
| Import zasobów i uruchomienie sceny głównej | Zakończone |
| `godot --headless --path . --script tests/station_smoke.gd` | 24/24 |
| Test okienkowy z odczytem renderu viewportu | 29/29, w tym cztery zapisane PNG i sprawdzenie przycisków na tablecie |
| Android SDK Build Tools 36.0.0, Java 21, eksport debug | Kod wyjścia 0 |
| Podpis debug, identyfikator pakietu, orientacja, ABI i uprawnienia | Podpis v2/v3 poprawny, pakiet `pl.krystiandevelopment.highwaytycoon`, portret, arm64-v8a i x86_64, bez uprawnienia do internetu |
| Instalacja na Androidzie, próba na iOS i wydajność 60 FPS na urządzeniu | Niewykonane, brak podłączonego urządzenia i emulatora |

Test wykonuje kliknięcia głównych przycisków, przejazd klientów, odmowę ponownego rozpoczęcia tankowania w trakcie obsługi, animację i postęp tankowania, wypłatę, zakup wszystkich poziomów, limit ulepszeń, zmianę języka i trybu FPS oraz ponowny odczyt stanu. Uszkodzenie testowego pliku zapisu celowo wywołuje komunikat parsera i potwierdza wczytanie kopii. Sterownik wirtualnego ekranu zgłasza brak zmiany trybu V-Sync.

### Zrzuty z wersji 0.1.0

- [Stacja po uruchomieniu](docs/screenshots/01-stacja.png)
- [Tankowanie w toku](docs/screenshots/02-tankowanie.png)
- [Ulepszenie i wersja angielska](docs/screenshots/03-upgrade-en.png)
- [Poziom 5 w układzie tabletowym 3:4](docs/screenshots/04-tablet.png)
