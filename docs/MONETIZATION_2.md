# Monetyzacja 2.0

Na mapie przycisk BOOST pokazuje aktywny czas i gotowość filmu. Plus przy gotówce prowadzi do pakietów zawierających gotówkę, plus przy diamentach otwiera pakiety diamentów. Polecane oferty i darmowe nagrody mają osobne skróty. Pulsujący znacznik pojawia się przy oczekującej nagrodzie kalendarza lub gotowym filmie z nagrodą. [Kadry z Godota](../screenshots/1.0.0-beta.1/README.md)

## Nagrody i ekonomia

| Nagroda | Zasady |
| --- | --- |
| BOOST | 5 minut od kwalifikującej reklamy, przedłużenie do 30 minut, zawsze ×2 dla bazowego dochodu usług w 12 regionach. |
| Diamenty | 5 za film, do 5 filmów dziennie. Odstęp 30 minut. Dzienny licznik odnawia się o północy UTC. Misje, kalendarz i normalna gra nadal przyznają diamenty. |
| Gotówka | Wycena trzech minut dochodu z obsadzonych biznesów regionu na bazie stawki offline, minimum 120 zł. Wycena zapisywana przy wyborze filmu. Limit 4 dziennie co 10 minut. |
| Ulepszenie i szkolenie | Jeden poziom wskazanego biznesu lub pracownika, z ograniczeniami określonymi w konfiguracji. |
| Dostawa | Jedna paleta dla czynnego magazynu z miejscem lub jedna dostawa paliwa do stacji. Cysterna oferuje paliwo. |
| Kalendarz, wydarzenie, misja | Dodatek po odebraniu bazowej nagrody i spełnieniu wymogu danego okresu. |
| Karta i VIP | Dokładnie karta Reese Morgan albo wizyta płacącego klienta VIP. |
| Nowy region | Jednorazowa wskazana premia lokalna. Dostęp z Centrum nagród i karty aktualnego regionu. |

25 diamentów dziennie to twarde maksimum z tej jednostki. W siedem dni daje do 175 diamentów, w 30 dni do 750. Wymaga odpowiednio 35 lub 150 osobnych, ukończonych filmów. Pakiety z gry zawierają też uprawnienia i inne elementy. Podstawowe ceny i cele kampanii pozostają zgodne z zapisem 9005. [Limity i ceny](../data/monetization/config.gd) · [Testy kwot i zapisów](../TEST_REPORT.md)

Bonusy w ruchu obejmują VIP, furgonetkę, ciężarówkę, helikopter ze skrzynią podwieszaną, wolno obracającą się skrzynię i cysternę. Wykorzystują osobne modele wizualne poza kolejką usług. Dotknięcie otwiera konkretną ofertę. Emisję inicjuje akcja w tym panelu. Zadania floty i bonus za ukończoną mini-grę korzystają z istniejącego powiązania z rzeczywistą dostawą lub wynikiem.

## Tryby reklam i zakupów

Gotowy film otwiera się z pierwszego zaakceptowanego dotknięcia. Podczas ładowania panel trzyma wybrany kontekst przez 12 sekund i pozwala anulować. Odłożona zgoda, brak połączenia, brak filmu, problem konfiguracji i przekroczony czas mają oddzielne statusy. Reklamy ładują się po UMP. Po błędzie jedna jednostka ma pięć automatycznych prób ponowienia z przerwami 3, 8, 20, 60 i 120 sekund. Po wyczerpaniu gracz może wznowić próbę po przerwie co najmniej pięciu minut. UMP ma limit czterech kolejnych prób na sesję. Tylko potwierdzenie SDK z bieżącym identyfikatorem żądania uruchamia atomowy zapis nagrody.

Przerywniki wymagają naturalnej przerwy po ukończeniu samouczka, co najmniej 15 minut aktywnej gry, 8 minut od poprzedniego i maksymalnie 4 na godzinę. Zakupy, nagrody i przejścia podczas modernizacji wstrzymują emisję. `remove_ads` wyłącza przerywniki, a opcjonalne filmy zachowują dostępność. [Zasady przerywników AdMob](https://support.google.com/admob/answer/6201362) · [Google Play Ads](https://support.google.com/googleplay/android-developer/answer/9857753)

Sklep pokazuje rzeczywiste lokalne ceny Billing po otrzymaniu katalogu. Przy braku bezpiecznego checkoutu oferta nie ma aktywnej akcji kupna. W zamkniętym AAB Billing i logowanie są wyłączone. Pakiety dla wszystkich 12 dzielnic mogą korzystać z pola `district` katalogu oraz istniejącej ilustracji miejsca. Nowy SKU do sprzedaży wymaga wpisu w Play Console, katalogu aplikacji i weryfikatorze. [Produkty i HTTPS](PLAY_BILLING.md)

Po ręcznym włączeniu lokalnego dziennika zapisywane są zdarzenia wejścia do sklepu i nagród, wyboru oferty, BOOST, startu i wyniku transakcji, emisji, braku filmu oraz potwierdzenia nagrody. Dziennik mieści 128 wpisów i jest czyszczony przy wyłączeniu. Brak wysyłania przez aplikację do zewnętrznej analityki. [Data Safety](PLAY_BETA_DATA_SAFETY.md)
