# Stan projektu

## 0.3.2 · Przebudowa geometrii Trasy 17

- Główna stacja ma pięć różniących się konstrukcji. Przełęcz została wybrana po porównaniu z Łukiem i Tarasem w oknie Godota. Otwarty sklep i czynny warsztat mają własne modele wyposażenia. [Galeria i porównanie](screenshots/0.3.2/README.md)
- Ruch i układ stanowisk przeszły testy rozgrywki. Profil utworzony w `7ea8bf9` otwiera się z portfelem, rozbudową, pracownikiem, językiem i trybem oszczędnym. [Raport testów](TEST_REPORT.md)
- GitHub Actions zbudował i opublikował testowy APK Android z tagu `v0.3.2`. Pobrany plik przeszedł weryfikację podpisu, manifestu i sumy kontrolnej. [Pobierz APK](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.3.2/HighwayBusinessTycoon-0.3.2-debug.apk)

## 0.3.1 · Modernizacja wizualna

- Stacja, Trasa 17 i osiem działających usług mają nową oprawę. Pięć progów dachów, wydzielona wiata TIR i animowane elementy oświetlenia są dostępne w uruchomionej grze.
- Kremowy HUD i widok ortograficzny zachowują obsługę w pionie, języki PL i EN oraz tryby 60 i 30 FPS. Zmiany przeszły próby pętli rozgrywki, zapisu i działania paneli. [Raport testów](TEST_REPORT.md)
- Porównanie zrzutów i galeria powstały w Godocie z istniejącej sceny Trasy 17. [Galeria](screenshots/README.md)

## 0.3.0 · Ekonomia i działający kompleks

- Działają stacja paliw, sklep, parking, myjnia, warsztat, restauracja, motel i osobny plac obsługi TIR. Kierowcy wybierają usługi według profilu, wjeżdżają na plac, czekają, zajmują przydzielone stanowisko i wyjeżdżają.
- Osiem usług obsługuje poziomy 1–100, progi pojemności, cztery tryby zakupu i oddzielne stawki. Fizyka ruchu korzysta z rezerwacji, odstępów i odzyskiwania po blokadzie.
- Pracownicy widoczni w świecie wykonują zadania, zyskują doświadczenie i awansują. Pięć kart menedżerów daje osobne efekty. Cele, osiągnięcia i rotujące wydarzenia pozwalają rozwijać kompleks za waluty zdobywane w grze.
- Dochód offline, atomowy zapis i odzyskiwanie obsługują istniejące profile. Opcjonalny moduł reklamowy działa w wariancie eksportu Android z odpowiednią konfiguracją. Podstawowy APK debug nadal działa offline.
- APK debug 0.3.0 został zbudowany z tagu `v0.3.0` przez GitHub Actions i udostępniony jako wydanie testowe. [Pobierz APK](https://github.com/kogonowski52-png/HighwayBusinessTycoon/releases/download/v0.3.0/HighwayBusinessTycoon-0.3.0-debug.apk)

Fizyczne testy Androida, pomiary wydajności i wyświetlenie reklamy z docelową konfiguracją wymagają urządzenia. Projekt rozgrywa się w kompleksie Trasy 17. Kolejne lokalizacje i publikacja sklepowa są w planie.

[Raport testów](TEST_REPORT.md) · [Symulacja ekonomii](docs/balance-0.3.0.md)

## 0.2.0 · Przebudowa oprawy Stacji Północ

- Ta sama grywalna lokalizacja z nową architekturą, autorskim otoczeniem, czterema porami dnia i kamerą mapy.
- Siedem dopracowanych obiektów w świecie gry. Stacja paliw zachowała obsługę klienta, ekonomię, zapis i pięć poziomów. Każdy zakup dodaje osobny moduł 3D i animację budowy.
- Flota 20 osobnych nadwozi GLB przejeżdża przez teren, z animacją kół i świateł oraz dwoma wariantami lakieru na model.
- Osiem ról używa własnych mundurów, akcesoriów i wspólnego szkieletu z dziewięcioma animacjami. Czynności personelu widać w otoczeniu gry.
- Grywalny dystrybutor ma widoczny wąż i pistolet tankowania, a wypłata uruchamia monety. Myjnia, warsztat i krajobraz mają własne cząsteczki.
- Tryb 30 FPS korzysta z mniejszej skali 3D i lżejszych efektów. Projekt nadal używa Godot Compatibility i działa lokalnie.

### Ówczesny zakres

Przychód i rozwój obejmują stację paliw. Sklep, myjnia, restauracja, warsztat, motel i parking mają modele oraz czynności w świecie, a ich własne transakcje i ulepszenia są w planie rozwoju. Pracownicy widoczni na mapie są postaciami otoczenia. System zatrudniania, automatyzacja i kolejki wielostanowiskowe pozostają oddzielnym etapem.

Zapis z 0.1.0 zachowuje poziom, ustawienia i środki. Materiały sprawdzono w renderze Compatibility i przygotowano APK debug. Pomiar 30 i 60 FPS na fizycznych urządzeniach, test wycięć ekranu i eksport iOS wymagają sprzętu docelowego. Szczegóły są w [raporcie testów](TEST_REPORT.md).
