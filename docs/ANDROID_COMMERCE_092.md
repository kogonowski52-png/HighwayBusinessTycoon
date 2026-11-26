# Highway Business Tycoon 0.9.2 · reklamy i sklep

## Dlaczego 0.9.1 wymagała drugiego kliknięcia

Zgłoszenie pochodzi z rzeczywistej próby właściciela na Androidzie. W kodzie wydania 0.9.1 `offer_ad()` wywoływało `request()` tylko dla już gotowej reklamy. W pozostałych przypadkach wywoływało `prepare()`. Callback `reward_availability` odświeżał panel, a gra nie pamiętała zatwierdzonej chęci obejrzenia reklamy. Osobny przycisk przy dochodzie offline również rozdzielał ładowanie od wyświetlania. Moduł Androida rozpoczynał ładowanie po pierwszym żądaniu i po zamknięciu wyświetlonej reklamy nie uzupełniał od razu zapasu. W próbie 0.9.1 z kontrolowanym callbackiem pierwszy klik otworzył 0 reklam, callback ustawił gotowość, a drugi klik otworzył 1 reklamę. W tej sesji nie otrzymano logów z telefonu, więc stan połączenia i zgody UMP w zgłoszonej próbie pozostają nieznane.

W 0.9.2 moduł ładuje cztery skonfigurowane jednostki w tle po UMP i inicjalizacji AdMob. Pamięta osobno inicjalizację, ładowanie, gotowość, wyświetlanie, niedostępność i ponowne ładowanie. Po zużyciu reklamy od razu przygotowuje następną. Po błędzie ponawia żądania z odstępami od 3 s do 2 min. Pojedyncze natywne ładowanie ma limit 25 s.

Pierwsze naciśnięcie otwiera gotową reklamę albo zapamiętuje wybór na maksymalnie 12 s. Anulowanie, zmiana zakładki, zamknięcie panelu i przejście aplikacji do tła przed wyświetleniem kończą oczekiwanie. Późna odpowiedź może ogrzać pamięć podręczną, a do otwarcia potrzebny jest nowy wybór gracza. Rezerwację przekazaną do Androida nadal można anulować, dopóki moduł nie rozpoczął wyświetlania. Jeden token obsługuje jedno zdarzenie nagrody. Potwierdzenie nagrody zapisuje transakcję, a animacja i dźwięk pojawiają się po powrocie z reklamy. Dotyczy to wszystkich istniejących reklam opcjonalnych. BOOST zachowuje 5 min za ukończoną reklamę, maksymalnie 30 min i mnożnik ×2.

## Sklep i Google Play

Katalog 0.9.1 pamiętał poprzednie żądanie po niektórych błędach pobierania. Rozróżnienie braku produktów od błędu sieci było niewystarczające, a pierwsze zalogowanie z wybranej karty kończyło się na przywracaniu zakupów. Wersja 0.9.2 daje osobne stany katalogu, ponowienie pobierania i kontynuację do okna płatności Google Play po bezpiecznej synchronizacji, jeśli gracz nadal ma otwartą właściwą zakładkę. Oczekujący produkt ma osobny status i nie można kupić go ponownie. Cena pochodzi z odpowiedzi Billing. Brak ceny i niedostępna weryfikacja blokują przycisk zakupu.

Dziewięć zakładek dzieli istniejący katalog i nagrody. Sekcja gotówki pokazuje wyłącznie istniejące pakiety zawierające gotówkę i osobną premię reklamową. Kalendarz, przepustka darmowa i oferty za waluty z gry działają bez konfiguracji płatności. Wersja APK z GitHuba używa reklam testowych Google. Zakupy są w niej wyłączone, ponieważ nie zawiera adresu weryfikatora HTTPS ani klienta OAuth. Aplikacja z pliku APK może też otrzymać pusty katalog. Do potwierdzenia zakupów potrzebna jest dystrybucja przez odpowiednią ścieżkę testową Google Play i konto testera uprawnione do produktów.

## Próby na Androidzie

1. Zainstaluj podpisane 0.9.2 na 0.9.1 jako aktualizację. Sprawdź gotówkę, rozwój, ustawienia i aktualny okres BOOST.
2. Otwórz BOOST przy diagnostyce wskazującej gotową reklamę. Potwierdź pierwsze dotknięcie, pełne 5 min za obejrzenie, ciszę podczas filmu, powrót dźwięku i następne ładowanie. Zamknij drugi film bez nagrody i sprawdź, czy licznik się nie zwiększył.
3. Na wolnym łączu dotknij reklamy podczas ładowania. Jedną próbę pozostaw na ekranie, drugą anuluj przyciskiem, a trzecią przez zamknięcie sklepu. Powtórz po przejściu do tła. Po odzyskaniu połączenia film może otworzyć się wyłącznie dla nadal oczekującej próby. Sprawdź też „Podwój dochód offline” oraz nagrodę w sklepie.
4. Na APK sprawdź komunikat o niedostępnych zakupach i nadal działający kalendarz oraz darmową ścieżkę sezonu. W środowisku Google Play sprawdź cenę lokalną, anulowanie, oczekującą płatność, przywracanie i odmowę zakupu przy niedostępnym weryfikatorze.
5. Przy zgłoszeniu podaj nazwę jednostki, czas ładowania, kod błędu i ostatnią nagrodę z ekranu **Ustawienia → Diagnostyka**. Ekran jest przeznaczony dla kompilacji testowej.

## Brakująca konfiguracja usług

- Reklamy produkcyjne wymagają własnego `HBT_ADMOB_APP_ID` oraz jednostek `HBT_REWARDED_BOOST_ID`, `HBT_REWARDED_OFFLINE_ID`, `HBT_REWARDED_BONUS_ID` i opcjonalnej `HBT_INTERSTITIAL_ID`. Komunikat zgody i preferencje prywatności konfiguruje się w panelu AdMob.
- Płatności wymagają opublikowanego pliku dla ścieżki testowej Google Play, testerów, włączonych produktów i ofert, `HBT_PLAY_BACKEND`, `HBT_GOOGLE_CLIENT_ID`, dostępu backendu do Publisher API i testów zwrotów. Endpoint `/health` dla testów musi zwrócić tryb `sandbox`, a dla wydania produkcyjnego `production`. Wydanie produkcyjne wymaga także `HBT_PRIVACY_URL` oraz klucza przesyłania Play. [AdMob i UMP](MONETIZATION.md) · [Produkty i próby Play](PLAY_BILLING.md) · [Weryfikator](HTTPS_VERIFIER.md)

## Rozbudowa kampanii

Atlas i katalogi usług definiują identyfikatory danych. Przełączanie scen przez `world_stream.gd` nadal utrzymuje tylko bieżącą mapę, a kampania zapisuje osobne stany lokalizacji. Główny ekran sklepu rozkłada pozycje według sekcji z danych i oddziela produkty Play od usług świata. Przy przejściu do 12 lokalizacji i ponad 60 usług należy rozszerzyć katalog usług, trasy, modele i testy lokalnych kontraktów oraz zapisu. Wspólna kolejka reklam i sklep pozostają niezależne od liczby map. [Atlas](../data/world/atlas.gd) · [Ładowanie](../scripts/core/world_stream.gd) · [Katalog produktów](../data/monetization/config.gd)
