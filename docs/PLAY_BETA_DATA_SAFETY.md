# Data Safety · zamknięty test beta.1

Formularz zależy od wszystkich wersji aktywnie dystrybuowanych w Google Play dla tej aplikacji. Poniżej konfiguracja kandydata `10001` z testowym Google Mobile Ads 25.5.0, UMP 4.0.0, Billing 9.1.0 i wyłączonym checkoutem. Przed przesłaniem porównaj ją z wykazem aktualnie aktywnych torów i oświadczeniami SDK. [Google Mobile Ads i Data Safety](https://developers.google.com/admob/android/privacy/play-data-disclosure) · [Pomoc Google Play](https://support.google.com/googleplay/android-developer/answer/10787469)

| Obszar | Dane i sposób użycia |
| --- | --- |
| Postęp i ustawienia | Lokalne dane gry, zapis i kopia. Brak konta gracza w zamkniętej konfiguracji. Dziennik zdarzeń jest wyłączony domyślnie, mieści do 128 rekordów i pozostaje lokalny. |
| Reklamy i zgody | UMP sprawdza wymagane preferencje. SDK reklam może przetwarzać adres IP, przybliżoną lokalizację wywnioskowaną z adresu IP, identyfikatory urządzenia lub aplikacji, interakcje z reklamami, dane diagnostyczne i dane zapobiegania nadużyciom. Dotyczy również wersji z testowymi jednostkami. |
| Identyfikator reklamowy | Manifest zawiera uprawnienie `com.google.android.gms.permission.AD_ID` z zależności. W deklaracji Play odzwierciedl wykorzystanie identyfikatora przez SDK reklam oraz jego cele według aktualnej instrukcji Google. |
| Dostęp do lokalizacji | W manifeście brak żądania uprawnień do lokalizacji. Adres IP może ujawnić przybliżoną lokalizację niezależnie od uprawnień telefonu. |
| Zakupy i identyfikacja | Biblioteki Billing i Credential Manager są obecne. W tej konfiguracji klient nie otwiera płatności ani logowania i nie wysyła tokenów do weryfikatora. Tor z aktywnym backendem wymaga aktualizacji polityki oraz deklaracji dla transakcji i powiązania konta. |
| Szyfrowanie i usunięcie | Pakiet blokuje nieszyfrowany HTTP. Użytkownik usuwa dane lokalne w ustawieniach Androida. Wybory reklamowe można zmieniać w ustawieniach gry, gdy UMP udostępnia formularz. |

W **App content** zadeklaruj obecność reklam, sprawdź klasyfikację treści, grupę odbiorców i wymagania konta. Opublikuj publiczny adres HTTPS polityki z prawdziwymi danymi administratora i kontaktem. Dane o zakupach opisz zgodnie z instrukcją weryfikatora dopiero dla dystrybuowanego toru, na którym zakup działa. [Szablon prywatności beta PL i EN](../release/play-beta/privacy.html) · [Aktywacja płatności](PLAY_BILLING.md)
