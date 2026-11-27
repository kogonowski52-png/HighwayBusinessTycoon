# AdMob · jednostki i konfiguracja

W tym wydaniu skorzystaj z rekomendowanego trybu zamkniętego `closed`. Reklamy korzystają z testowego App ID i testowych jednostek Google. To umożliwia próby emisji bez kierowania rzeczywistego ruchu reklamowego na produkcyjne jednostki.

| Pozycja | Typ w AdMob | Zmienna eksportu produkcyjnego | Nazwa w manifeście |
| --- | --- | --- | --- |
| Aplikacja Highway Business Tycoon | Android App ID | `HBT_ADMOB_APP_ID` | `com.google.android.gms.ads.APPLICATION_ID` |
| Boost ×2 | Rewarded | `HBT_REWARDED_BOOST_ID` | `highwaytycoon.rewarded_boost` |
| Podwojenie dochodu offline | Rewarded | `HBT_REWARDED_OFFLINE_ID` | `highwaytycoon.rewarded_offline` |
| Darmowe diamenty | Rewarded | `HBT_REWARDED_GEMS_ID` | `highwaytycoon.rewarded_gems` |
| Pozostałe premie | Rewarded | `HBT_REWARDED_BONUS_ID` | `highwaytycoon.rewarded_bonus` |
| Przerywnik w naturalnej przerwie | Interstitial | `HBT_INTERSTITIAL_ID` | `highwaytycoon.interstitial` |

1. W AdMob wybierz **Apps → Add app → Android** i upewnij się, że aplikacja jest właściwie powiązana z pakietem `pl.krystiandevelopment.highwaytycoon` po jego dostępności do powiązania. Zapisz własny App ID. Dodaj cztery miejsca nagradzane oraz jeden przerywnik.
2. W **Privacy & messaging** przygotuj wymagane komunikaty. Porównaj konfigurację z deklarowanymi krajami i grupami odbiorców. UMP powinien móc wyświetlić i ponownie otworzyć właściwy formularz. Sprawdź realne zachowanie na zatwierdzonym urządzeniu testowym.
3. Wprowadź własne identyfikatory w parametrach środowiskowych eksportu. Wtyczka `addons/highway_rewarded/plugin.gd` wpisuje je do manifestu. W trybie `closed` importer stosuje wyłącznie testowy `ca-app-pub-3940256099942544~3347511713`, nagradzany `/5224354917` i przerywnik `/1033173712` z tego samego przykładowego konta Google. `HBT_INTERSTITIALS=off` pozwala zrezygnować z wpisu przerywnika przy ponownym eksporcie.
4. Po wdrożeniu witryny ustaw prawdziwy `HBT_PRIVACY_URL`. Przed przejściem na produkcyjne jednostki sprawdź podpis, zasady emisji i zaktualizuj odpowiedzi w konsoli. Wymagania trybu `production` sprawdza `tools/android/build-monetization.sh`. Funkcje finansowe pozostają blokowane do wdrożenia odpowiedniego weryfikatora.

[Deklaracja reklam](../11_FORMULARZE_GOOGLE_PLAY/REKLAMY.md) · [Identyfikator reklamowy](../11_FORMULARZE_GOOGLE_PLAY/ADVERTISING_ID.md) · [Reklamy testowe Google](https://developers.google.com/admob/android/test-ads)
