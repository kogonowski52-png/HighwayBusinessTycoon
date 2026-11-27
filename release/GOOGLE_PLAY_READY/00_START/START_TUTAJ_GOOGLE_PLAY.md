# Zacznij tutaj · Highway Business Tycoon

Pakiet przygotowano 27 listopada 2026 r. dla `1.0.0-beta.2` i `versionCode 10002`. Zbierz najpierw trzy informacje z konta właściciela: odcisk klucza upload, największy kod wersji użyty w Play oraz dane administratora polityki prywatności. [Sprawdź blokery](BLOKERY_PUBLIKACJI.md) · [Dane aplikacji](APP_DETAILS.txt)

## 1. Utwórz aplikację albo otwórz istniejący wpis

W **All apps → Create app** wpisz `Highway Business Tycoon`, wybierz język `polski (Polska)`, typ `Gra` i dystrybucję `Bezpłatna`. Jeśli pakiet jest już zarejestrowany, wybierz istniejącą pozycję. Pakiet pojawia się po przesłaniu prawidłowego AAB. Ma wartość `pl.krystiandevelopment.highwaytycoon`. Przejrzyj oświadczenia dotyczące zasad i przepisów eksportowych na koncie przed ich złożeniem. [Oficjalna instrukcja](https://support.google.com/googleplay/android-developer/answer/9859152)

## 2. Ustaw kategorię i kontakt

W **Grow users → Store presence → Store settings** wybierz kategorię `Symulacyjne` i ustaw `kogonowski52@gmail.com` oraz `https://warszawa-uslugi.pl/`. W **Manage tags** korzystaj z dopasowanych tagów widocznych w konsoli. Kandydujące hasła i gotowe nazwy znajdziesz w [analizie ASO](ASO_I_NAZWA.md).

## 3. Zapisz podstawową i angielską kartę

W **Grow users → Store presence → Main store listing** wklej dla `pl-PL` nazwę, krótki i pełny opis z [katalogu PL](../02_OPISY_PL/). W **Manage translations → Add translations** dodaj `English (United States)` i wklej [teksty EN](../03_OPISY_EN/). Zapisz obie karty. W każdym języku użyj tych samych plików `app_icon_512.png` i `feature_graphic_1024x500.png`. Są uniwersalne, zawierają własne modele gry i wspólny znak marki.

| Pole | Plik lub katalog |
| --- | --- |
| App icon | [app_icon_512.png](../04_IKONA/app_icon_512.png) |
| Feature graphic | [feature_graphic_1024x500.png](../05_GRAFIKA_PROMOCYJNA/feature_graphic_1024x500.png) |
| Phone screenshots | [PL](../06_TELEFON/PL/) · [EN](../06_TELEFON/EN/). Dodawaj od `01` do `08`. |
| 7-inch tablet screenshots | [PL](../07_TABLET_7/PL/) · [EN](../07_TABLET_7/EN/) |
| 10-inch tablet screenshots | [PL](../08_TABLET_10/PL/) · [EN](../08_TABLET_10/EN/) |
| Video | Opcjonalne. Wklej publiczny lub niepubliczny adres YouTube po decyzji o publikacji filmu. [Zwiastun](../09_ZWIASTUN/) |

Kadry pochodzą z działającego Godota. Układy tabletów zarejestrowano w osobnych oknach 1200 × 1920 i 1600 × 2560. [Wytyczne obrazów](https://support.google.com/googleplay/android-developer/answer/9866151)

## 4. Uzupełnij App content

Wejdź w **Policy and programs → App content**. Wykorzystaj odpowiedzi odnoszące się do `closed` z tabeli. Jeżeli równolegle dystrybuujesz inną kompilację tego pakietu, deklaracja Data Safety powinna obejmować wszystkie aktywne konfiguracje objęte formularzem.

| Sekcja | Gotowa odpowiedź lub czynność |
| --- | --- |
| Privacy policy | Najpierw umieść wspólną politykę pod wskazanym HTTPS, po potwierdzeniu danych administratora. W konsoli wklej rzeczywisty publiczny URL. [Plik i instrukcja](../10_POLITYKA_PRYWATNOSCI/UMIESZCZENIE_NA_STRONIE.md) |
| Ads | `Tak`. Kompilacja zawiera reklamy nagradzane i przerywniki na jednostkach testowych. [Deklaracja](../11_FORMULARZE_GOOGLE_PLAY/REKLAMY.md) |
| Advertising ID | `Tak`. Biblioteka Google Mobile Ads korzysta z identyfikatora zgodnie z możliwościami urządzenia i zgodami. [Cele i manifest](../11_FORMULARZE_GOOGLE_PLAY/ADVERTISING_ID.md) |
| App access | Wszystkie funkcje udostępnione w tej kompilacji są dostępne bez konta. Nie podawaj danych logowania. [Gotowy tekst do wklejenia](../11_FORMULARZE_GOOGLE_PLAY/APP_ACCESS.md) |
| Data safety | Dane reklamy i SDK rozpisano według kategorii. Po odsłonięciu podglądu sprawdź zgodność z hostowaną polityką. [Odpowiedzi](../11_FORMULARZE_GOOGLE_PLAY/DATA_SAFETY_PL.md) |
| Content rating | Podaj e-mail, rozpocznij IARC i zastosuj odpowiedzi z audytu treści. [Kwestionariusz](../11_FORMULARZE_GOOGLE_PLAY/IARC.md) |
| Target audience | Potwierdź faktycznie zamierzoną grupę. Porównaj ją z grupami wiekowymi i konfiguracją reklam. [Grupa docelowa](../11_FORMULARZE_GOOGLE_PLAY/GRUPA_DOCELOWA.md) |
| Pozostałe deklaracje | Użyj odpowiedzi dla formularzy widocznych na koncie, m.in. finansów, zdrowia, plików i usług w tle. [Pozostałe deklaracje](../11_FORMULARZE_GOOGLE_PLAY/POZOSTALE_DEKLARACJE.md) |

## 5. Podpis i poprawny numer wersji

W **Setup → App integrity → App signing** znajdź sekcję **Upload key certificate**. Zapisz jej SHA-256. Przy pierwszym wariancie skonfiguruj Play App Signing w procesie zakładania wydania i zatwierdź sposób utworzenia lub użycia klucza upload. W istniejącej aplikacji użyj właściwego magazynu dla zarejestrowanego certyfikatu. Klucz upload trafia wyłącznie do prywatnego magazynu właściciela lub sekretów środowiska GitHub `play-upload`.

Sprawdź **Latest releases and bundles → App bundle explorer** i wszystkie tory. `10002` przekracza udokumentowany `10001`. Jeśli konto użyło `10002` lub wyższego kodu, trzeba skompilować kolejny numer przed wysyłką. W plikach znajduje się zweryfikowany kandydat AAB do podpisania. Gotowe APK służy do prób bezpośrednich. [Raport i klucz upload](../01_AAB/RAPORT_WERYFIKACJI.md)

## 6. Utwórz zamknięty tor i wydanie

W **Testing → Closed testing** otwórz istniejący tor lub użyj **Create track**. Na karcie **Countries / regions** wybierz faktyczne kraje uczestników. Na karcie **Testers** dodaj listę e-mail lub Google Group i ustaw adres zwrotny do opinii `kogonowski52@gmail.com`. W **Create new release** dodaj podpisany AAB. Podaj nazwę wydania `1.0.0-beta.2`. Wstaw [notatki PL](../02_OPISY_PL/release_notes_PL.txt) i [EN](../03_OPISY_EN/release_notes_EN.txt) w odpowiadających językach.

Użyj **Save → Review release**, sprawdź komunikaty i potwierdź wysłanie wydania na tor testowy. Jeśli konsola używa **Publishing overview**, sprawdź zmiany i wyślij do weryfikacji. Dystrybucję zatwierdza właściciel. Po udostępnieniu toru skopiuj z **Testers** link do przystąpienia i link do instalacji. Tester otwiera je kolejno na tym samym koncie Google. [Procedura testów i aktualizacji](../13_TESTY_ZAMKNIETE/TESTY_ZAMKNIETE.md)

## 7. Rozdziel odbiór beta od zakupów i produkcji

Próbuj podstawowej kampanii i jednostek testowych. Produkcyjny AdMob, aktywacja produktów, konto licencyjne i wdrożenie weryfikatora mogą poczekać na osobny tor testowy zakupów. Szablon publikacji, materiały i wirtualna ekonomia pozostają użyteczne na torze bez płatności. [AdMob](../12_MONETYZACJA/ADMOB.md) · [Zakupy i testerzy licencji](../12_MONETYZACJA/BILLING_I_TESTERZY.md)

Jeżeli konsola stosuje wymóg dla nowego konta osobistego, zbierz minimum 12 testerów zapisanych przez co najmniej 14 dni bez przerwy i potwierdź spełnienie warunku na pulpicie. Następnie wybierz **Apply for production access** i opisz zebrane opinie, wykonane próby i zmiany wyłącznie na podstawie rzeczywistych danych. Sam dostęp do produkcji nie publikuje gry. [Wymagania testowania](https://support.google.com/googleplay/android-developer/answer/14151465)

[Checklista do odhaczania](CHECKLISTA_PUBLIKACJI.md) · [Zakres weryfikacji i źródła](../14_RAPORTY/RAPORT_ZGODNOSCI.md)
