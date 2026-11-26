# Stabilność · 0.8.0

## Dwie godziny działania silnika

Dwa niezależne procesy Godota na Linuksie ukończyły po 7200 sekund czasu rzeczywistego w trybie headless. Drugi przebieg użył ładowania geometrii usług przy otwieraniu lokali. Skrypt uruchamia normalny węzeł gry, ruch i rozliczenia, ustawia wszystkie 41 usług na maksymalnym poziomie oraz zapełnia stanowiska pracownikami. Otwiera siedem paneli na zmianę, zapisuje stan i używa produkcyjnego przejścia między scenami. Co piąte przejście zamyka i odtwarza aktywną scenę z dysku. Początkowy BOOST działa przez pełny okres, a utrzymanie wypłat sprawdza odczyt rezerwacji i portfeli. Przebieg ciągły sprawdza silnik i zapis. Wydajność renderowania, Android oraz dostawcy reklam mają osobne próby. [Skrypt](../tests/stability_run.gd) · [Dane ciągłe](stability-0.8.0.json)

| Kontrola | 30 minut | 120 minut |
| --- | ---: | ---: |
| Czas silnika użyty przez rozgrywkę, sekundy | 1791 | 7166 |
| Rozliczone wizyty klientów | 237 | 936 |
| Zakończone wyjazdy | 239 | 941 |
| Zmiany lokalizacji | 8 | 32 |
| Ponowne odtworzenia aktywnej sceny | 2 | 8 |
| Otwarcia ekranów | 257 | 1029 |
| Ręczne zapisy wywołane w próbie | 59 | 233 |
| Sekwencja ostatniej kopii | 222 | 868 |

Każdy dwugodzinny przebieg zakończył się wynikiem **33/33**. Najwyższy próbnik pamięci alokatora w drugim przebiegu to 109.8 MiB. Porównania z tej samej lokalizacji różnią się m.in. liczbą aktywnych klientów i lokalnymi zdarzeniami. Próba nie wykazała narastania duplikatów lokalizacji ani błędów w rezerwacjach. [Porównanie wydajności w oknie](performance-0.8.0.md)

## Błędy wykryte podczas weryfikacji

- Wstępne liczenie tras próbowało odczytać pas ciężarowy w regionach obsługujących wyłącznie samochody. Odczyt pozycji przeniesiono do pierwszego korzystającego z niej pojazdu. Próby regionalne i ponowne wejścia zakończyły się bez tego błędu.
- Zamykanie procesu z aktywną ścieżką OGG zgłaszało pozostający uchwyt audio. Przy normalnym zamykaniu gra zapisuje postęp, zatrzymuje odtwarzanie i daje mikserowi czas na zwolnienie uchwytów. Zmiana mapy utrzymuje mikser i przejścia między utworami. Końcowa próba okienna zamknęła się bez ostrzeżenia OGG.
- W profilu odczytanym z 0.7.0 brak automatycznego ustawienia jakości oznacza dotychczasowy wybór ręczny. Weryfikacja porównała normalizację kopii źródłowej przez 0.7.0 oraz jej odczyt w 0.8.0.

## Próby zapisu i cyklu życia

Prawdziwy proces 0.7.0 przygotował zapis wszystkich sześciu lokalizacji, BOOST, wydarzeń, pracowników i wykupionego uprawnienia z kontrolowanych danych. Odczyt w 0.8.0 porównał profile i waluty oraz odzyskał dane po uszkodzeniu pliku głównego i niedokończonej kopii tymczasowej. Duplikat pauzy pominięto, a duplikat wznowienia nie zaliczył dochodu offline drugi raz. Zdarzenia SDK były podawane przez izolowane testy. Android z prawdziwym SDK wymaga osobnego urządzenia. [Wyniki testów](../TEST_REPORT.md) · [Próby Androida](ANDROID_QA.md)

Osobny działający proces gry zatrzymano za pomocą `SIGKILL` po automatycznym przygotowaniu danych i ręcznym zapisie. Sprawdzono sumy kontrolne głównego pliku oraz jego kopii. Oba obejmowały sześć lokalizacji i historię BOOST. Świeży start Godota odczytał ten sam plik bez błędów.

## Powroty do regionów z aktywnym rendererem

W oddzielnej próbie OpenGL wykonano trzy pełne okrążenia po sześciu lokalizacjach po pierwszym powrocie na Stację Północ. W każdym przejściu drzewo miało dokładnie jedną scenę gry. Na każdej próbce powrotnej odnotowano 752 węzły i 931 zasobów. Pamięć alokatora pozostawała w przedziale około 87.27–87.28 MiB. Pamięć procesu z Mesa miała 919.7 MiB przed rundami oraz kolejno 950.1, 930.6 i 948.2 MiB; te wartości nie tworzyły stałego trendu wzrostowego. Licznik pamięci renderera po pierwszej rundzie wynosił 67.7 MiB w kolejnych dwóch próbach. [Dane pomiarowe](performance-0.8.0.json)
