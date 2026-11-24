# Stan projektu

## Etap 1 · Stacja Północ

- Grywalna scena 3D z kamerą ortograficzną, krajobrazem, ruchem ulicznym, jedną usługą oraz widocznym klientem tankującym przy aucie.
- Przychody, pięć poziomów dystrybutora i natychmiastowa aktualizacja geometrii stacji po zakupie.
- Zapis lokalny z kopią poprzedniego zapisu, polski i angielski oraz wybór limitu 30 lub 60 FPS.
- Pionowy HUD ze skalowaniem dla telefonu i tabletu. Główna pętla działa lokalnie bez usług sieciowych.
- Gotowy do dalszej rozbudowy podział kodu na grę, ekonomię, zapis, budynki, klientów, pojazdy, ruch oraz HUD. Android ma własny preset oraz wyeksportowany i zweryfikowany pakiet debug 0.1.0.

## Rozwiązania etapu do rozwinięcia

Ruch używa zdefiniowanych punktów trasy, a jedno stanowisko obsługuje jednego klienta naraz. Animacja klienta obejmuje postawę i ruch ręki obok pojazdu. Podstawowe modele wariantów pojazdów oraz stacji są proceduralne. Fizyczne urządzenia, obciążenie GPU, obszary wycięcia ekranu i wersja iOS wymagają osobnej walidacji. Stan produkcyjny, podpisanie dystrybucyjne i wydajność 60 FPS nie zostały potwierdzone.

## Kolejny etap

Pracownicy i automatyzacja dystrybutora, obsługa wielu stanowisk i kolejki, pierwszy sklep oraz kalibracja ekonomii i wydajności na urządzeniu Android.
