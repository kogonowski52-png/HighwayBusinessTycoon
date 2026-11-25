# Wydajność i układ 0.5.0

Pomiary licznika viewportu w Godocie 4.7.2 Stable, renderer Compatibility, OpenGL 4.5 Mesa llvmpipe na Linuxie. Pobrano je w oknie podczas przejścia gry. Liczba prymitywów zależy od kadru, aktywnych pojazdów, cieni i bieżących paneli. Szeroki kadr obejmuje cały kompleks, a porównanie z wersją 0.4.0 pokazuje zmiany interfejsu i kadru. [Galeria](../screenshots/0.5.0/README.md)

| Kadr | Rozmiar okna | Wywołania rysowania | Prymitywy |
| --- | ---: | ---: | ---: |
| Rozgrywka, podstawowe okno | 720 × 1280 | 320 | 149 419 |
| Wąski telefon | 585 × 1280 | 374 | 120 109 |
| Tablet pionowy | 900 × 1200 | 369 | 139 749 |
| Szeroki widok mapy | 1440 × 960 | 540 | 109 053 |

| Profil | Skala 3D | Ustawienia renderera |
| --- | ---: | --- |
| Niska | 74% | Krótszy zasięg cieni, do trzech lamp lokalnych i uproszczone emitery |
| Średnia | 88% | Dynamiczne cienie kierunkowe i mniej lamp lokalnych |
| Wysoka | 100% | Dynamiczne cienie, pełna pula lamp, MSAA 2× |

Interfejs pozostaje w rozdzielczości viewportu. Oszczędzanie baterii wymusza niski profil i limit 30 FPS oraz wyłącza dodatkowe animacje kamery i licznika. Po wyłączeniu wracają ustawienia użytkownika. Test programowy sprawdził przełączenie 30/60 i trzech profili oraz odczyt ustawień po wznowieniu. Bezpieczne marginesy sprawdzono w oknie z wstrzykniętymi danymi. Android używa obszaru zgłoszonego przez system.

Wartości 30 i 60 FPS są celami ogranicznika. Rzeczywisty czas CPU i GPU, płynność po rozgrzaniu, zużycie energii oraz zachowanie przy fizycznym wycięciu ekranu wymagają testu na urządzeniu docelowym. Film zapisano w stałym 30 FPS przez Godot Movie Maker. [Nagranie](../screenshots/0.5.0/rozgrywka.mp4)
