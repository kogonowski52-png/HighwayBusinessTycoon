# Bezpieczeństwo zakupów i kompilacji · 0.9.0 RC

Weryfikator potwierdza jednorazowe produkty Android Publisher, przypisanie do pseudonimu konta Google, SKU, ilość i stan transakcji. Zapisuje unikalny hash tokena przed próbą potwierdzenia lub konsumpcji Google. Wydanie RC zwraca samą nagrodę oraz trwałe uprawnienia dopiero po finalizacji. SQLite zabezpiecza równoległe próby za pomocą czasowej rezerwacji finalizacji. Powtórzenie po utraconej odpowiedzi odczytuje stan u Google. Transakcja unieważniona jest wyłączona z kanału dostawy, także gdy zwrot dotrze przed callbackiem Billing.

Wersja klienta usuwa błąd terminalnego tokena blokującego kolejne zamówienia. Gdy odpowiedź może się zmienić, kolejka odkłada ponowienie i zachowuje token. Zapis nieobsługiwanej nowszej wersji przechodzi w tryb tylko do odczytu. Klient chroni zarówno uruchomienie zakupu, jak i zapis nagrody w tym stanie. Niepowiązany lub powtórzony callback reklamy nie przyznaje dodatkowej nagrody. Przerwanie reklamy kończy się czytelnym komunikatem. [Konfiguracja płatności](PLAY_BILLING.md)

| Próba | Wynik |
| --- | --- |
| Python i SQLite | 15/15. Konto i nonce, wszystkie 19 SKU, oczekiwanie, odmowa i cofnięcie uprawnienia, błędy przed i po finalizacji, ponowienia, szyfrowana kolejka oraz kopia bazy. |
| Granica klienta Godot | 86/86. Obejmuje wszystkie SKU, powtórzenia, konta, pełny katalog uprawnień, anulowanie reklamy, zapis, limity oraz postęp BOOST. Kontrolowane dane SDK i weryfikatora. |
| Caddy i WSGI na Linuksie | Lokalny certyfikat z zaufanym CA dla próby, `/health` 200, brak sesji 401, nieudostępniona trasa 404, nadmiarowa treść 400. Pełna próba HTTP w trybie sandbox sprawdziła sesję, jednokrotny nonce, dostawę zakupu i synchronizację przy powtórzeniu. |
| Testowy APK | Stabilny certyfikat z 0.7.0 i 0.8.0, `allowBackup=false`, `usesCleartextTraffic=false`, utrzymany Application ID. Google Ads ma oficjalne identyfikatory testowe. |
| Preset Android Play | Silnik Godot release na Linuksie uruchomił ekran startowy z PCK i zapisał profil Stacji Północ. Pakiet zasobów wyklucza raporty, marketing, dokumenty robocze, testy i skrypt panelu deweloperskiego. Produkcyjny eksport wymaga publicznego parametru prywatności, gotowego HTTPS w trybie produkcyjnym i osobnego klucza upload. |

Pozostają testy zwrotów i cyklu życiowego na fizycznym Androidzie oraz ustawienie działającego usługowego konta Google, uprawnień i hostingu. Serwer kontroluje zakupy, a waluty gry są przechowywane lokalnie poza serwerem. Już wydanych środków nie odzyskuje się automatycznie po cofnięciu uprawnienia. Reinstalacja przywraca trwałe uprawnienia z weryfikatora, a zużywalne środki wymagają tego samego identyfikatora zapisu. Właściciel powinien potwierdzić publiczne procedury retencji i usuwania danych. [Wdrożenie HTTPS](HTTPS_VERIFIER.md) · [Dane](DATA_SAFETY.md)
