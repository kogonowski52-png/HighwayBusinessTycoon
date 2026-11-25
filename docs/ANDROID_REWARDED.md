# Opcjonalna reklama nagradzana na Androidzie

Ten opis dotyczy pierwszego opcjonalnego mostu. Wersja 0.7.0 korzysta z obecnej instrukcji. [AdMob i BOOST](MONETIZATION.md)

Podstawowy preset Android zawiera pełną grę offline. Wariant reklamowy dodaje wyłącznie opcję podwojenia wypracowanych zarobków offline. Uruchamia SDK po dotknięciu przycisku przygotowania reklamy. Google User Messaging Platform obsługuje zgodę i opcje prywatności. Zwykła wypłata pozostaje dostępna przy braku reklamy, odrzuceniu zgody i zamknięciu materiału przed nagrodą.

## Kompilacja wtyczki

Moduł korzysta z Gradle 8.13, JDK 21, Android SDK API 36 i Build Tools 36.0.0. Biblioteki Google i Godota pochodzą z oficjalnych repozytoriów Maven.

```sh
gradle --project-dir tools/android_rewarded assembleRelease
cp tools/android_rewarded/build/outputs/aar/HighwayRewarded-release.aar addons/highway_rewarded/highway-rewarded.aar
```

Zainstaluj szablon Gradle w edytorze Godot oraz narzędzia Android Build Tools wymagane przez ten szablon. Weryfikacja z Godotem 4.7.2 korzystała z wersji 36.1.0. Włącz **Highway Rewarded Android** w ustawieniach wtyczek projektu. W kopii presetu Android włącz kompilację Gradle. Ustaw identyfikatory aplikacji i jednostki formatu Rewarded w sekcji `highway_rewarded` ustawień projektu. Wtyczka dodaje AAR oraz metadane i zależności tylko przy obecności artefaktu i poprawnym formacie obu identyfikatorów.

Do prób urządzeniowych można użyć publicznych identyfikatorów testowych Google dla Androida.

| Ustawienie | Testowa wartość |
| --- | --- |
| `application_id` | `ca-app-pub-3940256099942544~3347511713` |
| `rewarded_unit` | `ca-app-pub-3940256099942544/5224354917` |

Produkcja wymaga własnych identyfikatorów i treści zgody w AdMob. Urządzeniowy test odtwarzania powinien objąć pełne obejrzenie i zamknięcie przed przyznaniem nagrody. Kwota dodatkowa jest naliczana dopiero po zdarzeniu `OnUserEarnedRewardListener` dla bieżącego identyfikatora oferty.

Testowy eksport przeszedł kompilację Gradle i sprawdzenie podpisu. Manifest zawierał moduł, uprawnienie do internetu i oba publiczne identyfikatory testowe. Odtwarzanie i nagroda z SDK pozostają do sprawdzenia na Androidzie.
