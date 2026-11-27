# Historia zmian

## 0.9.4 RC · World Expansion

- Tropical Island, Route 66, Industrial Harbor, Luxury City, Japan Highway i Northern Wilderness otwierają się w drugim rozdziale atlasu. Łącznie działa 12 lokalizacji i 84 biznesy.
- Uruchomiono wypożyczalnie z odroczonymi zwrotami, załadunek i rozładunek, chłodnie, salony, działalność turystyczną oraz nowe usługi warsztatowe.
- Przygotowano 18 dodatkowych nadwozi, ośmiu menedżerów, sześć wydarzeń, 129 nowych misji rozdziałowych i 54 odznaki regionalne.
- Uzupełniono etapy rozwoju pierwotnych kompleksów oraz ograniczono koszt rysowania wody, nawierzchni i często używanych modeli pojazdów.
- Zachowano schemat zapisu i certyfikat testowy. Android ARM64 ma kod 9004. [Zakres, pomiary i ograniczenia](docs/WORLD_EXPANSION.md)

## 0.9.3 · Premium Graphics 2.0

- Pięć indywidualnych konstrukcji stacji i osobne moduły rozbudowy dla sklepu, warsztatu, myjni i restauracji.
- Częściowe wnętrza Północy z wyposażeniem oraz ruch szczotek podczas mycia i iskry powiązane z naprawą.
- Opracowane fasady, dachy i detal 41 istniejących usług. Nowe korony drzew, palmy i świerki oraz zmienione oznaki zużycia dróg.
- Dopracowane 20 dotychczasowych pojazdów i dziesięć nowych nadwozi, zmienione modele postaci oraz przejścia wybranych cykli.
- Pochmurna pogoda z chłodniejszym światłem, mniejsza gęstość mgły opadów, odświeżone ikony i ilustracje. Ultra skaluje render 3D do 110% przy MSAA 4×.
- Wersja testowa Android ARM64 z kodem 9003 i tym samym certyfikatem. [Porównanie z 0.9.2](screenshots/0.9.3/README.md) · [Wyniki testów](TEST_REPORT.md)

## 0.9.2 · Reklamy i sklep premium

- Wstępne ładowanie reklam po UMP, uruchomienie przy pierwszym dotknięciu i anulowalne oczekiwanie we wszystkich miejscach reklamowych.
- Jednorazowa nagroda po potwierdzeniu SDK, automatyczne uzupełnianie reklamy, powrót do panelu i wznowienie dźwięku.
- Dziewięć przewijanych sekcji sklepu, karty z autorskimi ilustracjami, czytelne statusy płatności i ceny z katalogu Google Play.
- Ponowienie katalogu po błędzie, osobny stan oczekującego produktu i kontynuacja wybranego zakupu po bezpiecznej synchronizacji.
- Diagnostyka testowa pokazuje UMP, stany jednostek, czas ładowania, kody błędów, nagrody, Billing i HTTPS. Kod 9002, Android ARM64. [Raport](docs/ANDROID_COMMERCE_092.md)

## 0.9.1 · Dotyk i rozbudowa

- Przewijanie paneli palcem, wygaszanie bezwładności i ochrona przycisków oraz kamery podczas gestu.
- Cztery zakładki Rozbudowy, rzeczywiste ilustracje 41 usług, koszt, szacunek przychodu stanowiska i oddzielne warunki poziomu oraz reputacji.
- Budowa za podaną cenę bezpośrednio z listy z przejściem kamery do animacji. Zielony młotek z ceną, szara kłódka i zarządzanie po dotknięciu modelu na mapie.
- Samouczek prowadzi przez zebranie środków i reputacji do otwarcia sklepu. Węższy górny HUD, zwijany dół oraz korekta jasności i kontrastu w zwykłym kadrze.
- Android ARM64 z kodem 9001 i stałym certyfikatem testowym. [Kadry](screenshots/0.9.1/README.md)

## 0.9.0 · Release Candidate

- Weryfikator wydaje zakupy dopiero po potwierdzeniu lub konsumpcji. Równoległe próby i niejednoznaczne odpowiedzi odtwarzają właściwy stan. Klient odkłada błędy przejściowe i usuwa z kolejki nierozliczalne paragony.
- BOOST ma odliczanie MM:SS i komunikat zamknięcia reklamy bez nagrody. Karta następnej inwestycji pokazuje koszt, warunki oraz przycisk skupienia kamery.
- Ekran wejściowy, ikony Androida i znak Krystian Development wykorzystują własny kierunek graficzny. Ujednolicono nazwę regionu w EN, pełne kwoty w PL i EN oraz jasne partie plaży i śniegu. Niski profil ogranicza animację wody.
- Produkcyjny eksport filtruje diagnostykę deweloperską i sprawdza docelowy HTTPS. Publikacja APK przez GitHub Releases wymaga ręcznego wyboru. Kod Androida 9000 zachowuje stały podpis. [Szczegóły wydania](docs/RELEASE_AUDIT.md)

## 0.8.0 · Wydajność i Android

- Cztery profile grafiki, dobór automatyczny i oszczędzanie baterii. Stan detali wizualnych jest oddzielony od częstotliwości gospodarki.
- Grupowanie dekoracji, ograniczenie animacji poza kadrem, pula pojazdów oraz siatka kolizji przy dużym ruchu. Dokładne kwoty i rozliczenia BOOST zachowują poprzedni format.
- Asynchroniczne wejście i podróż, późne wczytanie otwieranych budynków, oddzielne zasoby lokalizacji oraz test odzyskania zapisu `0.7.0`.
- Podpisany APK ARM64 z kodem `8000`, diagnostyka testowa i weryfikacja wyrównania 16 KiB. Konfiguracja usługi zakupów z HTTPS i kopiami SQLite.

## 0.7.0 · BOOST i monetyzacja testowa

- Dodano wspólny BOOST z 300 sekundami za ukończony materiał i limitem 1800 sekund. Wypłaty online sprawdzają czas rozliczenia. Odliczenia offline rozpoznają aktywne przedziały bez drugiego mnożnika.
- Natywna integracja Androida obejmuje AdMob, UMP, Credential Manager i Play Billing. Jedenaście nagród, cztery rodzaje zdarzeń na mapie i przerywniki mają osobne zasady kwalifikacji.
- Sklep premium, dwa tory sezonu, nagrody, dokładnie wyceniane produkty jednorazowe oraz weryfikator Play zachowują bazową grę offline.
- Schemat zapisu 8 przechowuje historię BOOST, limity reklam, uprawnienia, paragony i postęp przepustek. Wersja APK ma kod 7000 i stały podpis testowy.

## 0.6.1 · Sześć działających regionów

- Otwarto Green Valley, Alpine Pass, Ocean Coast i Metro City. Każda lokalizacja ma własny układ, architekturę, flotę i profil finansowy.
- Meridian Junction uruchamia doki przeładunkowe, magazyn z rezerwacją towaru, salon ze sprzedażą i Crossline z niezależnymi stanowiskami. Progi modernizacji montują cztery grupy geometrii ponad modelem otwarcia.
- Atlas odblokowuje mapy kolejno i rozlicza opłatę w regionie, który spełnił warunki. Dodano 320 misji, siedem kart z oryginalnymi postaciami i portretami, cztery kontrakty oraz album trasy w każdym z sześciu regionów.
- Schemat 7 odczytuje i zachowuje kampanie 0.6.0, niezależne dane gospodarcze, umowy i niewypłacony dochód. APK ma kod 6001 i certyfikat lokalnej linii od 0.5.0.

## 0.6.0 · Ekspansja Copper Mile

- Otwarto Desert Highway z własnym ruchem, zapisem, stawkami i dochodami offline. Atlas prezentuje sześć regionów i uruchamia podróż pomiędzy dwiema dostępnymi lokalizacjami.
- Dodano 160 misji rozdziałowych, sześć wydarzeń, siedem rodzajów kontraktów i podglądy 3D kolekcji. Dodano wybór pogody, automatyczny cykl dnia i prestiż z osobnym potwierdzeniem.
- Poprawiono trasy podczas próby mieszanego ruchu. Nowe odcinki oddzielają wyjazd ciężarówek od kolejki i zapewniają odstęp między lokalami przy tylnej drodze.
- Schemat 6 przenosi wcześniejszy profil do wspólnej kampanii. APK testowe używa stałego podpisu lokalnej linii i rosnącego kodu wersji. Workflow wymaga zgodności publicznego odcisku i dwóch chronionych sekretów.

## 0.5.0 · Interfejs i rytm Trasy 17

- Dodano ekran startowy z logo i paskiem faktycznego ładowania. HUD zyskał pięć zakładek, znaczniki usług, animowane salda, krótkie komunikaty i układ uwzględniający bezpieczne marginesy.
- Dodano 30-dniowy kalendarz i 50 osiągnięć z osobnymi ilustracjami. Zakładka sklepu obsługuje istniejące wymiany oraz użycie zdobytych kuponów. Karty menedżerów pokazują bieżący bonus, następny bonus i doświadczenie z obsługi w specjalizacji.
- Dodano przybliżanie gestem, bezwładność przesuwania i filmową kamerę przy przebudowie. Bramy warsztatu, ruch belki myjni, wysiadanie i dostawy uzupełniono o animacje wynikające z wizyt klientów i sprzedaży.
- Dodano osobną muzykę startu, dnia i nocy, siedem warstw otoczenia, cztery nowe sygnały interfejsu i niezależny miks. Ustawienia obejmują trzy tryby grafiki, FPS, oszczędzanie baterii i wibracje.
- Schemat zapisu 5 przechowuje kalendarz, odznaki, kupony, doświadczenie kart i ustawienia. Próba migracji używa profilu zapisanego przez 0.4.0.

## 0.4.0 · Rozwój Trasy 17

- Dodano wulkanizację, parking TIR i ładowarki EV z osobnymi stanowiskami, cenami, personelem oraz pięcioma etapami widocznymi na mapie.
- Klienci chodzą do obiektów i wracają do auta przed wyjazdem. Nowy profil EV wybiera usługi zgodne z napędem, a lokalne modernizacje zwiększają atrakcyjność obiektu.
- Dodano 20 poziomów gracza i 110 misji rozłożonych na 11 rozdziałów. Kolekcja obejmuje 15 menedżerów z portretami i pięcioma rangami.
- Dodano aktywny samouczek, animowane awanse, autorskie dźwięki i opcjonalne wibracje. Menu finansów pozwala rozbudować limit offline z 2 do 12 godzin.
- Schemat zapisu 4 zachowuje dotychczasowe obiekty, portfel, zespół, cele i oczekujące wypłaty. Powracające profile z limitem 8 h zachowują ten próg.

## 0.3.2 · Przebudowa Trasy 17

- Dodano trzy pełne warianty stacji i wybrano Przełęcz. W pięciu etapach zmieniają się zadaszenia, dystrybutory, zaplecze i zużycie placu.
- Przebudowano witrynę oraz zamknięty sklep, wyposażenie garażu i wiatę TIR. Dodano krzywiznę masek i szyb pojazdów, nadkola, detale ciężarówek, dedykowane elementy ubrań oraz drzewa z modelowanymi korzeniami.
- Dodano pęknięcia i łaty asfaltu, odbicia witryn i ambient occlusion wypalony do palety statycznych modeli.
- HUD zyskał własne cyfry, portfele z ikonami 3D, animację wpływów i panel pięciu etapów. Klienci sklepu chodzą między parkingiem a wejściem.
- Opublikowano podpisany testowy APK. GitHub Actions buduje wydania Android na podstawie tagów w formacie `vMAJOR.MINOR.PATCH`. [APK 0.3.2](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/tag/v0.3.2)

## 0.3.1 · Modernizacja wizualna Trasy 17

- Przebudowano zadaszenie stacji i plac TIR, wzbogacono fasady usług oraz dodano pięć dostrzegalnych progów rozwoju dachów usługowych.
- Poprawiono szyby floty, kształty fryzur i nakryć głowy, pracę zawieszenia i kół, nocne oświetlenie oraz animacje postaci.
- Dodano relief terenu, zbiornik retencyjny, kaktusy, wyposażenie zapleczy, teksturę asfaltu i ślady opon.
- Wprowadzono kremowy HUD z autorskimi ikonami 3D, animowanym licznikiem kasy i otwieraniem paneli. Porównano trzy kąty kamery w grze i zapisano zrzuty przed i po zmianach.

## 0.3.0 · Kompleks Idle Tycoon

- Dodano osiem usług, siedem profili klientów, sprawdzanie budżetu, dwie kolejki i rezerwowanie stanowisk na Trasie 17.
- Dodano pracowników z animacjami w świecie, szkolenia, awanse oraz pięć kart menedżerskich.
- Dodano cztery dokładne waluty, 100 poziomów na usługę, zakupy grupowe, statystyki, premie i wydarzenia dzienne.
- Dodano dochód offline, migrację zapisów, odzyskiwanie kopii oraz opcjonalny wariant Android z reklamą nagradzaną.
- Dodano automatyczne sprawdzanie balansu w sześciu horyzontach i testy pętli gry z rzeczywistymi kliknięciami w oknie.
- Dodano procedurę kompilacji, weryfikacji podpisu i publikacji APK debug 0.3.0 na GitHubie.

## 0.2.0 · Oprawa Trasy 17

- Wprowadzono autorskie modele GLB siedmiu obiektów, 20 pojazdów, ośmiu ról i wyposażenia krajobrazu.
- Sklep zyskał wnętrze, stacja pięć osobnych konfiguracji geometrii, a ruch koła, reflektory, kierunkowskazy i światła hamowania.
- Dodano cztery pory dnia, cienie kontaktowe, widok mapy, animacje szkieletowe i efekty powiązane z ruchem, sprzedażą oraz budową.
- Zgrupowano koła, przewody i roślinność w instancje. Aktywowano lżejsze renderowanie w trybie 30 FPS.
- Dodano testy oprawy, galerię z silnika i eksport debug Androida 0.2.0.

## 0.1.0 · Etap 1

- Dodano grywalną Stację Północ przy trasie 17.
- Dodano ruch drogowy, wizualizację tankowania, przychód i pięć poziomów dystrybutora.
- Dodano lokalny zapis, język polski i angielski oraz tryb 30 i 60 FPS.
- Dodano oryginalne modele proceduralne, materiał terenu, ikony, HUD i preset Android.
- Dodano test pętli gry oraz zrzuty z uruchomionej sceny 3D.
