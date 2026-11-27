# Blokery i potwierdzenia właściciela

| Stan | Czego dotyczy | Rozwiązanie |
| --- | --- | --- |
| Bloker wgrania AAB | Używane środowisko ma dotychczasowy certyfikat APK. Brakuje klucza upload potwierdzonego w Play Console. | Bezpiecznie skonfiguruj istniejący klucz dla środowiska GitHub `play-upload` lub podpisz lokalnie. Jeśli to pierwsza rejestracja i potrzeba nowego klucza, zatwierdź jego utworzenie. [Instrukcja](../01_AAB/RAPORT_WERYFIKACJI.md) |
| Przed wgraniem | `10002` jest wyższy od ostatniego potwierdzonego wydania repozytorium. Maksimum na koncie Play pozostaje nieodczytane. | Porównaj w App bundle explorer. Jeśli potrzeba wyższego kodu, skompiluj nowy AAB. |
| Przed zamkniętym testem | Publiczny URL polityki, prawne dane administratora, docelowe grupy i kraje są do potwierdzenia. Cloud nie mógł odczytać domeny. | Uzupełnij dane, opublikuj dedykowany HTML i sprawdź publiczny HTTPS. Zatwierdź grupę odbiorców i wybierz kraje według faktycznych planów dystrybucji. |
| Przed wysłaniem do przeglądu | Aktualne strony pomocy i selektor tagów były niedostępne z Cloud. | W konsoli sprawdź widoczne terminy, limity, dostępność tagów i komunikaty konta. Raport oddziela pomiary techniczne od tych pól. |
| Do potwierdzenia na torze | Play App Signing, faktyczne formularze UMP, natywne reklamy oraz instalacja i stabilność na urządzeniach. | Testerzy uruchamiają scenariusze z pakietu i uzupełniają raport. |
| Przed aktywacją zakupów | Brak potwierdzonego produkcyjnego weryfikatora HTTPS. Płatności w `closed` są wyłączone. | Osobno wdrożyć serwer, produkty i licencje, przetestować transakcje i dopiero potem aktywować zakup. |

Produkcja, publikacja polityki na serwerze i publikacja filmu na YouTube pozostają odrębnymi działaniami właściciela. Testowe APK jest gotowe do bezpośredniej aktualizacji instalacji z dotychczasowym certyfikatem.
