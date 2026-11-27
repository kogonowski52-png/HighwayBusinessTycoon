# Advanced Gameplay · 0.9.5 RC

Centrum imperium otwiera się z panelu finansów pod ikoną monet. Widać w nim wpływy całej kampanii i poszczególnych regionów, najlepszy biznes, obsadę, liczbę klientów, BOOST, flotę i następną inwestycję. Poziom imperium rośnie za kontrakty transportowe, certyfikaty oraz rozwój kompleksów. [Galeria i filmy](../screenshots/0.9.5/README.md)

| System | Dostępność i działanie |
| --- | --- |
| Flota | Poziom 4 stacji udostępnia bazę. Można kupić dostawczaka, ciężarówkę, cysternę i ciągnik oraz pięć typów naczep. Kierowcy mają doświadczenie za trasę i sześć poziomów uprawnień. Pojazdy mają stan techniczny, poziom, koszty i przydział. Garaż i wyjazdy są widoczne na aktualnej mapie. |
| Dostawy | Każdy region ma pięć zleceń. Pojazd, kierowca, rodzaj ładunku, pojemność, cel i opłata są sprawdzane przy wysłaniu. Rozładunek zasila kasę bazy, a zapas trafia do celu. Przydzielony menedżer logistyki może wysyłać lokalne zlecenia aktywnej bazy. |
| Mini-gry | Precyzyjne tankowanie z czterema pomiarami, czyszczenie stref karoserii i załadunek z obracanymi paczkami w siatce. Dostępne przy odpowiednim działającym biznesie w jego panelu zarządzania. Przyznanie wyniku i pieniędzy używa tego samego zapisu. |
| Wnętrza | Sklep, warsztat, restauracja, myjnia, hotel, salon, centrum handlowe, magazyn i centrum logistyczne mają własne przekroje 3D. Panel wczytuje aktualny przekrój na żądanie, odsuwa dach i pokazuje personel oraz aktywną obsługę. Jednocześnie otwiera się jedno wnętrze. |
| Personalizacja | 60 opcji w dwunastu kategoriach. Elewacja, dachy i zadaszenia korzystają z kolorów wierzchołków. Meble, lampy i oznakowanie mają modele 3D. Podgląd działa przed zakupem. Wystrój i odblokowania są regionalne. |
| Infrastruktura | Dziesięć instalacji po trzy etapy. Nawierzchnie, bramy, oznakowanie, światła i przejścia są widoczne przy bazie. Etapy poprawiają czasy przejazdów, obsługi, ruch lub ocenę. |
| Marketing | Siedem płatnych w gotówce z gry kampanii o różnych odbiorcach, czasach i usługach. W danym regionie działa jedna kampania naraz. |
| Opinie i inspekcje | Ocena wykorzystuje oczekiwanie, odjazdy bez obsługi, rozwój placu i parametry personelu. Sześć certyfikatów zapewnia nagrody za realne wyniki. Brak zaliczenia inspekcji nie kosztuje pieniędzy. |
| Pracownicy | Awansowany pracownik może rozwijać sprawność, jakość lub mentoring. Parametry zmieniają czasy, przychody lub cenę szkolenia. Starsza kadra ma oznaczenia uniformu. |
| Wizyty specjalne | Osiem wariantów z wyróżnionym rzeczywistym pojazdem i trasą do dostępnej usługi. Zapłata po obsłużeniu, z animacją na mapie. |
| Reklamy dobrowolne | Pięć miejsc korzysta z dotychczasowej jednostki nagradzanej i weryfikuje kontekst po odpowiedzi SDK. Nagrody to 20 s krótsza dostawa, 30 s krótsze szkolenie, +20% z ostatniego zlecenia, +50% z wyniku mini-gry lub wskazana donica Sun. [Testy](../TEST_REPORT.md) |
| Zgodność | Kontynuacja kampanii, istniejących usług, ustawień i wspólnego BOOST. APK 9005 jest podpisane certyfikatem 9004. [Migracja](MIGRATION_095.md) |

Podczas podróży tylko aktywny kompleks uruchamia ruch przestrzenny. Dostawa między regionami przechowuje w zapisie moment rozładunku. Gracz obserwuje wyjazd lub dojazd, gdy odwiedza odpowiednią mapę. Pulpit rozlicza opłatę i wypłatę według kwoty przyjętej w chwili dyspozycji.

## Pozostałe prace

Cztery kolejne mini-gry dotyczące warsztatu, wulkanizacji, sklepu i restauracji pozostają do przygotowania. Przekroje pokazują aktualnie obsługiwane stanowisko w jednej sali. Wielopomieszczeniowe wnętrza i wielopojazdowe konwoje pozostają poza tym wydaniem. Fizyczne pomiary Androida i natywne próby reklam i zakupów są oddzielnym krokiem odbioru. [Wydajność](PERFORMANCE_095.md)
