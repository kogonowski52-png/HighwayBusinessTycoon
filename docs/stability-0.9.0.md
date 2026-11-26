# Stabilność i odtwarzanie danych · 0.9.0 RC

Próby używały własnych zapisywalnych plików tymczasowych. Rzeczywiste uruchomienia 0.7.0 (`aec0754`) i 0.8.0 (`b182d4f`) zapisały po sześć lokalizacji. Kandydat porównał odtworzone dane do migawki z oryginalnej gry. Waluty sięgały rozmiaru większego niż 64 bity. Oprócz budynków i personelu uwzględniono karty, kolekcje, kontrakty, konfigurację, BOOST, aktywną lokalizację i stan zakupu.

Kandydat odtworzył osobno obie wersje. Test nadpisał plik główny i plik oczekujący niekompletnym JSON-em. Kopia odzyskała stan i została poprawnie zapisana ponownie. W dodatkowej próbie `SIGKILL` w czasie aktywnej gry zwrócił kod 137. Sumy kontrolne obu kopii pasowały. Kolejny proces Godota wczytał sześć lokalizacji.

## Próba ciągłego ruchu i paneli

Kampania została przygotowana z rozwiniętymi biznesami, poziomem 100, pracownikami, BOOST i wydarzeniem. Scenariusz symulował obciążenie zegarem ściennym na Linuksie bez renderowania. Pierwsza próba 900 s z przejściami co 45 s osiągnęła 107 rozliczonych wizyt i 92 wyjazdy. Próg ponad 100 wyjazdów pozostał niespełniony. Częsta zmiana sceny kończy wizyty w bieżącym świecie po ostatnim naliczonym stanie. Oddzielne testy tras przez 25 minut symulowanego ruchu potwierdziły rozliczenia i odpływ klientów bez zakleszczeń w czterech nowszych regionach. [Przebieg co 45 s](qa-0.9.0/endurance-travel-45s.json)

Druga próba trwała 900 s z przejściami co 90 s. Zaliczyła 18/18 sprawdzeń. Rozliczono 118 wizyt i 110 wyjazdów. Zarejestrowano 8 zmian map, 2 restarty sceny, 29 wymuszonych zapisów i 129 otwarć panelu. [Przebieg co 90 s](qa-0.9.0/endurance-travel-90s.json)

## Instalacje Androida

Metadane APK wskazują wymagany pakiet, identyczny certyfikat testowy i rosnący kod. Właściciel nadal musi odtworzyć aktualizację przez instalację testowego APK na fizycznym urządzeniu z zachowaniem danych. Androidowe testy przerwania zasilania, przejścia do tła i ubicia procesu uzupełniają test `SIGKILL` na Linuksie. [Zgodność Androida](PLAY_CONSOLE_RC.md)
