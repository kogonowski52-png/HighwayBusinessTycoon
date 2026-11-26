# Highway Business Tycoon · audyt 0.9.0 RC

Punktem odniesienia jest 0.8.0 z commitu `b182d4f`. Kandydat ma `versionCode 9000` i instalacyjny pakiet `pl.krystiandevelopment.highwaytycoon`. Pełna rozgrywka podstawowa działa offline w sprawdzonym przebiegu. Wydanie produkcyjne pozostaje wstrzymane do prób na Androidzie i uruchomienia usług właściciela. [Galeria i film](../screenshots/0.9.0/README.md) · [Testy](../TEST_REPORT.md)

## Usterki i warunki wydania

| Priorytet | Wynik audytu | Stan |
| --- | --- | --- |
| P0 | Nie można potwierdzić prawdziwej transakcji, zgody UMP i usunięcia przerywników z Play bez własnego konta i weryfikatora. Certyfikat upload nie jest dostępny. | Wydanie produkcyjne zablokowane. Przygotowany podpisany APK testowy, konfiguracja oraz procedura odbioru. |
| P0 | Brakuje zweryfikowanego adresu polityki, kontaktu wydawcy oraz zasad produkcyjnej retencji i przyjmowania żądań. | Szablon HTML PL i EN oraz instrukcja gotowe do uzupełnienia danymi właściciela. |
| P1 | Stan `purchased` mógł ujawnić zakup przed potwierdzeniem bądź konsumpcją. Równoległa próba mogła powtórzyć finalizację dla tej samej odpowiedzi. | Poprawione. Wydanie dopiero po finalizacji i rezerwacja operacji. Testy wyprzedzającej synchronizacji oraz starej odpowiedzi Google. |
| P1 | Terminalny błąd tokena mógł wstrzymać weryfikację późniejszych zakupów. | Poprawione. Oddzielna ścieżka odrzucenia i odłożenia ponowienia. |
| P1 | Brak pomiarów urządzeń mobilnych, zakończenia testu cyklu Androida oraz potwierdzenia aktualizacji w miejscu. Koszt wysokiego profilu w scenach z dużą liczbą modeli jest widoczny w rendererze CPU. | Potwierdzono zgodność certyfikatu i odczyt zapisów na Linuksie. Do zamknięcia na urządzeniach. |
| P2 | Po zamknięciu reklamy bez nagrody brakowało jednoznacznego wyniku. Czas BOOST używał różnych formatów. | Poprawione w panelu i na pasku. |
| P2 | Następna inwestycja ginęła na liście. Ekran wejściowy zawsze opisywał tę samą trasę. | Poprawione. Wybór najbliższej inwestycji, cena i warunki. Wczytywanie podaje zapisany region. |
| P2 | Jasne partie plaży i zabudowy zimowej ograniczały czytelność samochodów i detali. | Poprawiono oświetlenie, odcień piasku i śniegu. Niski profil wyłącza ruch tafli wody. |
| P2 | Wydanie preferowało automatyczne publikacje testowych APK po utworzeniu taga. | Publikacja wymaga świadomego wyboru w GitHub Actions. |
| P3 | Pełne kwoty finansowe nie miały separatorów. Nazwa stacji w atlasie odbiegała od używanej na stacji. | Pełne wartości grupowane zgodnie z PL i EN, ujednolicona nazwa Northpoint Station. |

## Co rzeczywiście sprawdzono

| Region | Usługi | Misje | Próba obsługi lub animacji |
| --- | ---: | ---: | --- |
| Stacja Północ | 11 | 110 | Ręczne tankowanie, modernizacja, zatrudnienie, kasa i wszystkie stanowiska w teście tras. |
| Desert Highway | 10 | 160 | Copper Mile, warsztat, restauracja, wiatr, misje i odpływ ruchu. |
| Green Valley | 4 | 64 | Warsztat Mill & Motor, Orchard Table, dostawa do Greenbank, ruch przez most. |
| Alpine Pass | 4 | 64 | Autokar w hotelu Snowline, gastronomia, warunki zimowe. |
| Ocean Coast | 5 | 80 | Wjazd klienta VIP i działająca myjnia Pearl Bay, turystyka i motel. |
| Metro City | 7 | 112 | Magazyn, logistyka z rozładunkiem, salon, centrum handlowe, EV i stanowiska ciężarowe. |

Przeprowadzono test wejścia do każdej usługi, rezerwacji, rozliczenia i zakończenia wizyty. W kampanii uruchomiono kolejne poziomy i powrót z dochodem offline oraz zachowanym zespołem. Scenariusze misji wykonują zgłoszenie spełnionych warunków i sprawdzają, czy odznaczenie lub wypłata nie powtórzą się. Osobne przebiegi obejmują wydarzenia, kontrakty, zestawy kolekcji oraz prestiż z potwierdzeniem. [Raport testów](../TEST_REPORT.md) · [Balans](balance-0.9.0.md)

Test zasobów w silniku objął 82 skrypty gry, 11 scen, 267 GLB, 10 shaderów, trzy pliki Resource, 125 grafik rastrowych lub wektorowych, cztery fonty i 19 plików dźwiękowych. Skrypt sprawdził możliwość wczytania i tworzenia scen oraz 592 klucze z tłumaczeniami, 168 dosłownych odwołań do kluczy oraz zgodność liczby argumentów formatowania. Przejście w oknie obejmowało zachowanie PL i EN oraz testy układu na ekranach telefonu i tabletu. Nie odtworzono każdej możliwej kombinacji wszystkich paneli dla wszystkich 100 poziomów.

## Ocena jakości 0–10

| Obszar | Ocena | Uzasadnienie |
| --- | ---: | --- |
| Grafika | 7 | Rzeczywiste regiony mają odrębny klimat i architekturę. Plaża i krajobraz Alp zyskały czytelność. W oddalonych kadrach widać powtarzające się moduły i skromniejszy detal niż w referencji. |
| Modele 3D | 7 | Własna architektura, autorskie etapy rozwoju, 267 sprawnych importów i zbliżenia pojazdów. Część drobnych rekwizytów oraz tła Metro City wymaga dalszego dopracowania sylwetek. |
| Animacje | 7 | W filmie działa ruch i rozliczany rozładunek. Godot potwierdził tankowanie, pracowników i modernizację. Postacie potrzebują większej różnorodności zachowań. |
| Interfejs | 7 | Nowy ekran startowy, następna inwestycja i czytelny BOOST. Trzy formaty łącznie z wcięciami oraz dwa rozmiary tabletu sprawdzone w środowisku okienkowym. Fizyczny dotyk do potwierdzenia. |
| Dźwięk | 6 | Autorski miks i dźwięk w rzeczywistym nagraniu. Testy zmiany głośności i zapisu ustawień przeszły. Głośnik telefonu i przerwania audio na Androidzie oczekują na próby. |
| Grywalność | 7 | Sprawne wprowadzenie i rozbudowa, wypłaty, podróże oraz aktywna obsługa klientów. Wynik oparty na scenariuszach wykonanych w silniku. |
| Ekonomia | 7 | Kampania bez zakupów otwiera wszystkie usługi. Pierwsze środki i modernizacja w kilka sekund. W późnym modelu dominują zarobki offline. Retencja wymaga danych od graczy. |
| Zawartość | 8 | Wykonana próba sześciu regionów, 41 usług i 590 misji rozdziałowych. Dostępne są kontrakty, kolekcje i wydarzenia. |
| Stabilność | 7 | Odczyt dwóch wydań, odzyskanie kopii po uszkodzonym zapisie i odczyt po `SIGKILL`. Androidowy cykl życia do potwierdzenia. |
| Wydajność | 5 | Zachowane profile i obciążenia ruchu. Pomiar CPU oraz renderera programowego potwierdza koszt cieni i scen z gęstą zabudową. Brak wyników telefonów. |
| Monetyzacja | 4 | SDK w APK, działające przepływy i sprawdzenia klienta i weryfikatora na kontrolowanych odpowiedziach. Rzeczywiste testy AdMob i Billing pozostają otwarte. |
| Gotowość publikacyjna | 4 | Podpisana wersja testowa, źródła i dokumentacja. Brakuje potwierdzenia na Androidzie, konfiguracji właścicielskiej, podpisanego AAB i opublikowanej polityki. |

Ocena wyglądu korzysta z załączonych przez właściciela kadrów Roadside Empire oraz ekranów z działającej gry. Przegląd dotyczy czytelności sylwetek, proporcji, szczegółowości otoczenia i hierarchii obrazu. Branding oraz grafiki sklepu pochodzą z autorskich modeli Highway Business Tycoon. [Kierunek artystyczny](../ART_DIRECTION.md) · [Materiały](../release/play/)

## Czynności właściciela przed decyzją o publikacji

1. Zweryfikuj parametry konta i wybierz grupę docelową. Uzupełnij publiczny kontakt, dane administratora, hosting i retencję. Uruchom obsługę żądań dostępu i usunięcia danych.
2. Podłącz OAuth, weryfikator HTTPS i konto usługi Play. Skonfiguruj jednostki reklamowe i komunikaty UMP oraz 19 produktów.
3. Dostarcz zaufane dojście do zarejestrowanego klucza upload. Dodaj sekrety stałego certyfikatu testowego do GitHub Actions tylko jeśli potrzebujesz kompilacji z repozytorium.
4. Przetestuj wydanie wewnętrzne na fizycznych telefonach oraz tablecie, w tym aktualizację z wcześniejszych APK z tym samym podpisem. Sprawdź ważne scenariusze zakupów, reklam, tła, wcięć, pamięci i 16 KiB.
5. Po pozytywnych testach oceń wydanie do Google Play. [Procedura i deklaracje](PLAY_CONSOLE_RC.md) · [Wydajność](performance-0.9.0.md) · [Bezpieczeństwo](SECURITY_RC.md)
