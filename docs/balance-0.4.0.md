# Balans 0.4.0 · Trasa 17

Symulacja korzysta z tej samej ekonomii, rezerwacji, cierpliwości i logiki zarobków offline co gra. Ziarna to 41, 612 i 7283. Pierwsze dwie godziny są aktywne, z zakupami sprawdzanymi co dwie sekundy. Dłuższe przebiegi obejmują trzy krótkie sesje dziennie, odbiór zarobków offline oraz ponowne inwestowanie wpływów. Symulator odbiera jawne nagrody, zatrudnia, szkoli, uruchamia nowe obiekty i rozwija limit offline za gotówkę. Tempo opisuje tę aktywną strategię.

| Czas | Otwarte usługi | Pracownicy | Najwyższy poziom obiektu | Poziom gracza | Karty | Limit offline | Przychód narastająco (zł) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 min | 5–6 | 5–6 | 11–12 | 8 | 4 | 2–4 h | 10 081–12 365 |
| 30 min | 11 | 15–16 | 27 | 13 | 11–13 | 8 h | 425 634–485 122 |
| 2 h | 11 | 23 | 59–60 | 17 | 15 | 12 h | 50 891 920–56 931 544 |
| 24 h | 11 | 26 | 83–86 | 18 | 15 | 12 h | 38 424 258 062–40 670 878 286 |
| 7 dni | 11 | 26 | 100 | 20 | 15 | 12 h | 6 926 594 492 580–6 966 208 997 821 |
| 30 dni | 11 | 26 | 100 | 20 | 15 | 12 h | 60 048 691 138 773–60 091 829 808 858 |

Pierwsza wypłata nastąpiła po 2,75 s, pierwszy zakup po 4,25 s. Po dwóch godzinach koszt inwestycji wyniósł 50,9–57,0 mln zł. Z ostatniej aktywnej minuty tego etapu pochodziło 1,44–2,53 mln zł. Pomiar przy 24 h wypada między sesjami, więc licznik przychodu z ostatnich 60 sekund wynosi wtedy zero. Po tygodniu najsłabszy obiekt miał poziom 97, a po miesiącu każdy osiągnął 100.

| Usługa | Otwarcie w trzech przebiegach |
| --- | --- |
| Stacja paliw | Od początku |
| Sklep | 18–30 s |
| Parking samochodowy | 54–80 s |
| Myjnia | 2:12–3:00 |
| Paliwo TIR | 3:00–3:18 |
| Warsztat | 4:46–7:54 |
| Restauracja | 8:08–11:10 |
| Wulkanizacja | 11:20–13:22 |
| Parking TIR | 14:26–17:08 |
| Motel | 17:46–21:22 |
| Ładowarki EV | 19:46–23:06 |

Wszystkie przebiegi zakończyły się bez awaryjnego zwalniania rezerwacji. We wczesnym teście wykryto dwa konflikty przestrzenne. Przesunięto zatokę naczep i zwiększono odstęp między placem EV a wyjazdem wulkanizacji. Następnie powtórzono symulację oraz testy wszystkich 26 stanowisk.

Strategia symulacji odebrała 116 z 120 dostępnych nagród misji i osiągnięć. Część końcowa związana z rangami wymaga szkolenia większej liczby menedżerów niż przewiduje strategia. Osobny test ekonomii odebrał wszystkie 120 nagród i wszystkie karty. Standardowy eksport działa offline, a wszystkie opłaty w tych próbach pochodziły z walut gry.

[Pełne dane z 18 przebiegów pomiarowych](balance-0.4.0.json) · [Raport testów](../TEST_REPORT.md)
