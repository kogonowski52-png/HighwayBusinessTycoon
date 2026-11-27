# Walidacja materiałów Google Play

Wyniki dotyczą wydania `1.0.0-beta.2` z 27 listopada 2026 r. Skrypt `tools/release/validate_publishing_kit.py` sprawdza pliki źródłowe paczki, w tym prawdziwe binaria przed zapakowaniem.

| Kontrola | Wynik |
| --- | --- |
| Struktura paczki | Katalogi od `00_START` do `14_RAPORTY` i osobny `PODGLAD`. Oba binaria i ich sumy są w `01_AAB`. |
| Ikona | `app_icon_512.png`, 512 × 512, 126 353 B. Trzy warianty dekodują się poprawnie, każdy poniżej 1 MB, bez maskowania narożników. |
| Warstwy adaptacyjne | Obie mają 432 × 432. Przezroczyste pole pierwszego planu zawiera całą treść w promieniu 129,5 px od centrum przy sprawdzanym promieniu 132 px. |
| Grafika promocyjna | 1024 × 500, 772 615 B, PNG RGB bez przezroczystości. Wspólna dla PL i EN. |
| Telefon | 8 zrzutów PL i 8 EN, 1080 × 1920, JPEG, 9:16. |
| Tablet 7″ | 4 zrzuty PL i 4 EN, 1200 × 1920, JPEG, 5:8. |
| Tablet 10″ | 4 zrzuty PL i 4 EN, 1600 × 2560, JPEG, 5:8. |
| Film | 29,75 s, 1920 × 1080, 714 klatek, H.264 i AAC. Miniatura JPEG 1280 × 720. |
| Karta PL | Nazwa 23, opis krótki 74, opis długi 1636 i notatki 226 znaków. Alternatywne opisy 64 / 70 / 67 znaków. |
| Karta EN | Nazwa 23, opis krótki 74, opis długi 1428 i notatki 220 znaków. Alternatywne opisy 67 / 75 / 68 znaków. |
| ASO | 5 nazw alternatywnych do 30 znaków. Redakcję PL i EN sprawdzono ręcznie. Limity odczytano jako liczbę znaków Unicode z pominięciem końcowego nowego wiersza. |
| Zgodność z grą | Liczby 12 regionów, 84 biznesów, 48 modeli pojazdów i 33 menedżerów pochodzą z załadowanych danych gry. Zgodność 19 SKU i 6 przepustek sprawdzono z weryfikatorem. |
| Prywatność i galeria | Obie wersje polityki i nagłówki galerii sprawdzone w Chromium przy 360, 800 i 1440 px. Działa nawigacja językowa, oba odnośniki kontaktowe występują w HTML i ładuje się 40 pozycji galerii. Publiczny URL i dane administratora do potwierdzenia. |
| Podpis i metadane | Potwierdzone SHA-256, APK zgodny certyfikatem z 10001. AAB spełnia walidację pliku i wymaga podpisu upload. Pakiet, 10002, ARM64, min/API target i wyrównanie sprawdzono narzędziami Androida. |
| Sekrety i dane | Skontrolowano nazwy plików, wpisy Androida i metadane konfiguracji. Zawartość zawiera oficjalne publiczne identyfikatory testowe, dane kontaktowe podane do karty i brak magazynów podpisu. |

[Testy Godota](RAPORT_TESTOW.md) · [Weryfikacja AAB i APK](../01_AAB/RAPORT_WERYFIKACJI.md) · [Warunki odbioru po stronie konta Google Play](../00_START/BLOKERY_PUBLIKACJI.md)
