# Google Play · przygotowanie 0.9.0 RC

Pakiet ma ID `pl.krystiandevelopment.highwaytycoon` i kod wewnętrzny 9000. Kandydat dostępny jest jako testowy APK ARM64. AAB dla Play używa konfiguracji i klucza upload właściciela. Stan ograniczeń i dowody znajdują się w audycie. [Audyt wydania](RELEASE_AUDIT.md)

## Uzupełnienie karty i deklaracji

| Sekcja Play Console | Dane z 0.9.0 i czynność właściciela |
| --- | --- |
| Dane aplikacji | Kategoria Gra, symulacja lub strategia według decyzji wydawcy. Nazwa „Highway Business Tycoon”. Uzupełnij publiczny kontakt, dane wydawcy i kraje dostępności. |
| Karta sklepu | Wybierz PL i EN. Wklej opisy, dodaj ikonę 512 × 512, grafikę 1024 × 500 i kadry odpowiednich urządzeń. Wersje źródłowe pochodzą z uruchomionej gry. [Pakiet materiałów](../release/play/) |
| Dostęp do aplikacji | Tryb podstawowy uruchamia się od razu po naciśnięciu Graj. Weryfikator zakupów wymaga tożsamości Google. Jeśli konsola wymaga instrukcji dla recenzenta, opisz dostęp do wszystkich obszarów i dostarcz legalny dostęp do testu płatności. |
| Klasyfikacja treści IARC | Przejdź aktualny kwestionariusz przy uruchomionej aplikacji. Projekt obejmuje fikcyjny biznes, obsługę pojazdów, wydarzenia, walutę gry i opcjonalne płatności. Brak zakładów o pieniądze, czatu, treści użytkowników i płatnych losowań w kodzie 0.9.0. Ocena wynika z ankiety IARC. |
| Grupa docelowa | Właściciel wybiera rzeczywistą grupę i kraje. Dostosuj konfigurację AdMob i komunikatów zgody do deklarowanej grupy oraz sprawdź ewentualne wymagania Families. |
| Reklamy i identyfikator | Produkcyjny preset zawiera Google Mobile Ads i UMP. W testowym manifeście widnieje `com.google.android.gms.permission.AD_ID`. Wypełnij deklarację na podstawie scalonego manifestu docelowego AAB i rzeczywistych celów SDK. |
| Data Safety | Uwzględnij działanie Mobile Ads, UMP, Billing, Credential Manager i weryfikatora. Sprawdź aktualne ustawienia reklam, hosting, retencję i sposób przyjmowania żądań. [Inwentaryzacja danych](DATA_SAFETY.md) |
| Polityka i usunięcie danych | Wstaw wartości pól w HTML i przygotuj działający kanał żądań przed udostępnieniem zakupów. Przekaż publiczny adres HTTPS do Console oraz `HBT_PRIVACY_URL`. Sprawdź w Console, czy użycie konta Google tylko do weryfikacji wymaga osobnego linku do usunięcia konta. Gotowy punkt dokumentu to `#usuniecie` lub `#deletion`. [Dokument HTML](../release/play/privacy.html) · [Wymagania](https://support.google.com/googleplay/android-developer/answer/13327111) |
| Płatności | Utwórz jednorazowe produkty według tabeli SKU. Włącz podstawowe opcje, wyklucz wielokrotne ilości i sprawdź ceny w grze na kontach z różnymi walutami. [Produkty](PLAY_BILLING.md) |
| Informacja o aktualizacji | Wklej odpowiedni tekst PL lub EN. Zachowaj kod większy od każdego poprzedniego kodu użytego w tej aplikacji. |

## Wymagania wersji Android

| Wymaganie | Wynik pliku RC | Weryfikacja właściciela |
| --- | --- | --- |
| API docelowe | Android 16 / API 36, min. API 24 w gotowym testowym APK | Sprawdź termin, wyjątki i wymagane API dla konkretnego konta w chwili wysyłki. [Target API](https://support.google.com/googleplay/android-developer/answer/11926878) |
| Play Billing | `com.android.billingclient:billing:9.1.0` w kompilacji natywnej. Oficjalne metadane Maven w tej sesji wskazały tę wersję jako bieżące wydanie. | Sprawdź okno wsparcia przy wgrywaniu AAB i proponowany test zakupowy. [Terminy Billing](https://developer.android.com/google/play/billing/deprecation-faq) · [Repozytorium Maven](https://dl.google.com/dl/android/maven2/com/android/billingclient/billing/maven-metadata.xml) |
| 64 bity | ARM64 w APK. Preset AAB obejmuje ARM64 i x86_64. | Sprawdź ABI wygenerowanych splitów w App Bundle Explorer. [Obsługa 64 bitów](https://developer.android.com/google/play/requirements/64-bit) |
| Strony 16 KiB | `zipalign -c -P 16 4` przeszedł. `PT_LOAD` obu bibliotek ARM64 ma 16 384 bajty wyrównania. | Uruchom ostateczne splity na Androidzie pracującym z 16 KiB i sprawdź wynik `adb shell getconf PAGE_SIZE`. [Strony pamięci](https://developer.android.com/guide/practices/page-sizes) |
| Limity wpisów | Nazwa 23/30, skrót PL 78/80, skrót EN 76/80. Pełne PL 1279/4000, EN 1172/4000. | Walidacja tekstu i wymiarów po wgraniu w Console. [Karta sklepu](https://support.google.com/googleplay/android-developer/answer/9859152) · [Grafiki i zrzuty](https://support.google.com/googleplay/android-developer/answer/9866151) |

Środowisko Cloud otrzymało HTTP 403 z dokumentacji Android Developers, Google Play Support i AdMob. Sprawdzono dostępne oficjalne metadane Maven, manifest i lokalny APK. Warunki aktualne dla konta i decyzje w formularzach pozostają do zweryfikowania w Console.

## Kolejność przygotowania toru wydania

1. Zaloguj się do konta wydawcy i wybierz istniejącą aplikację o tym samym ID. Włącz Play App Signing zgodnie z instrukcją konsoli dla tego pakietu. Zabezpiecz zarejestrowany klucz upload i pozyskaj odciski certyfikatów torów. Do aktualizacji APK testowych nadal używaj dotychczasowego klucza testowego. [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756) · [Podpisywanie w projekcie](ANDROID_SIGNING.md)
2. Uruchom weryfikator w osobnym środowisku licencyjnym, ustaw publiczne wartości i konto usługi dla jednego pakietu. W AdMob skonfiguruj jednostki i UMP. Podepnij opublikowaną politykę. [Weryfikator](HTTPS_VERIFIER.md) · [AdMob](MONETIZATION.md)
3. Wyeksportuj podpisany AAB z właściwym kluczem upload. W **Testing → Internal testing** dodaj AAB i listę testerów, a na koncie dodaj testerów licencyjnych. Zainstaluj z toru Play. Używaj testowych reklam i metod płatności Google. Porównaj odczyt wcześniejszego zapisu w osobnym teście aktualizacji APK z tym samym podpisem.
4. Powtórz zakupy udane, oczekujące, anulowane, zwrócone i przywracane po reinstalacji. Sprawdź 8 scenariuszy reklamowych z testowymi jednostkami i reakcję aplikacji po powrocie z tła. Wykonaj pomiary na co najmniej dwóch klasach telefonów i tablecie oraz test instalacji na stronach 16 KiB.
5. Jeśli Google wymaga testów zamkniętych na tym koncie, uruchom odpowiedni tor i spełnij warunki widoczne w Console przed złożeniem wniosku. [Testy kont osobistych](https://support.google.com/googleplay/android-developer/answer/14151465)
6. Po akceptacji właściciela i zamknięciu blokerów przygotuj wydanie produkcyjne z własnymi jednostkami reklam, produkcyjnym weryfikatorem i podpisem upload. Sprawdź raport z testów wstępnych i włącz zarządzane publikowanie. [Przygotowanie wydania](https://support.google.com/googleplay/android-developer/answer/9859348)

## GitHub Actions

Repozytorium buduje podpisane APK testowe przy użyciu `ANDROID_TEST_KEYSTORE_BASE64` i `ANDROID_TEST_KEYSTORE_PASSWORD`. Uruchomienie dla wskazanego tagu zapisuje zweryfikowany plik w artefaktach przebiegu. Publiczne GitHub Releases wymaga ręcznego pola `publish_release`. Wersja RC nie uruchamia procedury publikowania w Play. [Workflow](../.github/workflows/android-debug.yml) · [Sekrety testowe](ANDROID_SIGNING.md)

## Eksport podpisanego AAB

Ustaw `HBT_ANDROID_TEMPLATE` oraz zmienne aplikacji z instrukcji AdMob. Dla `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` wskaż plik właściwego klucza upload na dysku wydawcy, a dla `GODOT_ANDROID_KEYSTORE_RELEASE_USER` jego alias. Ustaw `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` z sejfu lub w zmiennej chronionego środowiska CI. Eksport wymaga odpowiedzi `ready` w trybie `production` pod `HBT_PLAY_BACKEND/health`. [Zmienne eksportu](MONETIZATION.md) · [Konfiguracja serwera](HTTPS_VERIFIER.md)

```bash
tools/android/build-monetization.sh production /pełna/ścieżka/HighwayBusinessTycoon-0.9.0.aab
jarsigner -verify -certs /pełna/ścieżka/HighwayBusinessTycoon-0.9.0.aab
```

Przed umieszczeniem AAB w torze testowym porównaj certyfikat upload z widokiem **App integrity**. Potwierdź także docelowe ABI, kod pakietu i działający link prywatności. Podpis instalacyjny ze sklepu może pochodzić z innego certyfikatu niż testowe APK z Cloud.
