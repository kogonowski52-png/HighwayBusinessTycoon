# Highway Business Tycoon 0.9.1 · rozbudowa i dotyk

Ujęcia pochodzą z działającego Godota 4.7.2 w pionowym oknie na Linuksie. Stan testu przygotował środki, reputację i poziom stacji, dzięki czemu porównanie pokazuje wszystkie typy kart. Przebieg pierwszej zmiany bez dodatkowych środków sprawdza osobny test kariery. [Raport prób](../../TEST_REPORT.md)

| Ujęcie | Kadr |
| --- | --- |
| Młotek i cena na mapie | [Gotowa inwestycja](00-pin-inwestycji.jpg) |
| Panel Rozbudowa | [Wszystkie usługi i wskazówka samouczka](01-rozbudowa.jpg) |
| Gotowe inwestycje | [Dostępne](02-dostepne.jpg) |
| Warunki budowy | [Zablokowane](03-zablokowane.jpg) |
| Otwarta inwestycja | [Kamera po budowie sklepu](04-sklep-wybudowany.jpg) |
| Zarządzanie obiektami | [Wybudowane](05-wybudowane.jpg) |
| Więcej miejsca na mapę | [Zwinięty panel](06-panel-zwiniety.jpg) |

[Porównanie światła i kart 0.9.0 → 0.9.1](porownanie.jpg) · [Nagranie przewijania](przewijanie.mp4)

Kadry dzienne i złotej godziny używają tego samego kadru zwykłej rozgrywki. Punkt skupienia Stacji Północ to `(-0,74, 0,62, 0,57)`, a szerokość ortograficzna to `22,6`. Nagranie Movie Maker pokazuje rzeczywiste `InputEventScreenTouch` i `InputEventScreenDrag` uruchamiające przewijanie oraz przejście do Dostępnych. [Scenariusz](../../tests/mobile_input_window.gd)
