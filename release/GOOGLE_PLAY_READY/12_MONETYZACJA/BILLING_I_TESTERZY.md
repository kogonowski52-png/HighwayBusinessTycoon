# Google Play Billing i licencje testerów

`10002` jest wydaniem `closed`. Nie wymaga produktów aktywnych w konsoli ani produkcyjnego weryfikatora. Wbudowany Google Play Billing 9.1.0 nie otwiera płatności w tym wariancie. Katalog pobrano z kodu klienta i porównano z autoryzowanymi SKU serwera. Cennik PLN jest propozycją konfiguracji, więc kupujący w aktywnej wersji zobaczy ceny i waluty pobrane z Google Play. [Katalog PL i EN](PRODUKTY_PL_EN.tsv) · [Cennik](CENNIK_PLN.tsv)

## Przygotowanie osobnego toru zakupów

1. W **Monetize with Play → Products → One-time products** twórz produkty z dokładnym identyfikatorem z tabeli. Dodaj nazwę i opis PL/EN, aktywną opcję zakupu, cenę i kraje. Diamenty są konsumowalne po odebraniu. Pakiety, usunięcie przerywników i sezonowe uprawnienia przywraca weryfikator. Każdy SKU przepustki dotyczy jednego okresu.
2. W **Setup → License testing** dodaj konta testerów licencji i zapisz. Te same konta powinny znajdować się na liście testowego toru. Konto akceptuje opt-in i instaluje build z Play. Jeżeli urządzenie ma wiele kont, sprawdź właściwe konto zakupu.
3. Wdróż weryfikator w trybie licencyjnym, potwierdź `/health` i wydaj wariant `play-test` z zarejestrowanym kluczem upload na odrębnym torze. Przy autoryzacji klient porównuje tryb sandbox. [HTTPS](WERYFIKATOR_HTTPS.md)
4. Przy próbie sprawdź sukces, anulowanie, płatność oczekującą, zamknięcie gry pomiędzy wydaniem i potwierdzeniem, utratę sieci, ponowny token, przywrócenie uprawnień po instalacji oraz zwrot. Kwota wirtualna i prawa powinny trafić raz. Prawa do usunięcia przerywników zachowują dostępność dobrowolnych reklam.
5. Dopiero po odbiorze licencyjnym, uruchomieniu produkcyjnego HTTPS i zgodzie właściciela zmień wariant oraz deklaracje. Dostosuj kartę i politykę do faktycznych aktywnych płatności, identyfikatorów konta i danych zamówień.

[Testowanie Google Play Billing](https://developer.android.com/google/play/billing/test) · [Weryfikacja zakupów](https://developer.android.com/google/play/billing/security)
