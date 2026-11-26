# Licencje zasobów

## Zasoby 0.9.0 RC

Ikonę, grafikę promocyjną i zdjęcie tła wykonano na własnym modelu stacji i samochodu Vela w Godot. Kompozycja i znaki graficzne powstają w skrypcie projektu z użyciem wcześniej licencjonowanego Open Sans. Kadry i film zachowują własne modele, tekstury i miks. [Scena przechwytująca](tests/release_brand_view.gd) · [Źródło kompozycji](tools/release/brand.py) · [Licencja Open Sans](assets/fonts/LICENSE-Open-Sans.txt)

## Zasoby 0.7.0

Błyskawica, monety, kryształy, skrzynie, flaga sezonu, brama, helikopter i wirnik są autorskimi modelami generowanymi w Blenderze. W tym samym źródle powstają portrety i rigi Sana Ito, Reese Morgan i Rhea Foster oraz dźwięk BOOST. Modele drogowe korzystają z dotychczasowych zasobów projektu i dodanych elementów nagrody. [Źródło](tools/art/monetization_art.py)

Mobile Ads, UMP, Play Billing, Credential Manager i Google ID pochodzą z oficjalnych pakietów Google Maven. Biblioteki są pobierane w czasie kompilacji Gradle i podlegają warunkom dostawców. Dźwięk i obrazy gry pozostają zasobami projektu. [Zależności i konfiguracja](docs/MONETIZATION.md)

## Zasoby regionalne 0.6.1

Autorskie skrypty Blendera przygotowują architekturę, geometrię rozbudowy, mosty, tarasy, latarnię i elementy skyline oraz siedem rigów i portretów. Są w `tools/art/regional_atlas.py`, `tools/art/regional_scenery.py` i `tools/art/regional_managers.py`. Modele używają palet i wypalanej okluzji projektu. Oświetlenie, woda, animowana roślinność i warianty oznakowania floty powstały w kodzie projektu. Nagranie używa istniejącej muzyki gry. Wydanie nie dodaje zewnętrznych pakietów zasobów.

| Zasób | Pochodzenie | Licencja lub źródło |
| --- | --- | --- |
| Modele stacji, samochodów, klienta, pracowników, menedżerów, terenu i wyposażenia | Autorskie generatory w `tools/art/`, eksportowane w Blenderze do GLB | Zasób projektu |
| Shadery gruntu, wody, cieni kontaktowych, źródeł światła i ikony SVG | Oryginalne pliki w `assets/` | Zasób projektu |
| Tekstura kruszywa, tła paneli i ikony 3D HUD-u | Oryginalne generatory `tools/art/surfaces.py` oraz `tools/art/hud_icons.py` | Zasób projektu |
| Route 17 Counter | Oryginalne glify z `tools/art/display_font.py` | Zasób projektu |
| Portrety menedżerów | Autorskie modele i własny render Blendera z `tools/art/portraits.py` | Zasób projektu |
| Dźwięki obsługi, wypłaty, budowy i awansu | Autorska synteza w `tools/art/feedback_audio.py` | Zasób projektu |
| Logo Trasy 17, powierzchnie paneli oraz 50 odznak | Oryginalne rysunki generowane przez `tools/art/presentation_art.py` | Zasób projektu |
| Ikony kalendarza, kart, ustawień, nagród i pomocy | Oryginalne modele i rendery `tools/art/presentation_icons.py` | Zasób projektu |
| Karton i wózek dostawy | Oryginalny model GLB z `tools/art/delivery.py` korzystający z palety projektu | Zasób projektu |
| Muzyka menu, dnia i nocy, atmosfera usług, sygnały interfejsu | Oryginalna kompozycja i synteza `tools/art/presentation_audio.py` | Zasób projektu |
| Zdjęcie na ekranie startowym i nagranie rozgrywki | Kadr Stacji Północ z własnej galerii 0.3.2 oraz nagranie z Godota 0.5.0 | Zasób projektu |
| Open Sans Regular, Bold i ExtraBold | Pakiet fontów Open Sans dostarczony w Debianie, Steve Matteson | Apache License 2.0, zob. [informacja o prawach](assets/fonts/LICENSE-Open-Sans.txt) i [pełna licencja](assets/fonts/Apache-2.0.txt) |
| Zrzuty ekranu | Render bieżącej gry w Godocie | Zasób projektu |
| Copper Mile, wyposażenie pustyni, ozdoby wydarzeń i warianty prestiżu | Autorskie generatory `tools/art/desert_diorama.py` oraz `tools/art/desert_roadkit.py` i 31 eksportów GLB | Zasób projektu |
| Trójwymiarowy atlas, szyldy i shader pustyni | Autorska geometria Godota, podglądy modeli projektu i `assets/materials/desert_ground.gdshader` | Zasób projektu |

Dołączony kolaż Roadside Empire był materiałem do obserwacji stylistyki. Galeria i zasoby w repozytorium pochodzą z Highway Business Tycoon.
