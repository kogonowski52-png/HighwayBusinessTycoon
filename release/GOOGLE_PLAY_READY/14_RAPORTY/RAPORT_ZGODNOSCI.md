# Raport zgodności Google Play · 27 listopada 2026

Oceniany plik to AAB `1.0.0-beta.2`, `versionCode 10002`, z trybem reklam `closed`. Zawiera testowe jednostki Google. Kampania działa bez konta. Checkout i weryfikator zakupów są wyłączone. Deklaracje w tej paczce dotyczą tej konfiguracji.

| Wymaganie | Dowód i stan |
| --- | --- |
| Target, wydanie release i pakiet | Scalone metadane potwierdzają API 36, min. 24 i oryginalny Application ID. Flaga debugowania nie jest aktywna. API 36 przyjęto jako podaną podstawę wydania, a bieżący komunikat konta Play pozostaje do odczytania. |
| ARM64 i 16 KiB | Sprawdzono podpisany APK, AAB i generowany z niego uniwersalny APK walidacyjny. Więcej w raporcie technicznym. |
| Billing i biblioteki reklam | AAB zawiera Billing 9.1.0, Ads 25.5.0 i UMP 4.0.0. Numery są zgodne z `latest` we wszystkich trzech odczytach Google Maven w dniu przygotowania. Włączenie checkoutu wymaga odbioru integracyjnego na Play. |
| Ikona, grafika, zrzuty i opisy | Sprawdzono 512 × 512 PNG poniżej 1 MB, 1024 × 500 PNG RGB, 32 kadry i limity tekstu 30 / 80 / 4000 / 500 znaków. Tytuł, kadry i napisy są oparte na autorskich zasobach i bieżącej kampanii. |
| Certyfikat i kod wersji | APK ma dotychczasowy podpis testowy. Certyfikat upload oraz najwyższy kod przyjęty dla pakietu w Play wymagają odczytu na koncie właściciela. |
| Polityka i App content | Treść PL/EN bazuje na scalonym manifeście, zależnościach i kodzie. Gotowe odpowiedzi obejmują Data Safety, AD_ID, reklamę, dostęp, IARC, odbiorców oraz pozostałe deklaracje. Publiczny URL i dane administratora wymagają potwierdzenia. |
| Testy zamknięte | Udokumentowano ścieżkę zgłoszenia i regułę 12 uczestników przez 14 dni dla kont nią objętych. Dostępny tor, faktyczny wymóg konta i kraje uczestników musi potwierdzić właściciel. |

## Dostęp do źródeł

Oficjalne metadane SDK odczytane w dniu audytu. [Google Play Billing 9.1.0](https://dl.google.com/dl/android/maven2/com/android/billingclient/billing/maven-metadata.xml) · [Google Mobile Ads 25.5.0](https://dl.google.com/dl/android/maven2/com/google/android/gms/play-services-ads/maven-metadata.xml) · [Google UMP 4.0.0](https://dl.google.com/dl/android/maven2/com/google/android/ump/user-messaging-platform/maven-metadata.xml)

Dostęp do pięciu wskazanych stron Pomocy był blokowany przez bramę Cloud kodem HTTP 403. Nie było sesji Play Console. Limity zastosowano w walidatorze. Przed wgraniem właściciel powinien porównać wymagania i faktyczny tor z informacjami w konsoli. [Tworzenie aplikacji](https://support.google.com/googleplay/android-developer/answer/9859152) · [Zasoby karty](https://support.google.com/googleplay/android-developer/answer/9866151) · [Wymagane API](https://support.google.com/googleplay/android-developer/answer/11926878) · [Testy nowych kont](https://support.google.com/googleplay/android-developer/answer/14151465) · [Wydania](https://support.google.com/googleplay/android-developer/answer/9859455)

Bramka Cloud blokowała również karty opisów porównywanych gier, aktualną listę tagów, kartę ujawniania danych Ads i adres docelowy polityki. Dokumentacja w paczce podaje fakty dotyczące artefaktu i oznacza odpowiedzi zależne od konta, zgód lub konfiguracji. [Wymogi 16 KB](https://developer.android.com/guide/practices/page-sizes) · [Ujawnianie danych Ads](https://developers.google.com/admob/android/privacy/play-data-disclosure) · [Formularz Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469) · [Kategoria i tagi](https://support.google.com/googleplay/android-developer/answer/9859673)

[Weryfikacja artefaktów](../01_AAB/RAPORT_WERYFIKACJI.md) · [Deklaracje](../11_FORMULARZE_GOOGLE_PLAY/) · [Warunki rozpoczęcia testów](../00_START/BLOKERY_PUBLIKACJI.md)
