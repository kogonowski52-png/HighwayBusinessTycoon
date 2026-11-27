# Umieszczenie polityki na warszawa-uslugi.pl

Użyj wspólnego pliku `highway-business-tycoon-privacy.html`. Zawiera polską i angielską treść, przełączniki języka, poprawny układ mobilny i kontakt `kogonowski52@gmail.com`. Docelowy adres to `https://warszawa-uslugi.pl/highway-business-tycoon-privacy.html`.

1. Przed publikacją potwierdź pełną identyfikację administratora, właściwy adres kontaktowy i to, kto obsługuje zgłoszenia. Potwierdź faktyczne okresy przechowywania korespondencji oraz podstawy przetwarzania. Plik wykorzystuje podaną nazwę wydawcy i opis celu, bez wymyślonego adresu firmy lub okresu. Dane dotyczące Google podlegają zasadom jego usług.
2. Dodaj plik jako nową publiczną stronę HTTPS w istniejącej domenie. Zachowaj treść pozostałych aplikacji. Adres powinien otwierać HTML bez konta i bez konieczności pobrania PDF. Sprawdź w prywatnym oknie na telefonie i przez `curl -fsSL https://warszawa-uslugi.pl/highway-business-tycoon-privacy.html`.
3. W **Play Console → App content → Privacy policy** wklej dopiero potwierdzony adres. Powinien pokazywać nazwę gry i kontakt oraz być dostępny w krajach toru.
4. W `10002` **Ustawienia → Polityka prywatności** otwiera ekran offline z treścią dla konfiguracji aplikacji i kontaktem. W scalonym manifeście nie wpisano odnośnika do niepotwierdzonej strony. Po publikacji i sprawdzeniu adresu ustaw `HBT_PRIVACY_URL` na ten HTTPS podczas eksportu nowego wydania. Wtedy w grze pojawi się **Przeczytaj pełną politykę**.

Stan dostępu z Cloud z 27 listopada 2026 r. to 403 z bramy sieciowej. Nie pozwala on ustalić ani działania, ani niedostępności publicznego serwera. Publikacja pliku i publiczny test adresu pozostają do potwierdzenia. [Wymagania polityki Google](https://support.google.com/googleplay/android-developer/answer/10144311)
