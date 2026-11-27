# Google Play · zamknięte testy 1.0.0-beta.1

Pakiet `pl.krystiandevelopment.highwaytycoon` ma kod `10001`, ARM64, target API 36 i min API 24. Kandydat powstał z szablonu Godot 4.7.2 w trybie release. Używa testowych reklam Google i wyłącza logowanie zakupowe, połączenie z weryfikatorem oraz płatności. Kampania, reklamy dobrowolne, kalendarz i sklep za waluty gry są dostępne niezależnie od weryfikatora zakupów. [Raport plików](BETA_VERIFICATION.md) · [Materiały do Play](../release/play-beta/README.md)

## Podpis upload

Cloud udostępnił dotychczasowy certyfikat APK do instalacji bezpośredniej. Podpis AAB sprawdza odcisk **Upload key certificate** z Play Console. Certyfikat **App signing key certificate** służy do podpisów plików instalowanych z Google Play. Dwa kanały mogą podpisywać APK różnymi certyfikatami. Zabezpiecz zapis z bezpośredniej instalacji przed przejściem na kanał Play.

Uruchomienie podpisu może odbyć się na stanowisku właściciela z dotychczasowym kluczem upload. AAB do podpisania i jego SHA-256 są w wydaniu beta. `keytool` i `jarsigner` odczytują hasła ze zmiennych środowiskowych. Wartości wprowadź z prywatnego sejfu lub bez echa w terminalu.

| Zmienna | Wartość |
| --- | --- |
| `GODOT_ANDROID_KEYSTORE_RELEASE_PATH` | Lokalna ścieżka do pliku klucza upload, poza checkoutem |
| `GODOT_ANDROID_KEYSTORE_RELEASE_USER` | Alias klucza |
| `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` | Hasło magazynu |
| `HBT_PLAY_UPLOAD_KEY_PASSWORD` | Osobne hasło klucza, jeżeli magazyn je stosuje |
| `HBT_PLAY_UPLOAD_SHA256` | SHA-256 sekcji **Upload key certificate** w Play Console |
| `HBT_BUNDLETOOL_JAR` | Ścieżka do oficjalnego `bundletool-all-1.18.2.jar` |

```bash
tools/android/verify-play-bundle.sh HighwayBusinessTycoon-1.0.0-beta.1-unsigned.aab unsigned
tools/android/sign-play-bundle.sh HighwayBusinessTycoon-1.0.0-beta.1-unsigned.aab HighwayBusinessTycoon-1.0.0-beta.1.aab
tools/android/verify-play-bundle.sh HighwayBusinessTycoon-1.0.0-beta.1.aab signed
```

Możesz wykonać te kroki przez ręczne GitHub Actions **Sign the Android closed-test bundle**. W chronionym środowisku `play-upload` ustaw sekrety `ANDROID_PLAY_UPLOAD_KEYSTORE_BASE64`, `ANDROID_PLAY_UPLOAD_KEY_ALIAS`, `ANDROID_PLAY_UPLOAD_STORE_PASSWORD` oraz opcjonalny `ANDROID_PLAY_UPLOAD_KEY_PASSWORD` i zmienną `ANDROID_PLAY_UPLOAD_SHA256`. Podaj SHA-256 niepodpisanego AAB z raportu jako `unsigned_sha256`. Wyniki działania obejmują podpisany AAB i raport. Kopię magazynu i hasła przechowuj osobno w trwałym sejfie właściciela. [Workflow podpisu](../.github/workflows/android-play-closed.yml)

Przy pierwszym przesłaniu wybierz Play App Signing i ustal klucz upload podczas zakładania aplikacji. Generowanie klucza wymaga decyzji właściciela. Dla istniejącej aplikacji sprawdź **Setup → App integrity → App signing**. Google pozwala właścicielowi zgłosić reset zgubionego klucza upload bez zmiany klucza podpisującego aplikację. [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756) · [Podpisywanie Androida](https://developer.android.com/studio/publish/app-signing) · [bundletool](https://github.com/google/bundletool/releases/tag/1.18.2)

## Ścieżka zamknięta

1. Wybierz istniejący pakiet lub utwórz aplikację o nazwie **Highway Business Tycoon**. W **App Bundle Explorer** sprawdź największy faktycznie użyty kod wersji. `10001` jest wyższy od wszystkich znanych wydań repozytorium. Po użyciu wyższego kodu w Play zwiększ `version/code` w `export_presets.cfg` przed ponownym eksportem.
2. Uzupełnij kartę aplikacji, deklarację reklam, klasyfikację treści, grupę odbiorców, dane kontaktowe i formularze pokazywane dla tego konta. Dodaj publiczny HTTPS polityki prywatności po wstawieniu danych administratora. Dla beta dostęp do podstawowej gry nie wymaga logowania. [Data Safety dla beta](PLAY_BETA_DATA_SAFETY.md) · [Oficjalna pomoc](https://support.google.com/googleplay/android-developer/answer/10787469)
3. W **Testing → Closed testing** utwórz tor, wybierz kraje oraz listę lub grupę adresów testerów. Utwórz wydanie i załącz podpisany `HighwayBusinessTycoon-1.0.0-beta.1.aab`. Sprawdź komunikaty konsoli i otwórz test dla grupy, gdy właściciel zatwierdzi wysyłkę.
4. Udostępnij testerom konsolowy link opt-in. Instalują grę przez Google Play tym samym kontem. Wymóg czasu trwania i liczby aktywnych uczestników przed uzyskaniem dostępu do produkcji pokazuje Play Console dla konkretnego konta. [Testy kont osobistych](https://support.google.com/googleplay/android-developer/answer/14151465)

## Co sprawdzono i co sprawdzi Play

Manifest, ustawienia App Bundle, biblioteki natywne, mostki i wersję Billing sprawdzono w rzeczywistym AAB. Oficjalne metadane repozytorium Google z 27 listopada 2026 wskazały Billing 9.1.0 jako bieżące wydanie. Strony pomocy Play i Android Developers zwróciły błąd dostępu w Cloud. Szczegóły aktualnych terminów, uprawnienia konta i dopuszczenie uploadu należy porównać z bieżącymi komunikatami konsoli. [Target API](https://support.google.com/googleplay/android-developer/answer/11926878) · [Strony 16 KB](https://developer.android.com/guide/practices/page-sizes) · [Terminy Billing](https://developer.android.com/google/play/billing/deprecation-faq) · [Artefakty Billing](https://dl.google.com/dl/android/maven2/com/android/billingclient/billing/maven-metadata.xml)
