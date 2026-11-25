# Balans Copper Mile · 0.6.0

Symulacja zaczyna się po otwarciu Desert Highway z 190 zł i dystrybutorem na poziomie 1. Używa tego samego ruchu, płac, kas, misji i wzorów co gra. Skrypt odbiera zarobione nagrody, zatrudnia, szkoli, inwestuje i wraca trzy razy dziennie na sześć minut. Wykonano 18 pomiarów dla trzech ziaren. Przebieg nie pobiera nagród wydarzeń specjalnych i nie przyjmuje kontraktów. [Surowy raport](balance-0.6.0.json)

| Czas od otwarcia | Działające usługi | Pracownicy | Najwyższy poziom | Najniższy poziom | Odebrane misje i cele | Przerwane przejazdy |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 min | 2 | 2 | 10–11 | 0 | 11–13 | 0 |
| 30 min | 5 | 8 | 20–22 | 0 | 44–48 | 0 |
| 2 h | 10 | 20 | 37 | 28–29 | 112–113 | 0 |
| 24 h | 10 | 22 | 75–76 | 67–68 | 135–136 | 0 |
| 7 dni | 10 | 22 | 95 | 93–94 | 142–143 | 0 |
| 30 dni | 10 | 22 | 100 | 99 | 152 | 0 |

Pierwsze tankowanie rozlicza się po 2,75 s. Pierwsze ulepszenie pojawia się po 4,25 s. Pierwotny próg serwisu TIR nie pozwalał części ziaren otworzyć piątej usługi do 30. minuty. Obniżono koszt wejścia oraz wymagany poziom łazienek. Wynik końcowy przechodzi 46/46 kontroli. Zakupy opierają się na przychodzie, reputacji i warunkach lokalnych. Kampania używa aktywnej rozgrywki i ograniczonych powrotów, więc czasy opisują tę konkretną strategię.

Symulacja Stacji Północ przechodzi 46/46 kontroli, a jej JSON jest identyczny z opublikowanym 0.4.0. [Wyniki Stacji Północ](balance-0.4.0.md)

```bash
godot --headless --path . --script tests/desert_balance.gd -- --report=/tmp/copper-mile-balance.json
```
