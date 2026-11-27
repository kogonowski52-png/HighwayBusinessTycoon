# Weryfikacja plików 1.0.0-beta.1

| Plik | Status | Rozmiar w bajtach | SHA-256 |
| --- | --- | ---: | --- |
| `HighwayBusinessTycoon-1.0.0-beta.1-test.apk` | Podpisany dotychczasowym certyfikatem testowym. Numer `10001` aktualizuje testowy `9005` na Androidzie, jeżeli telefon ma zgodny podpis. | 162 679 755 | `04022a85dbff20bb3855e3f25e3bbbdb8cb94c650fb384116ac8269bd371e058` |
| `HighwayBusinessTycoon-1.0.0-beta.1-unsigned.aab` | Zweryfikowany kandydat release do podpisania kluczem upload. | 107 647 868 | `085e364aedc32dffdcea0f9941cf68d74bcba7b02bd714ac6c151681b103bc26` |

Przeprowadzono `bundletool validate` w oficjalnym bundletool 1.18.2. W `BundleConfig.pb` jest `PAGE_ALIGNMENT_16K`. Biblioteki `libgodot_android.so` i `libc++_shared.so` mają segmenty `PT_LOAD` wyrównane do 16 KiB. Z niepodpisanego AAB odtworzono pomocniczy APK poleceniem `bundletool build-apks` i zaliczono `zipalign -c -P 16 4`. Pakiet ma ABI `arm64-v8a`, minimalne API 24, docelowe API 36 i identyfikator `pl.krystiandevelopment.highwaytycoon`.

Manifest AAB ma konfigurację `closed`, brak `debuggable=true`, wyłączony checkout i testowe jednostki reklamowe Google. Sprawdzono obecność natywnego mostka, Google Mobile Ads, UMP oraz Billing `9.1.0`. Kontrola pakietu objęła wykluczenie skryptów prób, panelu diagnostycznego, dokumentacji, magazynów kluczy i znaczników prywatnego klucza w DEX. Porównanie manifestów i `apksigner` potwierdziło rosnącą wersję APK oraz ten sam certyfikat. [Weryfikator AAB](../tools/android/verify-play-bundle.sh) · [Podpis APK](ANDROID_SIGNING.md)

W Cloud brakuje zarejestrowanego klucza upload. Próba użycia certyfikatu testowego została odrzucona przez mechanizm podpisu. Kontrola podpisu AAB nastąpi po zastosowaniu właściwego klucza. Maksymalny już użyty kod wersji w Play Console i instalacja z toru zamkniętego wymagają sprawdzenia na koncie właściciela. [Podpis i testy zamknięte](PLAY_CLOSED_BETA.md)

[Wydanie na GitHubie](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v1.0.0-beta.1)
