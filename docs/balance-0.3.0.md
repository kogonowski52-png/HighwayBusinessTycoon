# Symulacja ekonomii · 0.3.0

Symulacja używa tych samych klas ruchu, popytu, portfela, cen i dochodu offline co rozgrywka w Godocie. Trzy ziarna obejmują rzeczywiste przyjazdy i pełne ścieżki. Pierwsze dwie godziny to aktywna sesja, później gracz wraca na sześć minut w cyklu co osiem godzin i na końcu każdego raportowanego horyzontu. Bot obsługuje wolne stanowiska, zatrudnia ludzi, odbiera osiągnięte cele i inwestuje bez reklam ani płatności. Wyniki opisują ten scenariusz.

| Horyzont | Otwarte obiekty | Pracownicy | Poziom paliw | Najwyższy poziom | Najniższy poziom | Klienci | Zarobiono łącznie | W tym offline |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 minut | 3–5 | 3–5 | 4 | 7–10 | 0 | 56–58 | 5 712–6 516 | 0 |
| 30 minut | 8 | 13–14 | 21–23 | 28–31 | 17–18 | 365–387 | 411 891–519 787 | 0 |
| 2 godziny | 8 | 18 | 56–57 | 64 | 48 | 1 480–1 501 | 82 786 098–95 469 146 | 0 |
| 1 dzień | 8 | 19 | 82–89 | 89–90 | 80–82 | 1 625–1 645 | 45 925 230 016–47 599 122 567 | 45 362 004 616–47 026 521 820 |
| 7 dni | 8 | 19 | 100 | 100 | 97–98 | 2 949–2 971 | 5 324 441 830 954–5 435 619 827 960 | 5 272 021 095 304–5 381 978 558 604 |
| 30 dni | 8 | 19 | 100 | 100 | 100 | 7 914–8 025 | 41 821 100 873 821–41 952 168 824 690 | 41 444 872 647 688–41 565 812 814 348 |

Pierwszy przychód wystąpił po **2,75 s**, a pierwsze ulepszenie po **4,25 s** we wszystkich trzech przebiegach. Na koniec 30 dni każda usługa osiągnęła poziom 100. Na koniec pierwszego tygodnia pozostały usługi na poziomie 97–98. Usunięcie konfliktów tras umożliwiło zwykłym przebiegom działanie bez awaryjnego zwalniania rezerwacji.

Regresja zakończyła się wynikiem **46/46**. Automatyczne progi obejmują pierwsze zarobki, pierwszą inwestycję, stopniowe odblokowywanie, zatrudnienie, ograniczanie zbyt szybkiego dojścia do limitu oraz sprawne zwalnianie rezerwacji. W oddzielnym teście sprawdzono też wzrost ceny i stawki na każdym z 100 poziomów każdej usługi.

Pełne dane z 18 punktów kontrolnych znajdują się w [pliku JSON](balance-0.3.0.json). Polecenie odtwarza ten raport.

```sh
godot --headless --path . --script tests/balance_simulation.gd -- --report=/pełna/ścieżka/balance-0.3.0.json
```
