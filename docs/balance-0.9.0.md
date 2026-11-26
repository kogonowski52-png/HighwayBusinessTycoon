# Kampania i balans · 0.9.0 RC

`tests/campaign_balance.gd -- --release-horizons` podejmuje zwykłe akcje gry. Symulowane są obsługa i opuszczanie stanowisk, premie misji, ulepszenia, zatrudnianie, podróże, limit wypracowania offline i wizyty po nieobecności. Są to trzy deterministyczne przebiegi z ziarnami 41, 612 i 7283 bez zakupów i reklam. Po pierwszych dwóch godzinach harmonogram zakłada kolejne wizyty w zapisie. Czasy z tabeli dotyczą harmonogramu symulacji. [Dane z przebiegu](qa-0.9.0/campaign-balance.json)

| Czas od startu | Lokalizacje | Usługi | Suma poziomów | Pracownicy | Menedżerowie | Misje | Przychód łączny |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 min | 2 | 6 | 31–35 | 6 | 4 | 28–33 | 6 337–7 634 |
| 15 min | 2 | 8 | 66–70 | 8 | 4 | 43–50 | 17 971–18 630 |
| 30 min | 2 | 10 | 116–126 | 12–14 | 4 | 66–70 | 57 814–79 868 |
| 2 h | 4 | 16–17 | 309–326 | 27–28 | 5 | 145–147 | 501 439–521 867 |
| 1 dzień | 6 | 22–24 | 404–430 | 36–39 | 5 | 179–183 | 4 053 376–4 834 794 |
| 3 dni | 6 | 39–40 | 1 172–1 208 | 68–71 | 9–11 | 323–330 | 130 163 736–136 816 631 |
| 7 dni | 6 | 41 | 2 914–2 969 | 93 | 20–21 | 476–481 | 11 685 788 776–14 461 349 072 |
| 14 dni | 6 | 41 | 3 753–3 781 | 93 | 22 | 516–521 | 1 858 881 602 490–1 910 686 656 784 |
| 30 dni | 6 | 41 | 4 008–4 009 | 93 | 22 | 553–556 | 15 445 330 594 453–16 258 894 202 660 |

Pierwsza sprzedaż zajęła 2,75 s i pierwsze ulepszenie 4,25 s we wszystkich próbach. Oferty reklam i zakupów nie były potrzebne do otwarcia wszystkich map i usług. Kadry z rzeczywistego okna potwierdziły pierwszą obsługę, rozbudowę, rekrutację oraz odbiór nagród. Karta następnej inwestycji pokazuje miejsce, koszt i niewypełnione warunki. Po miesiącu w modelu regularnych wizyt pozostaje około 90 poziomów i ponad 30 misji rozdziałowych. Prestiż, kolekcje i wydarzenia zapewniają dalsze cele. Częste wizyty w symulacji sprawiają, że w dłuższym okresie duża część obrotu pochodzi z wypłat offline. Te dane nie mierzą faktycznej retencji ludzi ani częstotliwości ich powrotów.

## Porównanie z monetyzacją

Próba `tests/monetization_balance.gd` korzysta z kontrolowanych założeń o ukończonych reklamach i pakietach. Przetestowano 4 warianty po 1 h, 1 dniu, 7 i 30 dniach. Zastosowano tę samą logikę przychodu i awansu, bez połączeń z AdMob lub Play. [Dane wariantów](qa-0.9.0/monetization-balance.json)

| Scenariusz | Usługi po 1 h | Usługi po 1 dniu | Usługi po 7 dniach | Poziomy po 30 dniach |
| --- | ---: | ---: | ---: | ---: |
| Bez reklam i zakupów | 13 | 20 | 41 | 4001 |
| Okazjonalne reklamy | 13 | 18 | 41 | 4002 |
| Regularny BOOST | 15 | 22 | 41 | 4008 |
| Pakiety premium | 11 | 18 | 41 | 3999 |

55/55 sprawdzeń kampanii i 21/21 sprawdzeń wariantów monetyzacji przeszło. Wycena oraz główne warunki awansu zachowują zgodność wcześniejszych zapisów.
