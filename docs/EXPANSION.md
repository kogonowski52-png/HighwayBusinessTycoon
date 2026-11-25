# Ekspansja Trasy 17

Poniższy opis utrwala wydanie 0.6.0. Aktualny stan wszystkich sześciu regionów i weryfikację braków przedstawia audyt 0.6.1. [Etap 5](STAGE5_STATUS.md)

Atlas otwiera się przyciskiem **Atlas** przy widoku mapy. Copper Mile wymaga poziomu 3 na dystrybutorach Trasy 17, reputacji 6 i 670 zł. Gracz płaci przy otwarciu, a potem podróżuje bez opłat. Karta pokazuje rangę, odblokowane usługi, procent rozwoju i godzinową estymację offline opartą o obsadę. Szacunek różni się od bieżącej sprzedaży. Animacja podróży otwiera inną scenę i wyłącza krok symulacji poprzedniej.

| Region | Zawartość w 0.6.0 |
| --- | --- |
| Stacja Północ | Pierwotna mapa z 11 czynnymi usługami, bieżącym personelem i misjami. |
| Desert Highway | Copper Mile z niezależną sceną, dwoma wjazdami, 10 czynnymi biznesami i 10 rozdziałami po 16 misji. |
| Green Valley | Zapowiedź w atlasie. |
| Alpine Pass | Zapowiedź w atlasie. |
| Ocean Coast | Zapowiedź w atlasie. |
| Metro City | Zapowiedź w atlasie. |

Copper Mile obejmuje dwustanowiskową stację, kawiarnię, toalety, parking VIP, serwis ciężarówek, prysznice, motel, parking TIR, grill drive-through i szybkie ładowanie. Każda usługa ma cennik, ruch i rezerwacje, uprawnione pojazdy, płatną obsługę, rzeczywistą animację personelu, 100 poziomów i pięć etapów z wyposażeniem fizycznie widocznym na placu. Serwis, łazienki kierowców i postój korzystają z odrębnego pasa TIR. Goście gastronomii i motelu wychodzą z pojazdów. Grill obsługuje kierowcę przy okienku. Obsługa szybkiego ładowania przełącza lampę stanowiska podczas wizyty. [Modele i obsługa z silnika](../screenshots/0.6.0/README.md)

## Gospodarka i synchronizacja lokalna

Każdy region ma własny portfel, stanowiska, kasy, pracowników, stopień kariery, przydziały menedżerów, misje i czas offline. Biblioteka kart i ich rang, preferencje, odbiory kalendarza i odznak oraz kolekcje są wspólne. Gracz może przypisać tych samych menedżerów odrębnie w każdym regionie. Procent rozwoju to suma zakupionych poziomów podzielona przez maksymalną liczbę poziomów w danej lokalizacji. Każdy region ma własne godziny limitu, wynikające z zakupów za gotówkę.

Schemat 6 zachowuje profil Stacji Północ w korzeniu pliku. Blok kampanii zawiera drugi profil, wybór ostatniej mapy i stan okresowy. Jeden atomowy zapis obejmuje koszt otwarcia, przejście i znaczniki czasu obu map. Przy przejściu poprzednia mapa zapisuje moment postoju. W nowej naliczany jest tylko przedział od jej znacznika, z własnym limitem. Dochód czeka na oddzielny odbiór. Scena i biznes gracza działają w tym momencie w jednym regionie.

## Tydzień na autostradzie

Sześć wydarzeń w konfiguracji wyznacza 42-dniowy cykl UTC. Runda trwa pięć dni, a dwa kolejne pozwalają zobaczyć podsumowanie i odebrać uzyskany komplet. Wypadkowe zadania wynikają z rozliczonych wizyt. Tematyczny pojazd przyjeżdża, gdy profil klienta i dostępne usługi pozwalają go obsłużyć. Każda runda ma trzy cele, odpowiednią dekorację, nagrodę i archiwum wyników. Cofnięcie czasu nie ponawia rundy. Po ponownym uruchomieniu gra offline korzysta z zegara urządzenia, więc duże przesunięcie do przodu może przenieść kalendarz do kolejnej rundy. [Harmonogram i nagrody](../data/world/expedition_calendar.gd)

Gracz może przyjąć do trzech kontraktów równocześnie w jednym regionie. Istnieją zlecenia na sprzedane litry, naprawy, przychód, VIP, ciężarówki, wykonanie dostaw i zakupy rozbudowy. Litry liczą się z zakończonych transakcji paliwowych. Faktyczne wyładowanie paczki przed sklepem Trasy 17 zalicza dostawę. Czas biegnie także podczas podróży. Ukończenie i odbiór nagrody są zapisywane oddzielnie.

Modele pojazdów można odkryć przy kompleksie i po zakończonych wizytach. Kolekcja menedżerów korzysta z istniejących portretów. Medalion, dekorację, szyld lub daszek widać w podglądzie 3D i po ustawieniu w terenie. Premię za zestaw można odebrać raz.

## Prestiż

Poziom 100 wszystkich lokalnych usług otwiera osobny ekran potwierdzenia. Ranga daje stałe 5% premii do wyceny lokalnej sprzedaży oraz punkt sieci. Pierwszy punkt otwiera latarnię, drugi daszek Copper Classic. Reset obejmuje gotówkę, kasy, budynki, pracowników, lokalne misje i bieżące statystyki. Zachowuje pozostałe regiony, rangę gracza i nagrody za rangę, reputację, diamenty, punkty, przydziały kart, limit i zaległą wypłatę offline oraz cały wspólny profil. Samo wejście na ekran i wyjście zachowuje stan.

Warstwa `progress_gateway.gd` określa dane tożsamości, wersję protokołu, rewizję zapisu, synchronizację oraz dane przyszłego harmonogramu i rankingów. Zapis lokalny pozostaje źródłem prawdy w wydaniu testowym.

## Następne obiekty

Centrum logistyczne, magazyn, salon samochodowy i centrum handlowe mają status planu. Obecne pokazy działającego świata obejmują dwie ukończone lokalizacje.
