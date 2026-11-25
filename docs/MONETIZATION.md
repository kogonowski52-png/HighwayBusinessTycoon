# Etap 6 · BOOST, reklamy i sklep

## Co znajduje się w grze

- **BOOST ×2** daje pełne 300 sekund za potwierdzony film. Kolejne filmy dodają po 300 sekund przy limicie 1800. Przedziały są wspólne dla sześciu lokalizacji. Wypłata za zlecenie sprawdza moment rozliczenia. Gotówka z pakietu, waluty premium i jednorazowe nagrody mają zwykłą wartość.
- **Tryb offline** wylicza różnicę między skumulowanymi wpływami na końcu i początku każdego przecięcia z zapisanym przedziałem. Część już pomnożona przez BOOST pozostaje ×2 po dodatkowym filmie offline. Panel pokazuje faktyczną kwotę, którą można odebrać. Dawny kupon +25% pozostaje dostępny za środki z gry, a jego mnożnik nie łączy się z równoczesnym ×2.
- **Jedenaście ofert nagradzanych** obejmuje offline, gotówkę, modernizację, dodatek dzienny, misję, wydarzenie, prezent w sklepie, szkolenie, dostawę, kartę Reese i klienta VIP. Modernizacja i szkolenie dają po jednym bezpłatnym poziomie, ponieważ oba działania podstawowe są natychmiastowe. Dostawa dodaje jedną realną paletę do otwartego magazynu. Klient VIP wjeżdża do zwykłej kolejki i płaci po obsłudze.
- **Zdarzenia na mapie** pokazują specjalne auto, furgonetkę, ciężarówkę i helikopter. Dotknięcie otwiera propozycję. Film jest uruchamiany dopiero po potwierdzeniu gracza w panelu.
- **Przerywniki** mają punkt wejścia po ręcznym zamknięciu atlasu. Po 15 minutach aktywnej gry obowiązuje co najmniej 480 sekund między emisjami, maksymalnie 4 na 3600 sekund i 120 sekund przerwy po zakupie lub reklamie nagradzanej. Samouczek, aktywna modernizacja i trwające okna płatności blokują propozycję. `remove_ads` wyłącza ten format.
- **Przepustka** ma 30 progów, dwie ścieżki, misję tematyczną i nagrody zdobywane za obsługę i modernizację. Sześć okresów po 14 dni zaczyna się 23.11.2026 UTC. Każdy ma indywidualne SKU i 7 dni na odbiór po zakończeniu. Przepustka nie odnawia się automatycznie. Grywalne wydarzenia tygodniowe zachowują osobny harmonogram.
- **Diagnostyka** ma opt-in w ustawieniach. Zapis obejmuje maksymalnie 128 zdarzeń, np. modernizację, zakup, wejście do sklepu, emisję i potwierdzoną nagrodę. Dziennik pozostaje na urządzeniu. Wyłączenie usuwa lokalne wpisy.

Po odebraniu sygnału SDK menedżer zapisuje nagrodę i limit w tym samym pliku co gospodarkę. Cofnięcie zapisu na dysku odtwarza wcześniejsze saldo i limity. Czas korzysta z UTC z monotoniczną korektą. Android przekazuje licznik uruchomień urządzenia i `elapsedRealtime`, więc zamknięcie procesu oraz cofnięcie zegara w tym samym uruchomieniu nie wydłuża odliczania. Po restarcie urządzenia źródłem przerwy jest UTC i zapamiętane maksimum. Zegar urządzenia nie zastępuje autorytatywnego czasu serwera.

## Kompilacje

| Preset | Cele |
| --- | --- |
| Android | Poprzedni samodzielny eksport offline. |
| Android Test | Podpisany APK z natywnym mostem, testowymi reklamami Google i prawdziwym BillingClient. Zakupy wymagają konfiguracji weryfikatora. |
| Android Play | Gradle AAB. Wymaga zarejestrowanego klucza upload, publicznych identyfikatorów AdMob i HTTPS dla weryfikatora. |

Godot 4.7.2 Stable, JDK 21, Android SDK 36 i Build Tools 36.1.0 dla szablonu, Gradle 8.13 do biblioteki. Zależności natywne są przypięte do Mobile Ads 25.5.0, UMP 4.0.0, Play Billing 9.1.0, Credential Manager 1.6.0 i Google ID 1.2.1. Wersje potwierdzono w oficjalnych metadanych Maven, API zależności oraz udanej kompilacji. Oficjalne serwisy developers.google.com, developer.android.com i centrum pomocy zwracały HTTP 403 ze środowiska Cloud. Dostępne były oficjalne przykłady Google, artefakty SDK, schema Android Publisher i dokumentacja Godota z repozytorium autorów. [Dokumentacja Godota](https://github.com/godotengine/godot-docs/blob/master/tutorials/platform/android/android_plugin.rst) · [Przykłady Google Mobile Ads](https://github.com/googleads/googleads-mobile-android-examples) · [Przykłady Play Billing](https://github.com/android/play-billing-samples) · [Android Publisher API](https://github.com/googleapis/google-api-python-client/blob/main/googleapiclient/discovery_cache/documents/androidpublisher.v3.json)

```bash
export HBT_ANDROID_TEMPLATE=/pełna/ścieżka/android_source.zip
tools/android/build-monetization.sh test /pełna/ścieżka/HighwayBusinessTycoon-0.7.0-test.apk
```

Środowisko eksportu musi otrzymać dotychczasowe zmienne `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`, `GODOT_ANDROID_KEYSTORE_DEBUG_USER`, `GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`. Plik APK można porównać z lokalnym 0.6.1 poleceniem `tools/android/verify-monetization-apk.sh NEW.apk OLD.apk` po ustawieniu `ANDROID_BUILD_TOOLS_DIR`. [Stały certyfikat](ANDROID_SIGNING.md)

## Konfiguracja AdMob na koncie właściciela

1. W AdMob dodaj lub wybierz istniejącą aplikację Android o identyfikatorze `pl.krystiandevelopment.highwaytycoon`. Skopiuj jej App ID do `HBT_ADMOB_APP_ID`.
2. Utwórz trzy jednostki **Rewarded**. Wprowadź identyfikatory jako `HBT_REWARDED_BOOST_ID`, `HBT_REWARDED_OFFLINE_ID` i `HBT_REWARDED_BONUS_ID`. Ich nazwy w konsoli powinny wskazywać miejsca emisji. Kwoty dla gracza ustala konfiguracja w grze.
3. Opcjonalnie utwórz jednostkę **Interstitial** i użyj `HBT_INTERSTITIAL_ID`. `HBT_INTERSTITIALS=off` całkowicie wyłącza ten format w danej kompilacji.
4. W AdMob **Privacy & messaging** opublikuj właściwy komunikat zgody dla aplikacji i testuj także możliwość ponownego otwarcia formularza. Dopiero `canRequestAds()` pozwala inicjalizować SDK i pobrać reklamę. Okno nie pojawia się przy uruchomieniu gry.
5. Na urządzeniach wewnętrznych użyj wyłącznie testowego presetu lub skonfigurowanych urządzeń testowych. Testowy preset automatycznie wybiera publiczny App ID `ca-app-pub-3940256099942544~3347511713`, Rewarded `ca-app-pub-3940256099942544/5224354917` dla każdego miejsca i Interstitial `ca-app-pub-3940256099942544/1033173712`.

Punkty weryfikacji właściciela przed użyciem prawdziwych jednostek to polityka nagród, zgody dla rzeczywistej grupy docelowej, konfiguracja regionalna i przegląd deklaracji prywatności. [Rewarded](https://developers.google.com/admob/android/rewarded) · [Interstitial](https://developers.google.com/admob/android/interstitial) · [UMP](https://developers.google.com/admob/android/privacy) · [Polityka nagród](https://support.google.com/admob/answer/7313578)
