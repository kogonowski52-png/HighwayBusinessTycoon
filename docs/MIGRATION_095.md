# Migracja Androida 9004 → 9005

Profil próbny powstał podczas uruchomienia oryginalnej wersji 0.9.4 z commita d76e6a4 i tagu v0.9.4-rc.1. Scenariusz otworzył dwanaście regionów, kupił i rozbudował usługi, zatrudnił pracowników oraz zachował diamenty, kartę menedżera, historię i stan BOOST. Zapis rzeczywiście wykonał kod 9004. Zapis źródłowy przeszedł 13/13 asercji.

Na 0.9.5 sprawdzono równość obsługiwanych danych każdego regionu, BOOST, uprawnienia, ustawień i księgi. Nowe systemy rozpoczynają z pustą flotą i stanem regionalnym. Po zapisaniu postępu w nowej wersji skrypt uszkodził plik główny wraz z plikiem tymczasowym i zweryfikował odczyt kopii zapasowej. Cały odczyt 7/7.

Identyfikator aplikacji to `pl.krystiandevelopment.highwaytycoon`. Nowe pola zapisu mają wartości domyślne dla profili z wersji 9004. Próba na fizycznym Androidzie obejmuje osobno instalację w miejscu i rozruch zapisu telefonu. [Skrypt](../tests/migration_095.gd) · [Podpis](ANDROID_SIGNING.md#testowy-apk-095)
