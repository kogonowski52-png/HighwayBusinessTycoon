# Projekt gry · Trasa 17

## Dobrowolna monetyzacja

Wydanie 0.7.0 pozwala otworzyć cały atlas za gotówkę z obsługi. BOOST ×2 wpływa na wynagrodzenie za usługi i część rozliczenia offline. Pakiety dają określone składniki, a darmowa ścieżka przepustki działa od pierwszego otwartego regionu. Ceny produktów pochodzą z lokalnego Google Play. Osobne przyciski informują o pełnej nagrodzie przed otwarciem filmu. [Reguły i balans](docs/MONETIZATION.md)

## Kampania sześciu tras

Stacja Północ finansuje Copper Mile, następnie trasa prowadzi przez Green Valley, Alpine Pass i Ocean Coast do Metro City. Dostęp wymaga gotówki, określonej reputacji i rozwoju biznesu poprzednika. Powroty są bezpłatne. Zlecenia, pracownicy, aktywne karty, postęp rozbudowy i wpływy są przypisane do regionu. Karty posiadane przez gracza, ustawienia i kalendarz są wspólne.

Przeładunek w Meridian i składowanie w Junction rozliczają przyjęcie lub wydanie towaru po zakończeniu wizyty. Apex Motors rozlicza sprzedaż dostępnego auta, a Crossline obsługuje niezależne stanowiska przy parkingu. Szacunki offline nie zmieniają fizycznych dostaw ani stanu samochodów na ekspozycji. Album regionu nagradza spotkanie trzech wskazanych pojazdów na danej trasie. [Reguły etapu 5](docs/STAGE5_STATUS.md)

Gracz uruchamia kolejne usługi obsługi drogowej. Ruch widoczny na mapie wpływa na sprzedaż. Wyposażenie, pracownicy i menedżerowie przyspieszają proces. Wszystkie nagrody potrzebne do postępu pochodzą z rozgrywki.

W rozwoju sieci gracz kupuje dostęp do Copper Mile z zysków Stacji Północ. Dwie lokalizacje mają własne inwestycje, załogi, statystyki i zarobki w czasie postoju. Rozliczone wizyty zasilają tygodniowe wydarzenia, kontrakty i kolekcje, a komplet rozbudów lokalnych pozwala zdobyć prestiż. [Ekspansja i reguły kampanii](docs/EXPANSION.md)

## Pętla i rozwój

- Pierwszy klient czeka przy dystrybutorze. Początkowe 120 zł i 35 zł za tankowanie pokrywają koszt pierwszego ulepszenia. Zadania za obsługę i ulepszenie zapewniają środki na pierwszego pracownika.
- Pieniądze z ręcznej obsługi trafiają bezpośrednio do portfela. Sprzedaż przez pracownika trafia do kasy obiektu. Gracz odbiera całość w dowolnej chwili. Aktywna Ada pobiera wpływy automatycznie.
- Odblokowywanie wymaga reputacji, środków i poziomu wcześniejszej usługi. Po odblokowaniu każdy obiekt ma poziomy 1–100. Zakup +10 i +25 wymaga całej kwoty. Przy poziomie 100 liczba kupowanych poziomów jest odpowiednio ograniczona. MAX kupuje tylko poziomy mieszczące się w portfelu.
- Stanowiska otwierają się na progach właściwych dla obiektu. Wydajność i wysokość stawki rosną wraz z poziomem. Na mapie pojawiają się wyposażenie, nowe oznaczenia i oświetlenie, a stacja zachowuje pięć pierwotnych modułów.
- Cele i osiągnięcia mają znane nagrody. Trzy rotujące wydarzenia przyznają punkty za obsługę wybranych usług, premię za cel dnia i stałe wymiany na diamenty lub kartę Miry. Diamenty włączają dobrowolną premię przychodową na trzy minuty.
- Poziom gracza rośnie od 1 do 20 za obsługę, rozbudowę i rozwój zespołu. Nagrody za osiągnięte poziomy można odebrać w Karierze. Rozdziały zawierają po dziesięć celów związanych z konkretną usługą. Kolejną serię otwiera odebranie dwóch celów z poprzedniej.
- Karty zdobywa się w misjach, osiągnięciach i wymianie za punkty wydarzeń. Gracz może aktywować trzech z piętnastu menedżerów. Rozwój od rangi 1 do 5 kosztuje zarobione diamenty i wymaga poziomu gracza. W danej usłudze działa najsilniejszy pasujący efekt danego rodzaju. Ada odbiera wpływy w całym kompleksie. Wyniki specjalistów dotyczą ich usług. Olu i Jo potrafią obsłużyć pojedynczego klienta samodzielnie, gdy w ich obiekcie brakuje pracownika.
- Kalendarz udostępnia jedną nagrodę na dobę UTC. Dzień bez logowania zachowuje kolejny etap cyklu. Po dniu 30 następne odebranie wraca do pierwszego pola. Powtórzona karta daje sześć diamentów, a kupon czeka w sklepie do aktywacji. Znacznik ostatniej nagrody korzysta z tego samego zapisywanego czasu co wpływy offline.
- Osiągnięcia obejmują po pięć progów dla dziesięciu wskaźników. Każda odznaka ma aktualny postęp i jednorazową nagrodę diamentową. Doświadczenie karty rośnie po sprzedaży w specjalizacji przypisanego menedżera. Wymagania i cena awansu zachowują reguły kariery.

## Klienci, drogi i obsługa

| Profil | Zachowanie |
| --- | --- |
| Mieszkaniec | Najczęściej tankuje i robi zakupy, ma ograniczony budżet i dość długi czas oczekiwania. |
| Podróżny | Preferuje paliwo, posiłek lub postój, rezygnuje szybciej od lokalnego klienta. |
| Kierowca ciężarówki | Używa osobnego wjazdu i kolejki. Wybiera tankowanie lub parking TIR. |
| Turysta | Najchętniej parkuje, korzysta z restauracji i motelu. |
| Rodzina | Częściej odwiedza sklep, restaurację i parking oraz dłużej czeka na obsługę. |
| Biznesowy | Zostawia większy napiwek, preferuje szybką obsługę i ma krótszą cierpliwość. |
| VIP | Pojawia się po zdobyciu reputacji, ma największy budżet i najkrótszą cierpliwość. |
| Kierowca EV | Pojawia się przy działających ładowarkach. Wybiera ładowanie lub wizytę w ogólnodostępnej usłudze. |

Przyjazdy wybierają otwarte usługi pasujące do typu pojazdu i budżetu. Wagi rosną wraz z rozbudową i maleją przy zatłoczeniu. Pojazd może wybrać alternatywną usługę lub opuścić teren po przekroczeniu cierpliwości. Auta jadą przez narysowane na mapie wjazdy, kolejki i stanowiska. Pieszy idzie od auta do usługi i wraca przed wyjazdem. Pracownicy przydzieleni do obiektu podchodzą do zarezerwowanego zadania oraz wykonują animację odpowiednią dla usługi.

Rezerwacja wszystkich sektorów manewru jest atomowa. Gdy pojazd osiągnie miejsce obsługi, zwalnia korytarz i pozostaje na swoim stanowisku. Hamowanie zależy od odstępu. Awaryjny mechanizm zwalnia rezerwację po trwałym zatrzymaniu bez przyznawania przychodu za niedokończoną usługę.

## Zarobki offline

Szacowanie korzysta z obsady, stawek, trwałych premii i zachowawczego tempa przyjazdów. Startowy limit jednej nieodebranej wypłaty to 2 godziny. Zakupy za gotówkę wydłużają go do 4, 6, 8, 10 i 12 godzin. Starsze profile z limitem ośmiu godzin zachowują próg 8 h. Okno pokazuje czas poza grą oraz czas objęty wypłatą. Ostatni zapisany znacznik czasu blokuje powielanie okien po cofnięciu zegara. Wznowienie tego samego procesu dodatkowo porównuje czas urządzenia z monotonicznym. Środki można zawsze odebrać bezpłatnie. Dotychczasowy opcjonalny moduł nagradzanej reklamy zachowuje warunkowy przycisk dla dostawcy.

Parametry i przebieg symulacji. [Dane ekonomii](data/economy) · [Raport balansu 0.4.0](docs/balance-0.4.0.md)
