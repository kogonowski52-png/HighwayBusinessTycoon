# Balans Advanced Gameplay

Dotychczasową kampanię uruchomiono na trzech nowych zapisach z ziarnami 41, 612 i 7283. Symulator używał prawdziwej ekonomii i kolejek. Po pierwszych dwóch godzinach wchodził do gry na sześć minut trzy razy dziennie. Nie kupował floty, reklam ani płatnych pakietów. Wynik 55/55 potwierdza wykonalność ścieżki bez nowych systemów.

| Moment | Otwarte regiony | Otwarte biznesy | Suma poziomów |
| --- | ---: | ---: | ---: |
| 5 minut | 2 | 6 | 31–35 |
| 30 minut | 2 | 10 | 116–122 |
| 2 godziny | 4 | 16–18 | 309–319 |
| 1 dzień | 6 | 22–24 | 404–422 |
| 7 dni | 11 | 63–65 | 2589–2682 |
| 14 dni | 12 | 80–83 | 5409–5557 |
| 30 dni | 12 | 84 | 7877–7894 |
| 60 dni | 12 | 84 | 8292–8296 |

Pierwsza sprzedaż następowała po 2,75 s, a pierwsza modernizacja po 4,25 s. Wszystkie trzy przebiegi rozwinęły 84 biznesy do 30. dnia. [Surowe dane 60 dni](qa-0.9.5/economy.json) · [Symulator](../tests/campaign_balance.gd)

## Flota i decyzje o wydatkach

Północ na poziomie 4 może uruchomić bazę za 980 zł, co obejmuje dostawczaka i pierwszego kierowcę. Krótka dostawa dwóch jednostek części oferuje 169 zł przy 30 zł kosztu i 39 s jazdy na podstawowym poziomie auta. Przed kosztem przeglądu zwrot nakładu wymaga ośmiu kursów. Każde wznowienie tej trasy respektuje 30 s przerwy i stan techniczny auta. Naczepy i kursy chłodnicze, kontenerowe, paliwowe lub samochodowe mają oddzielne warunki wejścia.

Ładunki zwiększają sprawność zgodnych biznesów o ograniczoną liczbę wizyt. Materiały redukują najbliższy zakup budowlany o 5% za jedną jednostkę zapasu. Ukończone kursy rozliczają kwotę z podpisanej dyspozycji. BOOST obejmuje normalne wpływy z wizyt. Nagrody za dostawy i mini-gry są stałe.

Kampania paliwowa zmieniła liczbę lokalnych kierowców ze 135 do 244 w dwóch porównywalnych próbach po 400 przyjazdów. Koszt zależy od ceny paliwa, a dodatkowe wizyty nadal wymagają wolnych stanowisk. Decyzja o kampanii zależy więc od obsady i możliwości placu. [Próby ekonomii](../tests/estate_checks.gd) · [Sprawdzenie kosztu, wypłaty i idempotencji](../tests/transport_checks.gd)
