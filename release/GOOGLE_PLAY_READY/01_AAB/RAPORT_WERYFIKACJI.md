# Weryfikacja pakietów Android 1.0.0-beta.2

Do bezpośredniej instalacji służy podpisane **APK testowe**. AAB w folderze to sprawdzony build release w trybie `closed`. Do przesłania w Play Console potrzebuje osobnego podpisu upload.

| Właściwość | Wynik |
| --- | --- |
| Identyfikator | `pl.krystiandevelopment.highwaytycoon` |
| Wersja | `1.0.0-beta.2`, kod `10002`. Poprzedni opublikowany APK miał kod `10001`. |
| Android | Min. API 24, target i compile API 36, tylko ARM64 `arm64-v8a`. |
| AAB | 107 174 409 B, około 102,21 MiB. `bundletool 1.18.2 validate` i test ZIP zakończone powodzeniem. Brakuje podpisu upload. |
| APK | 162 206 199 B, około 154,69 MiB. `apksigner verify` i `zipalign -c -P 16 4` zakończone powodzeniem. Podpis jak w 10001. |
| Strona 16 KiB | `PAGE_ALIGNMENT_16K`. Oba pliki mają segmenty ELF `PT_LOAD` wyrównane do co najmniej 16 384 B w `libgodot_android.so` i `libc++_shared.so`. |
| Tryb release AAB | Brak flagi `debuggable`, diagnostyki gry i produkcyjnego endpointu zakupów. UMP 4.0.0, Google Mobile Ads 25.5.0 oraz Google Play Billing 9.1.0. Reklamy na testowych identyfikatorach, płatności wyłączone. |
| Certyfikat APK testowego | SHA-256 `e43f4ee684e3e0341672d4b9fdc03561baea103a17141f11cd37ebacdae85d62`. Powtórzony pomiar APK 10001 daje ten sam odcisk. |

[Sumy SHA-256](SHA256SUMS.txt) · [Scalony manifest](../14_RAPORTY/AndroidManifest-AAB.xml) · [Raport techniczny](../14_RAPORTY/RAPORT_TECHNICZNY_AAB.md)

## Jak uzyskać podpisany AAB

1. Wejdź w **Play Console → Setup → App integrity → App signing** i odczytaj SHA-256 w sekcji **Upload key certificate**. Użyj magazynu klucza powiązanego z tym certyfikatem. W procesie pierwszego wydania wybierz sposób konfiguracji Play App Signing. Przed wygenerowaniem nowego klucza upload wymagana jest decyzja właściciela.
2. W **GitHub → Settings → Environments** utwórz lub otwórz chronione środowisko `play-upload`. Ogranicz gałąź do `main` i dodaj wymóg zatwierdzenia uruchomienia, jeśli plan konta to umożliwia. Dodaj poniższe dane jako sekrety tego środowiska. Przechowuj kopię magazynu i haseł w prywatnym zaszyfrowanym miejscu pod kontrolą właściciela.

| Pole w `play-upload` | Wartość |
| --- | --- |
| Secret `ANDROID_PLAY_UPLOAD_KEYSTORE_BASE64` | Bajty właściwego magazynu klucza zakodowane w Base64. Przygotuj lokalnie, poza publicznym repozytorium. |
| Secret `ANDROID_PLAY_UPLOAD_KEY_ALIAS` | Alias z właściwym kluczem prywatnym upload. |
| Secret `ANDROID_PLAY_UPLOAD_STORE_PASSWORD` | Hasło magazynu. |
| Secret `ANDROID_PLAY_UPLOAD_KEY_PASSWORD` | Dodaj tylko jeśli hasło klucza różni się od hasła magazynu. |
| Variable `ANDROID_PLAY_UPLOAD_SHA256` | Odcisk certyfikatu **Upload key certificate** z Play, w zapisie szesnastkowym. |

3. Uruchom **Actions → Sign the Android closed-test bundle → Run workflow** na `main`. W polu `unsigned_sha256` wpisz `24f94e90be9ae367d2339611de3b1f0dbdc3bd04d5e9606a31ca9568b3aa8f62`. Workflow pobiera plik wydania, weryfikuje sumę, sprawdza zgodność certyfikatu, podpisuje plik i drugi raz sprawdza strukturę i podpis.
4. Po pomyślnym wyniku pobierz artefakt **HighwayBusinessTycoon-1.0.0-beta.2-play-upload** z danego uruchomienia Actions. Rozpakuj podpisany `HighwayBusinessTycoon-1.0.0-beta.2.aab` oraz `verification.txt`. Przed wysłaniem do Play sprawdź, czy `10002` przekracza wszystkie kody użyte na koncie. Jeśli na koncie jest wyższa wersja, potrzebny jest nowy eksport i podpis tego eksportu.

Lokalnie można sprawdzić certyfikat poleceniem `tools/android/sign-play-bundle.sh --check-key`. Ustaw w prywatnym terminalu `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` i `HBT_PLAY_UPLOAD_SHA256`. Opcjonalne hasło klucza to `HBT_PLAY_UPLOAD_KEY_PASSWORD`. Następnie podaj skryptowi ścieżki wejściowego i wyjściowego AAB. Do końcowej weryfikacji ustaw `HBT_BUNDLETOOL_JAR` i uruchom `tools/android/verify-play-bundle.sh ŚCIEŻKA_DO_PODPISANEGO.aab signed`.

Podpis Google Play App Signing służy do podpisywania plików dystrybuowanych przez Play. Lokalny APK i instalacja z Play mogą mieć różne certyfikaty, a Android odrzuci bezpośrednią aktualizację przy różnicy. Test przejścia wykonaj na oddzielnym urządzeniu lub profilu z zachowaniem ważnego zapisu.

[Workflow GitHub](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/workflows/android-play-closed.yml) · [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756)
