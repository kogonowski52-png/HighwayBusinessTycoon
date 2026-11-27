# Identyfikator reklamowy

W **App content → Advertising ID** wybierz **Tak**. W scalonym manifeście jest `com.google.android.gms.permission.AD_ID`. Są także uprawnienia usług reklamowych Androida wniesione przez zależności. Dowodem jest manifest rzeczywistego AAB. Kod gry nie odczytuje identyfikatora bezpośrednio. Po UMP aktywna biblioteka Google Mobile Ads 25.5.0 może go używać, gdy jest dostępny.

| Pole celu | Odpowiedź dla zachowania SDK |
| --- | --- |
| Reklama lub marketing | Tak. Emisja i pomiar reklam. |
| Analityka | Tak w zakresie pomiaru działania reklam przez SDK. Dziennik gry nadal jest lokalny. |
| Zapobieganie oszustwom, bezpieczeństwo i zgodność | Tak w zakresie ochrony przed nadużyciami reklamowymi opisanej przez Google. |
| Zarządzanie kontem, komunikacja dewelopera | Nie dla tego identyfikatora. W grze `closed` brak konta wydawcy. |
| Personalizacja | Zależna od konfiguracji UMP, regionu i tego, na jakie reklamy pozwala bieżący profil. Nie potwierdzono rzeczywistej emisji na Androidzie. Sprawdź deklarację SDK i ustawienia konta przy przejściu do produkcji. |

Jeżeli inny tor zmienia zestaw SDK albo cele, zaktualizuj deklarację dla wszystkich objętych wersji. [Raport zgłoszeń manifestu](../01_AAB/RAPORT_WERYFIKACJI.md) · [Identyfikator reklamowy Google](https://support.google.com/googleplay/android-developer/answer/6048248) · [Google Mobile Ads i Data Safety](https://developers.google.com/admob/android/privacy/play-data-disclosure)
