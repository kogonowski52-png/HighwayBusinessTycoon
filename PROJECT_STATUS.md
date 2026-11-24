# Stan projektu

## 0.2.0 · Przebudowa oprawy Stacji Północ

- Ta sama grywalna lokalizacja z nową architekturą, autorskim otoczeniem, czterema porami dnia i kamerą mapy.
- Siedem dopracowanych obiektów w świecie gry. Stacja paliw zachowała obsługę klienta, ekonomię, zapis i pięć poziomów. Każdy zakup dodaje osobny moduł 3D i animację budowy.
- Flota 20 osobnych nadwozi GLB przejeżdża przez teren, z animacją kół i świateł oraz dwoma wariantami lakieru na model.
- Osiem ról używa własnych mundurów, akcesoriów i wspólnego szkieletu z dziewięcioma animacjami. Czynności personelu widać w otoczeniu gry.
- Grywalny dystrybutor ma widoczny wąż i pistolet tankowania, a wypłata uruchamia monety. Myjnia, warsztat i krajobraz mają własne cząsteczki.
- Tryb 30 FPS korzysta z mniejszej skali 3D i lżejszych efektów. Projekt nadal używa Godot Compatibility i działa lokalnie.

## Zakres grywalny i stan walidacji

Przychód i rozwój obejmują stację paliw. Sklep, myjnia, restauracja, warsztat, motel i parking mają modele oraz czynności w świecie, a ich własne transakcje i ulepszenia są w planie rozwoju. Pracownicy widoczni na mapie są postaciami otoczenia. System zatrudniania, automatyzacja i kolejki wielostanowiskowe pozostają oddzielnym etapem.

Zapis z 0.1.0 zachowuje poziom, ustawienia i środki. Materiały sprawdzono w renderze Compatibility i przygotowano APK debug. Pomiar 30 i 60 FPS na fizycznych urządzeniach, test wycięć ekranu i eksport iOS wymagają sprzętu docelowego. Szczegóły są w [raporcie testów](TEST_REPORT.md).

## Kolejny etap

Automatyzacja dystrybutora, obsługa wielu stanowisk, gospodarka sklepu i pomiary GPU na telefonach Android.
