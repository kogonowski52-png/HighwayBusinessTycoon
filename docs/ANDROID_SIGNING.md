# Podpisywanie testowych wydań Androida

Pakiet zachowuje identyfikator `pl.krystiandevelopment.highwaytycoon`. Wersja 0.6.0 ma kod 6000, a 0.6.1 ma kod 6001. Wersje używają wzoru `major × 1 000 000 + minor × 1 000 + patch`, przy składowych od 0 do 999. Weryfikator odrzuca APK z kodem niezgodnym z wersją, błędnym identyfikatorem lub innym certyfikatem. Publikacje są wykonywane kolejno, a workflow odrzuca wersję starszą od opublikowanej.

| Kompilacja | Kod | SHA-256 certyfikatu |
| --- | ---: | --- |
| GitHub 0.4.0 | 6 | `541a8dacb5709777437f3e8e388f6f4e5b6624fe16e5b24c4d26bf4b1a0f149b` |
| GitHub 0.5.0 | 7 | `cd16aa3a3773054f82bea5551330e64be8f93af907f6a1dbc1a041a8ce8ea2bc` |
| Lokalny 0.5.0 i stały podpis testowy od 0.6.0 | 7, 6000 i wyższe | `e43f4ee684e3e0341672d4b9fdc03561baea103a17141f11cd37ebacdae85d62` |

Poprzedni workflow tworzył osobny klucz na każdym runnerze. Sprawdzono oba wydania i dwa dostępne magazyny. Kopie prywatnych kluczy zastosowanych w GitHub 0.4.0 i 0.5.0 nie są dostępne w tych magazynach ani w wydaniach. Udało się odzyskać klucz lokalnego 0.5.0. Przeniesiono go do PKCS#12 chronionego losowym hasłem i szyfrowaniem AES-256. Kontrola podpisu w repozytorium używa wyłącznie publicznego odcisku.

## Trwałe przechowanie i publikacja

Właściciel przechowuje zaszyfrowany plik PKCS#12 w prywatnym sejfie z kopią poza Cloud. Hasło zapisuje oddzielnie w menedżerze haseł. GitHub Actions odczytuje kopię pliku i hasło z dwóch sekretów repozytorium `ANDROID_TEST_KEYSTORE_BASE64` oraz `ANDROID_TEST_KEYSTORE_PASSWORD`. Właściciel może je ustawić ze swojego zaufanego komputera po zalogowaniu do GitHub CLI z uprawnieniem zarządzania sekretami.

```bash
base64 < HighwayBusinessTycoon-test-signing.p12 | tr -d '\n' | \
  gh secret set ANDROID_TEST_KEYSTORE_BASE64 --repo kogonowski52-png/HighwayBusinessTycoon
gh secret set ANDROID_TEST_KEYSTORE_PASSWORD --repo kogonowski52-png/HighwayBusinessTycoon
```

Drugie polecenie wczytuje hasło ze standardowego wejścia lub w trybie interaktywnym. Workflow weryfikuje odcisk, używa klucza w katalogu tymczasowym runnera i usuwa tę kopię po eksporcie. Gdy brakuje sekretu lub odcisk jest inny, publikacja zatrzymuje się. Po konfiguracji uruchom workflow dla odpowiedniego tagu.

Próba publikacji `v0.6.0` zatrzymała się na braku pary sekretów. Dostęp z Cloud do API zarządzania sekretami został odrzucony. Sprawdzony APK i zapasowy szyfrowany magazyn przygotowano w prywatnym katalogu pobierania. Ustawienie sekretów w repozytorium oraz przeniesienie kopii do sejfu właściciela pozostają otwarte. [Przebieg GitHub Actions](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45664015493)

### Publikacja 0.6.1 z przeglądarki

1. Na zaufanym komputerze przygotuj jednoliniową zawartość istniejącego magazynu poleceniem `base64 < HighwayBusinessTycoon-test-signing.p12 | tr -d '\n'`.
2. W repozytorium otwórz **Settings → Secrets and variables → Actions → New repository secret**. Dodaj `ANDROID_TEST_KEYSTORE_BASE64` z treścią z pierwszego kroku.
3. Dodaj `ANDROID_TEST_KEYSTORE_PASSWORD` z hasłem tego samego magazynu.
4. Otwórz **Actions → Android debug release → Run workflow**, wpisz `v0.6.1` w polu `tag` i uruchom kompilację. Po pomyślnym przebiegu APK jest do pobrania w Releases. [Ustawienia sekretów](https://github.com/kogonowski52-png/HighwayBusinessTycoon/settings/secrets/actions) · [Workflow wydania](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/workflows/android-debug.yml)


Przebieg `v0.6.1` zatrzymał się przy ładowaniu certyfikatu, ponieważ runner nie otrzymał wymaganej pary sekretów. API sekretów zwróciło `Forbidden` z Cloud. Lokalny podpisany plik `HighwayBusinessTycoon-0.6.1-test.apk` ma SHA-256 `3d158c903ee36dac19c080501a5a5ac08a9e76febdafffc1375e0901e207bc6b`. [Przebieg 0.6.1](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45702931277)


## Aktualizacja i zapis

APK z tym samym identyfikatorem, tym samym podpisem i wyższym kodem jest zgodny z aktualizacją w miejscu. `tools/android/verify-test-apk.sh` przyjmuje poprzedni APK jako trzeci argument i sprawdza te trzy warunki. Migracja gry obejmuje plik `roadside.cfg` i jego atomowe kopie. Próba na urządzeniu obejmuje zainstalowanie starszego lokalnego APK, zrobienie zapisu, `adb install -r` dla nowej wersji i odczyt postępu.

Instalacje GitHub 0.4.0 i 0.5.0 wymagają jednorazowego przeniesienia zapisu. Wariant debug pozwala skopiować dane przez `adb run-as pl.krystiandevelopment.highwaytycoon` na zaufanym komputerze z autoryzowanym debugowaniem USB. Przed zmianą instalacji zlokalizuj plik `roadside.cfg` poleceniem `adb shell run-as pl.krystiandevelopment.highwaytycoon find files -name 'roadside.cfg*'`. Zapisz plik główny oraz istniejące kopie poleceniem `adb exec-out run-as pl.krystiandevelopment.highwaytycoon cat <ścieżka> > <kopia>`. Zweryfikuj zawartość kopii przed migracją. Po instalacji stabilnego APK przywróć pliki do analogicznego katalogu użytkownika przed pierwszym uruchomieniem gry.

Przykład przywrócenia pliku, jeśli polecenie `find` zwróciło `files/roadside.cfg`. Dla plików kopii użyj nazw odnalezionych w poprzedniej instalacji.

```bash
adb shell run-as pl.krystiandevelopment.highwaytycoon mkdir -p files
adb shell -T "run-as pl.krystiandevelopment.highwaytycoon sh -c 'cat > files/roadside.cfg'" < roadside.cfg
```

Próba aktualizacji na urządzeniu wymaga fizycznego Androida lub emulatora. Lokalna kontrola porównuje podpisy dwóch gotowych plików i kod wersji, a osobny test Godota sprawdza odczyt autentycznych zapisów 0.5.0 i 0.6.0.
