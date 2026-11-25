# Dane i prywatność · 0.7.0

Zakres zależy od rodzaju kompilacji oraz ustawień AdMob i wdrożenia weryfikatora. Dokument służy do przygotowania deklaracji właściciela w Google Play Console. Wartości o rzeczywistej retencji po stronie hostingu i przetwarzania przez pośredników trzeba uzupełnić przed uruchomieniem.

| Dane | Gdzie i po co | Kiedy |
| --- | --- | --- |
| Zapis regionów, waluty gry, ustawienia i postęp | Plik użytkownika Godota i kopia lokalna. Android przechowuje także licznik rozruchu i czas monotoniczny potrzebny do odliczania BOOST. | Wszystkie warianty |
| Dziennik zdarzeń gry | Lokalny zapis maksymalnie 128 rekordów. Zdarzenia mają typ, czas i miejsce w grze. Wyłączenie diagnostyki usuwa wpisy. | Dobrowolnie po zmianie ustawienia |
| Preferencje zgody reklamowej | Google User Messaging Platform. Formularz zgody i formularz zmiany preferencji, gdy Google udostępnia go dla danej aplikacji. | Po wejściu w funkcję reklam lub kwalifikowanej przerwie |
| Identyfikatory urządzenia lub aplikacji, adres IP, interakcje i dane diagnostyczne SDK | AdMob i Google Mobile Ads SDK mogą przetwarzać je do obsługi reklam, pomiaru i zapobiegania nadużyciom. Zależności i deklarację należy sprawdzić z aktualnym przewodnikiem dostawcy i ustawieniami konta. | Tylko wariant natywny z uruchomionymi reklamami |
| Token tożsamości Google i jednorazowy nonce | Przekazywane do weryfikatora przez HTTPS. Weryfikator wyprowadza przypisanie konta z `sub`. Aplikacja nie przesyła osobno e-maila ani imienia. | Po naciśnięciu logowania zakupów |
| ID produktu, token zakupowy i stan zamówienia | Play Billing i weryfikator zabezpieczają finalizację, przywracanie i zwroty. W bazie zapisuje się skrót tokena, pseudonim konta i zapis docelowy. Token oczekujący na potwierdzenie jest szyfrowany na serwerze do czasu finalizacji lub unieważnienia. | Przy zakupie i synchronizacji uprawnień |
| Dane karty i transakcji płatniczej | Obsługuje Google Play zgodnie z własnymi warunkami. Kod gry nie odbiera numeru karty. | Zakupy przez Google Play |

Natywny APK ma uprawnienia do internetu, odpytywania Play Billing i wibracji. Scalony manifest testowego APK zawiera też `ACCESS_NETWORK_STATE`, `AD_ID`, uprawnienia Ad Services dla identyfikatora, atrybucji i Topics oraz uprawnienia bibliotek dla blokady uśpienia, usługi pierwszoplanowej i uwierzytelniania urządzenia. Logowanie korzysta z interfejsu Credential Manager. Gra nie otrzymuje danych biometrycznych. Build offline nie zawiera bibliotek reklam, Billing ani Credential Manager. Ruch weryfikatora używa TLS. Rola serwera i licencja Google Play powinny być opisane w opublikowanej polityce prywatności. Dane konta i zamówień nie są kopiowane do lokalnej diagnostyki. Gra nie aktywuje Firebase Analytics.

Właściciel określa retencję serwera oraz procedurę wycofania zgody i żądania usunięcia danych przed udostępnieniem wersji produkcyjnej. Reklamy nagradzane są dobrowolne. Płatne wyłączenie przerywników nie zmienia zgody Google. Aplikacja zachowuje podstawową rozgrywkę przy braku sieci. [Google Mobile Ads i Data Safety](https://developers.google.com/admob/android/privacy/play-data-disclosure) · [Polityka danych użytkownika Google Play](https://support.google.com/googleplay/android-developer/answer/10144311) · [Data Safety Google Play](https://support.google.com/googleplay/android-developer/answer/10787469)
