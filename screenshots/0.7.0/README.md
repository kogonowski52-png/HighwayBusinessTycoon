# Highway Business Tycoon 0.7.0 w działającym Godocie

Galeria ma 30 odczytów renderowanego widoku 640 × 1138. Kadry od 13 zawierają oznaczenie próby silnika. Skrypt uruchamia panel gry i wkłada kontrolowane zdarzenie na granicy adaptera reklamy. Android w kompilacji testowej używa prawdziwego SDK. Pokazane próby nie nagrywają filmu reklamowego ani transakcji Play i nie mają spreparowanych cen.

| Widok | Materiał |
| --- | --- |
| BOOST bez sieci, przygotowanie i gotowy film | [Bez sieci](02-boost-bez-polaczenia.jpg) · [Przygotowanie](13-boost-przygotowanie.jpg) · [Gotowy film](14-boost-film-gotowy.jpg) |
| Aktywacja, wskaźnik na mapie i dodatkowy czas | [Aktywny](16-boost-aktywny.jpg) · [Złoty licznik](17-zloty-licznik-w-swiecie.jpg) · [Przedłużenie](18-boost-przedluzenie.jpg) · [Limit](19-limit-trzydziesci-minut.jpg) |
| Sklep | [Oferty](03-start-sklep.jpg) · [Diamenty](04-pakiety-diamentow.jpg) · [Rozbudowa](05-pakiet-rozbudowy.jpg) · [Bonusy](06-darmowe-bonusy.jpg) |
| Przepustka | [Ścieżka darmowa](08-przepustka-darmowa.jpg) · [Ścieżka premium](09-przepustka-premium-zablokowana.jpg) · [Postęp](27-przepustka-postep.jpg) · [Uprawnienie testowe](28-przepustka-premium-test.jpg) |
| Nagrody w świecie | [VIP](22-vip-na-drodze.jpg) · [Furgonetka](23-furgonetka.jpg) · [Ciężarówka](24-zlota-ciezarowka.jpg) · [Helikopter](25-helikopter.jpg) · [Wybór gracza](26-oferta-helikoptera.jpg) |
| Pozostałe ekrany | [Modernizacja](20-oferta-modernizacji.jpg) · [Prywatność](12-prywatnosc.jpg) · [Rozliczenie offline](29-zarobki-offline-z-boost.jpg) · [Język angielski](30-boost-en.jpg) |

Nagranie pokazuje pełną akcję przycisku, oczekiwanie na potwierdzenie, aktywację na 300 sekund i rzeczywiste naliczenie 70 zł dla usługi o stawce 35 zł. [Nagranie MP4](aktywacja-boost.mp4)

```bash
godot --path . --script tests/monetization_window.gd -- --capture-dir=/tmp/hbt-070-gallery
godot --path . --write-movie /tmp/hbt-070-boost.avi --fixed-fps 30 --script tests/monetization_recording.gd
```
