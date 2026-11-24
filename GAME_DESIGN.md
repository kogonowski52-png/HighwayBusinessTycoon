# Projekt gry · Trasa 17

Gracz uruchamia kolejne usługi obsługi drogowej. Ruch widoczny na mapie wpływa na sprzedaż. Wyposażenie, pracownicy i menedżerowie przyspieszają proces. Wszystkie nagrody potrzebne do postępu pochodzą z rozgrywki.

## Pętla i rozwój

- Pierwszy klient czeka przy dystrybutorze. Początkowe 120 zł i 35 zł za tankowanie pokrywają koszt pierwszego ulepszenia. Zadania za obsługę i ulepszenie zapewniają środki na pierwszego pracownika.
- Pieniądze z ręcznej obsługi trafiają bezpośrednio do portfela. Sprzedaż przez pracownika trafia do kasy obiektu. Gracz odbiera całość w dowolnej chwili. Aktywna Ada pobiera wpływy automatycznie.
- Odblokowywanie wymaga reputacji, środków i poziomu wcześniejszej usługi. Po odblokowaniu każdy obiekt ma poziomy 1–100. Zakup +10 i +25 wymaga całej kwoty. Przy poziomie 100 liczba kupowanych poziomów jest odpowiednio ograniczona. MAX kupuje tylko poziomy mieszczące się w portfelu.
- Stanowiska otwierają się na progach właściwych dla obiektu. Wydajność i wysokość stawki rosną wraz z poziomem. Na mapie pojawiają się wyposażenie, nowe oznaczenia i oświetlenie, a stacja zachowuje pięć pierwotnych modułów.
- Cele i osiągnięcia mają znane nagrody. Trzy rotujące wydarzenia przyznają punkty za obsługę wybranych usług, premię za cel dnia i stałe wymiany na diamenty lub kartę Miry. Diamenty włączają dobrowolną premię przychodową na trzy minuty.

## Klienci, drogi i obsługa

| Profil | Zachowanie |
| --- | --- |
| Mieszkaniec | Najczęściej tankuje i robi zakupy, ma ograniczony budżet i dość długi czas oczekiwania. |
| Podróżny | Preferuje paliwo, posiłek lub postój, rezygnuje szybciej od lokalnego klienta. |
| Kierowca ciężarówki | Używa osobnego wjazdu, pasa oczekiwania i stanowiska TIR. |
| Turysta | Najchętniej parkuje, korzysta z restauracji i motelu. |
| Rodzina | Częściej odwiedza sklep, restaurację i parking oraz dłużej czeka na obsługę. |
| Biznesowy | Zostawia większy napiwek, preferuje szybką obsługę i ma krótszą cierpliwość. |
| VIP | Pojawia się po zdobyciu reputacji, ma największy budżet i najkrótszą cierpliwość. |

Przyjazdy wybierają otwarte usługi pasujące do typu pojazdu i budżetu. Wagi maleją przy zatłoczeniu. Pojazd może wybrać alternatywną usługę lub opuścić teren po przekroczeniu cierpliwości. Auta jadą przez narysowane na mapie wjazdy, kolejki i stanowiska. Pracownicy przydzieleni do obiektu podchodzą do zarezerwowanego zadania oraz wykonują animację odpowiednią dla usługi.

Rezerwacja wszystkich sektorów manewru jest atomowa. Gdy pojazd osiągnie miejsce obsługi, zwalnia korytarz i pozostaje na swoim stanowisku. Hamowanie zależy od odstępu. Awaryjny mechanizm zwalnia rezerwację po trwałym zatrzymaniu bez przyznawania przychodu za niedokończoną usługę.

## Zarobki offline

Szacowanie korzysta z obsady, stawek, trwałych premii i zachowawczego tempa przyjazdów. Czas jednorazowego naliczenia ograniczono do ośmiu godzin. Ostatni zapisany znacznik czasu blokuje powielanie okien po cofnięciu zegara. Wznowienie tego samego procesu dodatkowo porównuje czas urządzenia z monotonicznym. Środki można zawsze odebrać bezpłatnie. Opcjonalny Androidowy wariant reklamy podwaja część, na którą wydano ofertę, po potwierdzeniu odtwarzania przez dostawcę.

Parametry znajdują się w [data/economy](data/economy), a przebieg symulacji w [raporcie balansu](docs/balance-0.3.0.md).
