# Balans z monetyzacją · 0.7.0

Cztery warianty uruchomiły tę samą kampanię od nowego zapisu na ziarnie 612. Pierwsza godzina jest aktywna. Potem symulator wraca średnio trzy razy na dobę przez sześć minut, inwestuje wpływy i odwiedza wcześniej otwarte lokalizacje. Wariant sporadyczny dodaje BOOST co najmniej co 30 minut między odsłonami. Wariant regularny robi to co najmniej co 366 sekund. Przerwy obejmują tylko rzeczywistą część bonusu. Wariant pakietów otrzymuje zawartość startera, pakietu rozbudowy i 550 diamentów z konfiguracji. Skrypt symuluje wybory, wypłaty i naliczanie. Nie wykonuje płatności ani żądań SDK. [Kod](../tests/monetization_balance.gd) · [Surowe wyniki](balance-0.7.0.json)

| Wariant | Czas | Mapy | Usługi | Suma poziomów | Zakończone filmy | Pakiety | Obrót | Zysk offline |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Bez reklam i zakupów | 1 h | 3 | 13 | 195 | 0 | 0 | 166 413 | 0 |
| Bez reklam i zakupów | 24 h | 5 | 20 | 312 | 0 | 0 | 1 000 442 | 813 279 |
| Bez reklam i zakupów | 7 dni | 6 | 41 | 2 767 | 0 | 0 | 11 876 892 887 | 11 787 820 478 |
| Bez reklam i zakupów | 30 dni | 6 | 41 | 4 001 | 0 | 0 | 14 973 497 655 512 | 14 919 600 858 238 |
| Sporadyczny BOOST | 1 h | 3 | 13 | 216 | 2 | 0 | 200 419 | 0 |
| Sporadyczny BOOST | 24 h | 5 | 18 | 328 | 5 | 0 | 5 355 789 | 5 038 639 |
| Sporadyczny BOOST | 7 dni | 6 | 41 | 2 811 | 23 | 0 | 12 426 481 055 | 12 259 068 411 |
| Sporadyczny BOOST | 30 dni | 6 | 41 | 4 002 | 92 | 0 | 15 769 357 265 775 | 15 665 779 614 706 |
| Regularny BOOST | 1 h | 4 | 15 | 265 | 10 | 0 | 386 806 | 0 |
| Regularny BOOST | 24 h | 6 | 22 | 397 | 13 | 0 | 5 751 027 | 5 223 665 |
| Regularny BOOST | 7 dni | 6 | 41 | 2 976 | 31 | 0 | 16 304 632 115 | 15 876 076 318 |
| Regularny BOOST | 30 dni | 6 | 41 | 4 008 | 100 | 0 | 15 842 846 471 307 | 15 741 391 391 752 |
| Pakiety premium | 1 h | 3 | 11 | 183 | 0 | 3 | 167 114 | 0 |
| Pakiety premium | 24 h | 5 | 18 | 300 | 0 | 3 | 1 954 856 | 1 766 992 |
| Pakiety premium | 7 dni | 6 | 41 | 2 701 | 0 | 3 | 8 821 507 952 | 8 758 111 738 |
| Pakiety premium | 30 dni | 6 | 41 | 3 999 | 0 | 3 | 15 645 776 346 852 | 15 591 089 820 046 |

Wszystkie cztery warianty otworzyły sześć lokalizacji i 41 usług. Cała kampania w wariancie bez reklam i zakupów była dostępna w pierwszym tygodniu. Cechy flow przerywników, współczynnik dostępności reklam i rzeczywiste decyzje gracza mogą zmienić tempo. Wyniki są deterministyczne dla tej kadencji i ziarna.
