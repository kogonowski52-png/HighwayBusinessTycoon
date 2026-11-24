# Raport testów · 0.1.0

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

## Zrzuty z uruchomionej gry

- [Stacja po uruchomieniu](docs/screenshots/01-stacja.png)
- [Tankowanie w toku](docs/screenshots/02-tankowanie.png)
- [Ulepszenie i wersja angielska](docs/screenshots/03-upgrade-en.png)
- [Poziom 5 w układzie tabletowym 3:4](docs/screenshots/04-tablet.png)
