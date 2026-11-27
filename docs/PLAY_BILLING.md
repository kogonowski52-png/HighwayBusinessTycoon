# Google Play Billing i bezpieczeństwo zakupów

## Produkty w Play Console

W aplikacji `pl.krystiandevelopment.highwaytycoon` otwórz **Monetize with Play → Products → One-time products**. Dodaj poniższe identyfikatory jako zakupy jednorazowe z pojedynczą ilością. Ustaw aktywne podstawowe opcje zakupu i ceny dla krajów dystrybucji. Klient pobiera aktualną cenę i walutę z `ProductDetails`. Proponowane PLN służą do konfiguracji Play Console.

| Produkt | Proponowane PLN | Rozliczenie |
| --- | ---: | --- |
| `starter_pack` | 9,99 | Uprawnienie. 200 diamentów, 2400 gotówki, Sana Ito, złota brama i 3 kupony. |
| `remove_ads` | 24,99 | Uprawnienie. Usuwa przerywniki. |
| `gems_100` | 4,99 | Konsumowalny. 100 diamentów. |
| `gems_550` | 19,99 | Konsumowalny. 550 diamentów. |
| `gems_1200` | 39,99 | Konsumowalny. 1200 diamentów. |
| `gems_2500` | 79,99 | Konsumowalny. 2500 diamentów. |
| `gems_6500` | 199,99 | Konsumowalny. 6500 diamentów. |
| `manager_pack` | 29,99 | Uprawnienie. Reese Morgan, 250 diamentów i 4 kupony. |
| `builder_pack` | 39,99 | Uprawnienie. 420 diamentów, 7800 gotówki i 6 kuponów. |
| `workshop_pack` | 14,99 | Uprawnienie po otwarciu warsztatu. |
| `wash_pack` | 14,99 | Uprawnienie po otwarciu myjni. |
| `freight_pack` | 19,99 | Uprawnienie po otwarciu serwisu ciężarowego. |
| `coast_pack` | 24,99 | Uprawnienie po odblokowaniu Ocean Coast. |

Przepustki tworzy się za 24,99 PLN każda. Każdą aktywuj tylko dla właściwego okresu. Zamknij sprzedaż odpowiednio przed końcem okresu, aby obsłużyć płatności oczekujące.

| SKU | Początek UTC |
| --- | --- |
| `season_pass_2026_snow` | 2026-11-23 |
| `season_pass_2026_holiday` | 2026-12-07 |
| `season_pass_2026_sport` | 2026-12-21 |
| `season_pass_2027_truck` | 2027-01-04 |
| `season_pass_2027_summer` | 2027-01-18 |
| `season_pass_2027_green` | 2027-02-01 |

## Uwierzytelnienie i weryfikator

Gotowa konfiguracja systemd, HTTPS i kopii zapasowych jest opisana w instrukcji wdrożenia. [Wdrożenie weryfikatora](HTTPS_VERIFIER.md)

1. W Google Cloud przygotuj publiczny OAuth Web Client ID i powiąż Android OAuth Client z pakietem oraz odciskiem certyfikatu używanego na danym torze Play. Billing i konto zweryfikowane przez Credential Manager powinny używać tego samego konta testera. Adresu e-mail z tokena aplikacja nie zapisuje.
2. W Play Console nadaj tożsamości usługi weryfikacyjnej dostęp do zamówień tej aplikacji. Włącz Android Publisher API w projekcie właściciela. Serwer korzysta z Application Default Credentials. Użyj tożsamości infrastruktury lub pliku konta usługi przechowanego poza repozytorium i aplikacją.
3. W odizolowanym środowisku zainstaluj `backend/play/requirements.txt`. Skonfiguruj `HBT_GOOGLE_CLIENT_ID`, `HBT_PLAY_DB` na trwałym woluminie z backupem i `HBT_ACCOUNT_SECRET` z sejfu. Sekret ma co najmniej 32 losowe bajty i służy do pseudonimizacji identyfikatora oraz szyfrowania oczekujących tokenów.
4. Uruchom usługę za HTTPS z ograniczeniem rozmiaru i częstotliwości zapytań. Backend WSGI nasłuchuje na prywatnym porcie, a reverse proxy udostępnia cztery operacje `/v1/*`. Dla produkcji użyj `HBT_PLAY_TEST=0`. Osobne środowisko licencyjne używa `HBT_PLAY_TEST=1`.
5. W kopii konfiguracji Android ustaw publiczne `HBT_GOOGLE_CLIENT_ID` i `HBT_PLAY_BACKEND`. Podpis porównuje odcisk klucza upload z `HBT_PLAY_UPLOAD_SHA256`. [Pola podpisu](PLAY_CLOSED_BETA.md#podpis-upload)
6. W **Play Console → Setup → License testing** wskaż konta licencyjne. Dodaj te konta również do listy testerów odpowiedniego toru i przejdź przez instalację z linku opt-in. Zamknięta beta może ruszyć z wyłączonymi płatnościami. Do prób zakupów przygotuj osobny AAB `play-test` po skonfigurowaniu serwera weryfikacji. [Licencyjne próby Billing](https://developer.android.com/google/play/billing/test)

```bash
cd backend/play
python -m pip install -r requirements.txt
gunicorn --bind 127.0.0.1:8074 --workers 2 'service:make_app()'
python service.py retry
python service.py reconcile --days 14
```

Zadanie `retry` uruchamiaj co 10 minut, a `reconcile` co najmniej raz dziennie z nakładającym się oknem. Usługa umożliwia `GET /health`. Logi reverse proxy nie powinny zawierać treści żądań, danych autoryzacji ani tokenów. Backup bazy i sejfu trzeba przechowywać oddzielnie. Utrata klucza HMAC zmienia powiązanie dotychczasowych kont. Weryfikator nie wymaga płatnej usługi do prób lokalnych. Produkcyjny adres oraz zasoby uruchamia właściciel.

## Granice bezpieczeństwa i odzyskiwanie

- Credential Manager pobiera token Google po świadomym logowaniu. Backend sprawdza podpis, odbiorcę, ważność i jednorazowy nonce, po czym wydaje krótkotrwałą sesję w pamięci aplikacji.
- Klient przekazuje token z potwierdzonej transakcji przez HTTPS. Android Publisher `productsv2.getproductpurchasev2` sprawdza pakiet, produkt, zakupiony stan, ilość i identyfikator przypisany do konta. Anulowane i oczekujące zakupy nie wydają nagród.
- Hash tokena jest kluczem unikalnym w SQLite. Transakcja zapisuje prawo do nagrody przed potwierdzeniem lub konsumpcją w Play. Zaszyfrowana kolejka odtwarza finalizację po przerwaniu sieci albo zamknięciu aplikacji. Konsumowalne nagrody mogą trafić wyłącznie do pierwotnego identyfikatora zapisu.
- Aplikacja atomowo zapisuje odebranie nagrody i jej skutki. Próba z powtórzonym paragonem daje tę samą odpowiedź bez ponownego przyznania. Przywracanie po reinstalacji odtwarza niekonsumowalne uprawnienia, w tym usunięcie przerywników, przepustki oraz stałe elementy pakietu startowego. Zużyta waluta nie jest przenoszona między lokalnymi zapisami.
- Voided Purchases API unieważnia zwroty. Nagrody z unieważnionego tokena znikają z kanału dostawy, a uprawnienia cofają się po synchronizacji. Już wydana gotówka lub diamenty, które gra przechowuje lokalnie, mogą pozostać w użyciu. Autorytatywny zwrot waluty i synchronizacja całej gospodarki między urządzeniami wymagałyby osobnego zapisu serwerowego.
- Lokalna gospodarka jest dostępna offline. Ochrona tokenów i ważności zakupu działa na serwerze. Klient bez zweryfikowanego połączenia lub logowania nie otwiera płatności.

## Weryfikacja przed włączeniem prawdziwych zakupów

W trybie testowym eksport AAB do ścieżki Play wykonuje polecenie `tools/android/build-monetization.sh play-test /pełna/ścieżka/HighwayBusinessTycoon-play-test.aab`. Wymaga klucza upload, publicznego identyfikatora OAuth oraz HTTPS z gotowym `/health` w trybie `sandbox`. AAB testuje zakupy kontami licencyjnymi i używa jednostek testowych AdMob. Do wysłania wybierz kod wersji niewykorzystany w Play Console. Gotowego APK z GitHuba można użyć do sprawdzenia reklam. [Raport 0.9.2](ANDROID_COMMERCE_092.md)

Na fizycznym Androidzie z licencyjnym kontem testera sprawdź zakup, anulowanie, oczekiwanie, przywrócenie po przeinstalowaniu, zwrot, powtórzenie tokena, zamknięcie aplikacji między wydaniem a potwierdzeniem oraz utratę internetu. Podpis AAB do Play musi być kluczem upload zarejestrowanym dla pakietu. Natywny APK deweloperski używa odrębnego, wcześniej uzgodnionego certyfikatu testowego. Cloud potwierdził kompilację i testy aplikacji oraz backendu z kontrolowanymi odpowiedziami. Próby Google Play na urządzeniu pozostają otwarte. [Integracja Billing](https://developer.android.com/google/play/billing/integrate) · [Bezpieczeństwo Play](https://developer.android.com/google/play/billing/security) · [Voided Purchases](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list)
