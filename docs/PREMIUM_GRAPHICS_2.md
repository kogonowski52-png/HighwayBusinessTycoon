# Premium Graphics 2.0 · Highway Business Tycoon 0.9.3

Punktem odniesienia jest wydanie 0.9.2, commit dad4e74 i Android 9002. Przed zmianami wyrenderowano Stację Północ w Godocie 4.7.2. Audyt zdjęć i geometrii pokazał, że z normalnego kadru część wyposażenia ginęła pod dachami, bryły warsztatu i myjni miały podobny profil, a obrzeża mapy wyglądały jak jedna jasna płaszczyzna. W zbliżeniu widać było też za mało różnic w sylwetkach głów postaci i w wykończeniu bocznych części samochodów. Najpierw sprawdzono wersję wzorcową Stacji Północ, a potem zaadaptowano obróbkę profili dachów i wyposażenia do pozostałych regionów. Inspiracja dotyczyła czytelności i skali makiety. Wszystkie modele i znaki są własne. [Galeria i nagranie](../screenshots/0.9.3/README.md)

| Obszar | Wykonana zmiana |
| --- | --- |
| Stacja Północ | Pięć zadaszeń z odrębną geometrią. Poziomy przechodzą od wyeksploatowanej blachy i ujścia rynny, przez zabudowę techniczną i świetliki, do szerokich podpór i kilku różnych brył dachowych. Doszły masywniejszy pylon cenowy i detale dystrybutorów. |
| Sklep Północ | Nad witryną są nowa markiza i naświetle. Przez szyby widać chłodziarkę z rzędami opakowań, dodatkowy kontuar, ladę chłodniczą, istniejące półki i stanowisko kasowe. |
| Myjnia Północ | Wzmocniona brama, obudowy sterowania, przęsła suszarek, dysze i regał płynów. Szczotki obracają się i dojeżdżają do auta podczas zlecenia, obok istniejącej wody, piany i pary. |
| Warsztat Północ | Nowa rama bramy, dach z naświetlem, kompresor, opony, klucze i wieszak. Iskry są powiązane z postępem realnej naprawy. |
| Restauracja Północ | Pasiasta markiza i klosze, nowy kontuar oraz lada przy restauracyjnym wnętrzu. Na poziomach rozwoju przy tych czterech usługach dochodzą różne zaplecza, od niskich szaf po zabudowane punkty z pergolą i podświetleniem. |
| Pozostała Stacja Północ | Region zyskał detale motelu, parkingu, wiaty ciężarówek, wulkanizacji, punktu EV i zaplecza parkingu ciężarowego. |
| Desert Highway | Detale w stylu Art Deco, barwne żaluzje zadaszenia Copper Mile, markizy kawiarni i motelu, bramy Red Mesa i odrębne wyposażenie punktu ładowania, parkingów i usług sanitarnych. |
| Green Valley | Drewniane i miedziane osłony wejść, markizy wiejskich sklepów i restauracji, bramy warsztatu i nowa warstwowa korona drzewa. |
| Alpine Pass | Osłony z drewnianymi przęsłami, odrębna sylwetka motelu i parkingu, świerki z oddzielnie modelowanymi czapami śniegu i asymetryczne, wygładzone granie z jaśniejszą pokrywą śnieżną. |
| Ocean Coast | Tkaniny w kolorze koralu, pergola VIP, osobne portale myjni, modelowane unerwienie i szerokie listki widoczne z góry. |
| Metro City | Świetliki hali logistycznej i magazynu, wykończenie doków i oświetlenie fasad, nowe profile salonu, centrum handlowego oraz wiat EV i TIR. |
| Flota | Poprawione profile progów, powierzchnia lakieru, felgi i materiały szyb. Dodano Cove, Sable, Brook, Ridgeback, Courier, Sundown, Arrow, Solstice, Switchback i Petrel. Nowe rodziny nadwozi obejmują kamper i cysternę. Zachowano oddzielne obiekty lamp i koła, które obracają się według przebytej drogi. |
| Pracownicy | Indywidualne profile żuchwy i kurtki, dodatkowe detale identyfikatorów, narzędzi i ubrań, nowe fryzury trzech ról. Przejścia chodzenia, biegu i przenoszenia nadal korzystają ze wspólnego szkieletu. |
| Nawierzchnia i roślinność | Na Północy grupy koron i krzewów zamykają kadr wokół placu. W regionalnych materiałach połączono kruszywo, ciemne ślady i zmienny odcień w jednej współdzielonej teksturze z mipmapami. Zachowano profile wiatru i instancjonowanie. |
| Oświetlenie i interfejs | Pochmurny wariant zmienia światło wraz ze stanem pogody. Zredukowano zamglenie deszczu i śniegu. Ikony stacji, gotówki i zespołu oraz etapów są renderami modeli. Wszystkie 41 kart biznesów powstało ponownie z GLB w silniku. Atlas korzysta z aktualnych modeli. |

## Warstwa techniczna

Modele przechodzą przez Blendera 4.3.2 w trybie bez okna. Powierzchnie konstrukcyjne mają profile z zaokrągleniami oraz gładkie normalne. Okluzja jest zapisana w kolorach wierzchołków i działa w Compatibility. Wykończenia są grupowane w powierzchnie GLB. Teren korzysta ze współdzielonej tekstury kruszywa i rzutowania współrzędnymi świata. Import tworzy LOD oraz oddzielne siatki cieni. Regionalne instancje drzew są dzielone na grupy o boku 16 m, więc renderer może je pomijać w mniejszych porcjach poza kadrem. Ultra ma skalę renderu 3D 1,10, MSAA 4× i cztery kaskady cieni w konfiguracji Godota 4.7.2. [Procedura uruchomienia](../README.md) · [Pomiary](PERFORMANCE_093.md) · [Inwentaryzacja geometrii](qa-0.9.3/geometry.json)

Zmieniono 114 plików GLB i dodano 27. Poniższe liczby pochodzą z indeksów modeli przed automatycznym LOD. Wyniki renderera liczą się oddzielnie, ponieważ uwzględniają instancje, kamerę i wybrany profil grafiki.

| Model | Trójkąty 0.9.2 | Trójkąty 0.9.3 |
| --- | ---: | ---: |
| Zadaszenie ostatniego etapu Północy | 6 288 | 8 810 |
| Sklep | 35 548 | 42 884 |
| Myjnia bez ruchomych szczotek | 13 472 | 16 194 |
| Warsztat | 13 544 | 18 006 |
| Samochód Sprint | 6 530 | 7 222 |
| Ciężarówka Cargo | 14 090 | 15 062 |
| Mechanik | 8 882 | 9 808 |
| Centrum logistyczne Metro | 12 416 | 18 022 |
| Palma Ocean Coast | 877 | 1 954 |

Normalny kadr, sterowanie dotykowe, trasy i reguły gospodarki pochodzą z 0.9.2. Zadaszenia, meble i dekoracje działają w warstwie wizualnej. Otwieranie biznesów, zakup poziomów i system rozliczeń wywołują ich istniejące mechanizmy. Zmiana pogody dodaje zapisany wybór graficzny. Starsze ustawienia pozostają odczytywane.

Generatory podstawowe znajdują się w `tools/art/generate.py`. `tools/art/regional_atlas.py` generuje fronty, roślinność i formy terenu czterech regionów. `tools/art/desert_diorama.py -- --facades-only` odtwarza zaktualizowane modele Desert Highway. Po imporcie skrypt `tools/art/render_business_cards.gd` odtwarza w oknie Godota ilustracje Rozbudowy wraz z granicami modeli. [Źródła generatorów](../tools/art)

## Zakres dalszych szlifów

Cztery wnętrza na Północy są częściowymi scenografiami widocznymi przez witryny i bramy. Wnętrza usług regionalnych mają przede wszystkim opracowane witryny, dachy i fronty. Część rozbudów poza czterema biznesami wzorcowymi nadal rozwija się istniejącymi modułami. Nie zmieniano całego zestawu animacji postaci ani wszystkich ilustracji sklepu wprowadzonych w 0.9.2. Pomiary na Mali, Adreno, ergonomia na telefonie i emisja reklam z SDK wymagają próby na urządzeniu. [Raport testów](../TEST_REPORT.md)
