# Stan projektu

## 0.9.2 · Reklamy od pierwszego dotknięcia i sklep

AdMob ładuje jednostki w tle po UMP. Pierwsze dotknięcie wyświetla gotową reklamę albo podejmuje jedną próbę oczekiwania do 12 s. Anulowanie i zamknięcie panelu kończą oczekiwanie. Nagroda pozostaje przypisana do jednego potwierdzenia SDK, a BOOST rozlicza te same przedziały co wcześniej.

Sklep ma dziewięć sekcji, autorskie ilustracje, statusy katalogu Google Play, ponowienie żądania i blokadę zakupu bez weryfikacji HTTPS. Podpisany APK ARM64 ma kod 9002 i korzysta z testowych jednostek Google. Właściciel może sprawdzić reklamy na telefonie, a transakcje wymagają odpowiednio skonfigurowanej ścieżki Google Play. [Przyczyny i próby odbiorcze](docs/ANDROID_COMMERCE_092.md) · [Galeria](screenshots/0.9.2/README.md)

## 0.9.1 · Dotyk i rozbudowa

Wspólny panel przewija całą powierzchnią, utrzymuje bezwładność po puszczeniu palca i rozróżnia ruch pionowy od regulacji suwaka. Rozbudowa sortuje gotowe inwestycje, ma cztery zakładki i umożliwia budowę z listy. Dotknięcie budynku albo znacznika otwiera jego własny panel. Pierwsza zmiana prowadzi do zakupu sklepu. Górny HUD zajmuje mniej miejsca, a dolny panel można zwinąć.

Porównano światło w tym samym ujęciu zwykłej rozgrywki. Kod 9001 zachowuje Application ID i certyfikat testowy 0.9.0. Rzeczywiste sprawdzenie ergonomii i wydajności na telefonie pozostaje zadaniem odbiorczym. [Galeria](screenshots/0.9.1/README.md) · [Raport testów](TEST_REPORT.md)

## 0.9.0 · Release Candidate

Kandydat z kodem 9000 i stałym testowym podpisem Androida. Zmieniono tytuł, ekran wczytywania i ikonę aplikacji. Rozbudowa pokazuje następną inwestycję. Dopracowano oświetlenie Alpine Pass i Ocean Coast. Poprawiono granice przyznawania zakupów, ponawianie weryfikacji i komunikaty BOOST.

Przejście renderowane obejmuje sześć map i 41 usług zweryfikowanych również w symulacji testowej. Przeszła migracja zapisów 0.7.0 i 0.8.0. Produkcyjne AAB, prawdziwe testy AdMob i Billing, publiczna polityka i pomiary na telefonach wymagają infrastruktury i urządzeń właściciela. [Audyt i blokery](docs/RELEASE_AUDIT.md) · [Dowody i raporty](TEST_REPORT.md)

## 0.8.0 · Optymalizacja i zgodność Androida

Wersja zawiera cztery profile grafiki, automatyczny wybór, ograniczanie pracy poza kadrem, pulę aut, asynchroniczne podróże i zachowane dane wszystkich lokalizacji. Testowe APK wykorzystuje ten sam certyfikat oraz mniejszy wariant ARM64. Próby płynności, cyklu życia i zakupów na fizycznym Androidzie pozostają otwarte. Weryfikator HTTPS ma gotową instalację bez uruchamiania zewnętrznej usługi. [Status wszystkich wymagań](docs/STAGE7_STATUS.md) · [Weryfikacja urządzeń](docs/ANDROID_QA.md)

## 0.7.0 · BOOST i monetyzacja testowa

- BOOST ×2 jest wspólny dla sześciu regionów, ma 5 minut za film i 30 minut maksymalnej kolejki. Dochód offline korzysta z rzeczywistego przecięcia czasu. Zachowano kupowanie kuponów za walutę gry i zwykłe wypłaty.
- Podpisane APK testowe zawiera natywne AdMob, UMP i Play Billing. Produkcyjne identyfikatory, zweryfikowane konto Play, zaplecze HTTPS i klucz upload AAB pozostają do skonfigurowania przez właściciela. Żadnej produkcyjnej usługi nie uruchomiono. [Reklamy i eksport](docs/MONETIZATION.md) · [Weryfikator zakupów](docs/PLAY_BILLING.md)
- Sklep zawiera rzeczywiste ścieżki płatności z ceną zwracaną przez Play, nagrody darmowe i sześcioterminową przepustkę z 30 progami. Przetestowano logikę i migrację starego zapisu. [Stan etapu 6](docs/STAGE6_STATUS.md)
- Galeria i klip pochodzą z renderowanego silnika. Film oznacza kontrolowane zdarzenie adaptera. Android z aktywnym Google Play jest potrzebny do prób natywnego odtwarzania, zgód, zakupów i zwrotów. [Galeria](screenshots/0.7.0/README.md) · [Raport testów](TEST_REPORT.md)

## 0.6.1 · Sześć działających regionów

- Do Stacji Północ i Copper Mile dołączyły Green Valley, Alpine Pass, Ocean Coast oraz Metro City. Kampania obejmuje 41 usług, 590 zadań rozdziałowych, 22 menedżerów i niezależne zarobki każdego regionu. [Audyt etapu 5](docs/STAGE5_STATUS.md) · [Galeria](screenshots/0.6.1/README.md)
- Meridian Freight, Junction Warehouse, Apex Motors i Crossline przeszły próby tras, wynagrodzeń z obsługi, rozbudowy i zapisu. Dostawy, sprzedaż i odwiedziny mają widoczne skutki w scenie. [Raport testów](TEST_REPORT.md)
- Trzy przebiegi 30-dniowe potwierdziły możliwość otwarcia wszystkich usług bez płatności. Zachowano lokalne zapisy, kalendarz, wydarzenia, kontrakty, kolekcje i prestiż. [Balans](docs/balance-0.6.1.md)
- APK testowe ma kod 6001 i podpis zgodny z lokalnymi wydaniami 0.5.0 oraz 0.6.0. Status publikacji i sposób dodania sekretów opisuje instrukcja. [Instrukcja wydania](docs/ANDROID_SIGNING.md)
- Pomiary wydajności pochodzą z Godota na Linuksie. Próba instalacji i pomiary na fizycznym Androidzie pozostają otwarte. [Wydajność](docs/performance-0.6.1.md)

## 0.6.0 · Ekspansja Copper Mile

- Atlas prowadzi do dwóch grywalnych lokalizacji. Desert Highway ma własny układ i scenerię 3D, dziesięć czynnych usług, niezależną gospodarkę i 160 nowych misji rozdziałowych. Razem ze Stacją Północ jest ich 270. [Zrzuty i nagranie](screenshots/0.6.0/README.md)
- Działa sześć rotacyjnych wydarzeń, siedem rodzajów kontraktów, sześć kolekcji, prestiż z potwierdzeniem i pogoda. Kampania zapisuje oba biznesy atomowo. Odczyt autentycznego zapisu 0.5.0 przeszedł weryfikację. [Zasady gry](docs/EXPANSION.md) · [Testy](TEST_REPORT.md)
- Przygotowano APK z kodem 6000 i stałym certyfikatem, zgodnym z lokalnym 0.5.0. Przebieg publikacji zatrzymał się na brakujących sekretach. [Podpisywanie i migracja APK](docs/ANDROID_SIGNING.md) · [GitHub Actions](https://github.com/kogonowski52-png/HighwayBusinessTycoon/actions/runs/45664015493)
- Green Valley, Alpine Pass, Ocean Coast oraz Metro City są oznaczone w atlasie jako w przygotowaniu. Centrum logistyczne, magazyn, salon i centrum handlowe są w planie. Interfejs przyszłej synchronizacji ma kontrakt danych. [Zakres ekspansji](docs/EXPANSION.md)
- Wydajność oceniono w oknie Godota z rendererem Compatibility. Instalacja, płynność i pamięć na sprzęcie Android wymagają pomiaru. [Raport wydajności](docs/performance-0.6.0.md)

## 0.5.0 · Interfejs i rytm Trasy 17

- Dostępne są ekran startowy, zwięzły HUD, panele obsługi, kolekcja 15 menedżerów, nagrody awansu, finanse i offline, pomoc, licencje, prywatność oraz sklep za środki z gry. Kalendarz ma 30 nagród, a osiągnięcia 50 odznak z zapisem. [Galeria](screenshots/0.5.0/README.md)
- Kamera obsługuje dotyk i mysz oraz podąża za modernizacją. Animacje świata wynikają z wizyt i zakupów. Oryginalne utwory i efekty działają na trzech regulowanych kanałach.
- Sprawdzono zapis utworzony przez wersję 0.4.0 oraz regresję jej 11 usług. Koszty, stawki i trasy zweryfikowano tym samym symulatorem balansu. [Raport testów](TEST_REPORT.md)
- Podpisany APK z tagu `v0.5.0` opublikowano w GitHub Releases i zweryfikowano po pobraniu. [APK Android](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.5.0/HighwayBusinessTycoon-0.5.0-debug.apk)
- Instalacja, płynność po rozgrzaniu, wibracje i rzeczywiste wycięcia wymagają sprawdzenia na Androidzie. Diagnostyka ekranu i liczniki renderera pochodzą z okna Godota na Linuxie. [Raport wydajności](docs/performance-0.5.0.md)

## 0.4.0 · Rozwój Trasy 17

- Pierwotna lokalizacja ma 11 działających usług i 26 stanowisk. Wulkanizacja, parking TIR i ładowarki EV mają własne modele, pracowników, cenniki, kolejki i wyposażenie widoczne przy rozbudowie. [Zrzuty z gry](screenshots/0.4.0/README.md)
- Poziomy gracza, 110 nowych misji, 15 kart menedżerów i rozbudowa zarobków offline działają za waluty zdobywane w grze. Samouczek prowadzi przez rzeczywiste tankowanie, zakup i zatrudnienie. [Projekt gry](GAME_DESIGN.md)
- Migracja zachowuje dotychczasowych pracowników, karty, ustawienia i niewypłacone wpływy. Symulator przechodzi sześć horyzontów na trzech ziarnach. [Raport testów](TEST_REPORT.md) · [Balans](docs/balance-0.4.0.md)
- Podpisany testowy APK z tagu `v0.4.0` został opublikowany i zweryfikowany po pobraniu. [APK Android](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.4.0/HighwayBusinessTycoon-0.4.0-debug.apk)
- Test instalacji, dźwięku, wibracji i płynności na fizycznym Androidzie pozostaje otwarty. Charakterystyka zarobków offline opiera się na lokalnym zegarze i limicie naliczania.

## 0.3.2 · Przebudowa geometrii Trasy 17

- Główna stacja ma pięć różniących się konstrukcji. Przełęcz została wybrana po porównaniu z Łukiem i Tarasem w oknie Godota. Otwarty sklep i czynny warsztat mają własne modele wyposażenia. [Galeria i porównanie](screenshots/0.3.2/README.md)
- Ruch i układ stanowisk przeszły testy rozgrywki. Profil utworzony w `7ea8bf9` otwiera się z portfelem, rozbudową, pracownikiem, językiem i trybem oszczędnym. [Raport testów](TEST_REPORT.md)
- GitHub Actions zbudował i opublikował testowy APK Android z tagu `v0.3.2`. Pobrany plik przeszedł weryfikację podpisu, manifestu i sumy kontrolnej. [Pobierz APK](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.3.2/HighwayBusinessTycoon-0.3.2-debug.apk)

## 0.3.1 · Modernizacja wizualna

- Stacja, Trasa 17 i osiem działających usług mają nową oprawę. Pięć progów dachów, wydzielona wiata TIR i animowane elementy oświetlenia są dostępne w uruchomionej grze.
- Kremowy HUD i widok ortograficzny zachowują obsługę w pionie, języki PL i EN oraz tryby 60 i 30 FPS. Zmiany przeszły próby pętli rozgrywki, zapisu i działania paneli. [Raport testów](TEST_REPORT.md)
- Porównanie zrzutów i galeria powstały w Godocie z istniejącej sceny Trasy 17. [Galeria](screenshots/README.md)

## 0.3.0 · Ekonomia i działający kompleks

- Działają stacja paliw, sklep, parking, myjnia, warsztat, restauracja, motel i osobny plac obsługi TIR. Kierowcy wybierają usługi według profilu, wjeżdżają na plac, czekają, zajmują przydzielone stanowisko i wyjeżdżają.
- Osiem usług obsługuje poziomy 1–100, progi pojemności, cztery tryby zakupu i oddzielne stawki. Fizyka ruchu korzysta z rezerwacji, odstępów i odzyskiwania po blokadzie.
- Pracownicy widoczni w świecie wykonują zadania, zyskują doświadczenie i awansują. Pięć kart menedżerów daje osobne efekty. Cele, osiągnięcia i rotujące wydarzenia pozwalają rozwijać kompleks za waluty zdobywane w grze.
- Dochód offline, atomowy zapis i odzyskiwanie obsługują istniejące profile. Opcjonalny moduł reklamowy działa w wariancie eksportu Android z odpowiednią konfiguracją. Podstawowy APK debug nadal działa offline.
- APK debug 0.3.0 został zbudowany z tagu `v0.3.0` przez GitHub Actions i udostępniony jako wydanie testowe. [Pobierz APK](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.3.0/HighwayBusinessTycoon-0.3.0-debug.apk)

Fizyczne testy Androida, pomiary wydajności i wyświetlenie reklamy z docelową konfiguracją wymagają urządzenia. Projekt rozgrywa się w kompleksie Trasy 17. Kolejne lokalizacje i publikacja sklepowa są w planie.

[Raport testów](TEST_REPORT.md) · [Symulacja ekonomii](docs/balance-0.3.0.md)

## 0.2.0 · Przebudowa oprawy Stacji Północ

- Ta sama grywalna lokalizacja z nową architekturą, autorskim otoczeniem, czterema porami dnia i kamerą mapy.
- Siedem dopracowanych obiektów w świecie gry. Stacja paliw zachowała obsługę klienta, ekonomię, zapis i pięć poziomów. Każdy zakup dodaje osobny moduł 3D i animację budowy.
- Flota 20 osobnych nadwozi GLB przejeżdża przez teren, z animacją kół i świateł oraz dwoma wariantami lakieru na model.
- Osiem ról używa własnych mundurów, akcesoriów i wspólnego szkieletu z dziewięcioma animacjami. Czynności personelu widać w otoczeniu gry.
- Grywalny dystrybutor ma widoczny wąż i pistolet tankowania, a wypłata uruchamia monety. Myjnia, warsztat i krajobraz mają własne cząsteczki.
- Tryb 30 FPS korzysta z mniejszej skali 3D i lżejszych efektów. Projekt nadal używa Godot Compatibility i działa lokalnie.

### Ówczesny zakres

Przychód i rozwój obejmują stację paliw. Sklep, myjnia, restauracja, warsztat, motel i parking mają modele oraz czynności w świecie, a ich własne transakcje i ulepszenia są w planie rozwoju. Pracownicy widoczni na mapie są postaciami otoczenia. System zatrudniania, automatyzacja i kolejki wielostanowiskowe pozostają oddzielnym etapem.

Zapis z 0.1.0 zachowuje poziom, ustawienia i środki. Materiały sprawdzono w renderze Compatibility i przygotowano APK debug. Pomiar 30 i 60 FPS na fizycznych urządzeniach, test wycięć ekranu i eksport iOS wymagają sprzętu docelowego. Szczegóły są w [raporcie testów](TEST_REPORT.md).
