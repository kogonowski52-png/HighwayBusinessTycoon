# Raport techniczny AAB

Eksport wykonano w Godocie 4.7.2 w trybie release z Gradle i konfiguracją Android Play Closed Test. Narzędzia Android Build Tools 36.1.0, JDK 21 i bundletool 1.18.2 posłużyły do odbioru. APK do bezpośrednich testów korzysta z dotychczasowej tożsamości podpisu.

| Sprawdzenie | Wynik |
| --- | --- |
| ZIP i BundleConfig | `unzip -tq` i `bundletool validate` zakończone sukcesem. `optimizations.uncompressNativeLibraries.alignment=PAGE_ALIGNMENT_16K`. |
| Scalony manifest | `pl.krystiandevelopment.highwaytycoon`, 10002, min. 24, target/compile 36 i orientacja pionowa. `android:allowBackup=false` i `android:usesCleartextTraffic=false`. |
| Natywny kod | Dwie biblioteki ARM64. `libgodot_android.so` i `libc++_shared.so` przeszły kontrolę wszystkich `PT_LOAD` co najmniej 0x4000. |
| Próbna instalowalna paczka z AAB | `bundletool build-apks --mode=universal` utworzył lokalny plik walidacyjny 156 485 467 B. Jego `zipalign -P 16`, ELF, min/target API, aplikacja, ABI i podpis walidacyjny przeszły sprawdzenie. To dowód generacji APK. Instalacja wymaga urządzenia. |
| Ikona Androida | `res/mipmap-anydpi-v26/icon.xml` w złożonym APK zawiera `adaptive-icon` i odrębne warstwy. Warstwy źródłowe mają 432 px. Ich treść została obejrzana pod okrągłą maską. |
| SDK i dane | Testowy AdMob App ID i cztery nagradzane miejsca. Przerywniki testowe. UMP i Billing są spakowane. Checkout, diagnostyka w AAB i produkcyjny URL weryfikatora są nieaktywne. |
| Wyłączenia pakietu | Sprawdzono wyłączenie katalogów testowych, backendu, galerii, diagnostyki oraz nazw magazynów kluczy. Kontrola DEX nie znalazła znaczników prywatnych kluczy. |
| Podpis | W AAB brak wpisów podpisu JAR, a `jarsigner -verify` zwraca `jar is unsigned`. Negatywny test wariantu `signed` słusznie odrzuca ten plik. Podpis APK porównano z wydaniem 10001. |
| Sumy | Utrwalone dla rzeczywistych bajtów AAB i APK. Ponownie sprawdzane przy pakowaniu i udostępnieniu. |

APK wygenerowany przez bundletool służył wyłącznie do kontroli lokalnej. Link APK z wydania prowadzi do oryginalnego pakietu testowego. Dokładny rozmiar wariantu instalowanego przez Google Play będzie dostępny po przyjęciu podpisanego AAB i zależy od konfiguracji urządzenia.

[Parametry plików](../01_AAB/RAPORT_WERYFIKACJI.md) · [Scalony manifest](AndroidManifest-AAB.xml) · [Dane aplikacji](../00_START/APP_DETAILS.txt)
