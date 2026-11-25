# Balans kampanii 0.6.1

Godot uruchomił tę samą kampanię od czystego zapisu na ziarnach 41, 612 i 7283. Do 2 godzin test obsługuje grę aktywnie. Potem symuluje trzy sześciominutowe wizyty na dobę z powrotami do wcześniejszych lokalizacji. Symulator rozlicza prawdziwy ruch, odbiera kasy, realizuje dostępne nagrody, zatrudnia, szkoli i kupuje ulepszenia. Po spełnieniu warunków kupuje eskapadę za gotówkę poprzednika. Wyniki nie korzystają z nadanych środków, reklam ani prawdziwych zakupów. [Dane liczbowe](balance-0.6.1.json) · [Skrypt](../tests/campaign_balance.gd)

| Czas | Mapy | Otwarte usługi | Suma poziomów usług | Pracownicy | Odebrane cele | Karty | Obrót kampanii |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 5 min | 2 | 6 | 31–35 | 6 | 28–33 | 4 | 6 337–7 634 |
| 30 min | 2 | 10 | 116–126 | 12–14 | 66–70 | 4 | 57 814–79 868 |
| 2 h | 4 | 16–17 | 309–326 | 27–28 | 145–147 | 5 | 501 439–521 867 |
| 24 h | 6 | 22–24 | 404–430 | 36–39 | 179–183 | 5 | 4 053 376–4 834 794 |
| 7 dni | 6 | 41 | 2 914–2 969 | 93 | 476–481 | 20–21 | 11 685 788 776–14 461 349 072 |
| 30 dni | 6 | 41 | 4 008–4 009 | 93 | 553–556 | 22 | 15 445 330 594 453–16 258 894 202 660 |

## Odblokowanie tras

| Region | Pierwszy zakup od początku symulacji |
| --- | --- |
| Desert Highway | 0:03:36–0:04:18 |
| Green Valley | 0:39:04–0:42:26 |
| Alpine Pass | 1:39:10–1:41:00 |
| Ocean Coast | 9:54:00–9:54:00 |
| Metro City | 24:00:00–24:00:00 |

## Wyniki

Pierwszy przychód uzyskano po 2,75 s, a pierwsze ulepszenie po 4,25 s na każdym ziarnie. Wszystkie 41 usług otwarto w pierwszym tygodniu. Po 30 dniach pozostaje 91–92 poziomów do rozwoju, przy łącznej pojemności 4 100 poziomów. W badanych przebiegach nie zadziałał mechanizm awaryjnego usuwania zablokowanego pojazdu.

Dochód offline dominuje w późniejszej części sugerowanej kadencji. Wizyty w działających biznesach nadal są potrzebne do rozwoju reputacji, zatrudniania, dostaw i części celów. Pomiar odtwarza strategię deterministycznego symulatora. Tempo rzeczywistego gracza zależy od kolejności inwestycji, częstotliwości powrotów i rozwoju zespołów.

```bash
godot --headless --path . --script tests/campaign_balance.gd -- --report=/tmp/hbt-campaign.json
```
