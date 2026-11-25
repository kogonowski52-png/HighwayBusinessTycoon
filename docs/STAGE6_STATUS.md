# Etap 6 · stan testowy 0.7.0

| Wymaganie | Wykonanie i weryfikacja |
| --- | --- |
| 1. Technologia | Natywny most Godot Android skompilowano z GMA 25.5.0, UMP 4.0.0, Billing 9.1.0 i Credential Manager 1.6.0. Wersje zweryfikowano w Maven Google i kodzie SDK. Bezpośrednie serwisy dokumentacji Google blokowała sieć Cloud. |
| 2. Globalny BOOST | 300 sekund za film, 1800 sekund limitu, wspólna historia, ×2 przy wypłacie i tylko w odpowiednim przedziale offline. |
| 3. Interfejs BOOST | Autorska błyskawica i dźwięk, licznik, pasek, animowane monety i podświetlenie. Zweryfikowano w renderowanym Godocie. |
| 4. Jedenaście nagradzanych ofert | Wszystkie aktywne w kodzie. Dodatki za misję, kalendarz i wydarzenie są powiązane z rzeczywistą nagrodą. Dostawa działa w otwartym magazynie. Bez urządzenia sprawdzono adapter i warunki gry przy podaniu kontrolowanych zdarzeń. |
| 5. Nagrody na mapie | Trzy pojazdy z geometrią bonusu i autorski helikopter z wirnikiem. Dotknięcie otwiera ofertę przed odtworzeniem. |
| 6. Przerywniki | Odstęp, limit godzinowy, osłona samouczka, modernizacji, reklam i zakupów. Format można wyłączyć podczas eksportu. Reguły przeszły testy lokalne. |
| 7. Google Play Billing | Skatalogowane jednorazowe produkty, lokalne ceny, pobieranie transakcji i oczekiwanie. Natywne klasy są obecne w APK. Autoryzowana ścieżka urządzeniowa wymaga toru Play. |
| 8. Starter | Jednorazowy, treść z danych, oryginalna karta Sana Ito, złota brama i kupony czasu bez sztucznego odliczania. |
| 9. `remove_ads` | Trwałe uprawnienie synchronizowane według konta. Oddzielne nagradzane materiały pozostają dostępne. Potwierdzono przywracanie i cofnięcie w testach serwera. |
| 10. Sklep | Pakiety, premie, BOOST, przepustka i wymiany walut z gry. Odbiór zakupów ma osobną animację. Cena jest pokazywana po odczycie katalogu. |
| 11. Przepustka | Sześć jednorazowych SKU, 30 progów, dwie ścieżki, misje, dekoracje i trzy typy ekonomicznych nagród oraz karta. |
| 12. Oferty postępu | Pakiety warsztatu, myjni, ciężarówek i luksusowej lokalizacji pojawiają się po rzeczywistym rozwoju. Oferty są dostępne w sklepie na żądanie. |
| 13. Bezpieczeństwo | Serwer sprawdza Android Publisher, wiąże token z kontem i zapisem, rozlicza trwałe paragony, szyfruje retry i obsługuje zwroty. Płatności pozostają zależne od publicznego HTTPS i konfiguracji właściciela. |
| 14. Prywatność | Natywne UMP z formularzem zmiany zgody i Data Safety. Przygotowanie reklamy odbywa się po sprawdzeniu zgody. Przejście formularza od początku do końca wymaga urządzenia. |
| 15. Analityka | Zdarzenia działają lokalnie po włączeniu diagnostyki przez gracza. Kod nie dołącza Firebase Analytics. |
| 16. AdMob | Oddzielne klucze App ID, BOOST, offline, bonus i interstitial. APK używa oficjalnych identyfikatorów testowych. |
| 17. Ekonomia | Cztery polityki, cztery horyzonty. Wszystkie lokalizacje i usługi zostały otwarte także bez reklam i zakupów. |
| 18. Testy | Testy boosta, adapterów SDK, serwera, regresji zapisów i poprzednich map, wraz z rzeczywistą galerią Godota. Próby emisji i płatności na fizycznym Androidzie są otwarte. |
| 19. Podpis i eksport | APK testowe 0.7.0, kod 7000, ten sam pakiet i stały podpis. AAB wymaga zarejestrowanego klucza upload oraz konfiguracji produkcyjnej właściciela. |
| 20. Dokumentacja i dowody | 30 kadrów, klip aktywacji z oznaczonym testowym sygnałem i raporty. Kod i konfiguracja produkcyjna pozostają dostępne do weryfikacji przed publikacją. |

[Galeria](../screenshots/0.7.0/README.md) · [Testy](../TEST_REPORT.md) · [Reklamy i BOOST](MONETIZATION.md) · [Play Billing i bezpieczeństwo](PLAY_BILLING.md) · [Data Safety](DATA_SAFETY.md) · [Balans](balance-0.7.0.md)
