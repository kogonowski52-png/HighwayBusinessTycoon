# Inne formularze Google Play

Wypełniaj pozycje faktycznie pokazane dla konta w **App content**. Poniższe odpowiedzi dotyczą zamkniętego `10002`. Raport manifestu zawiera ostateczne uprawnienia tego pliku.

| Formularz | Odpowiedź do konfiguracji | Podstawa |
| --- | --- | --- |
| Financial features | Aplikacja nie oferuje funkcji finansowych. | Zakupy walutą gry, rachunki kampanii i wirtualne zyski są częścią symulacji. Brak kredytów, przelewów, rachunków bankowych i wypłacania gotówki. |
| Health apps | Brak funkcji zdrowotnych. | Gra nie rejestruje zdrowia, aktywności fizycznej ani danych medycznych. |
| Government apps | Nie jest aplikacją rządową. | Zwykła gra od Krystian Development. Brak usług publicznych. |
| News and magazines | Nie. | Gra nie prowadzi publikacji prasowej ani serwisu informacyjnego. |
| Photo and video permissions, Storage | Brak aplikacyjnego dostępu do zdjęć i użytkowych plików współdzielonych. | Stan gry zapisuje się w prywatnym obszarze Androida. Uprawnienia zdjęć, kamery i pamięci współdzielonej zweryfikowano w AAB. |
| Sensitive permissions | Brak dostępu gry do SMS, kontaktów, kamery, mikrofonu i lokalizacji precyzyjnej. O identyfikatorze reklamowym odpowiedz osobno. | Sieć, wibracje oraz uprawnienia bibliotek są w raporcie. Zależności deklarują m.in. biometrię. Zamknięty wariant nie wywołuje logowania zakupowego. |
| Foreground services | Gra nie uruchamia własnej usługi typu foreground. Jeśli konsola pyta w związku ze scalonym manifestem, sprawdź komponent `androidx.work.impl.foreground.SystemForegroundService` z zależności i wskaż, że istnieje techniczna deklaracja biblioteki. | W AAB jest ogólne `android.permission.FOREGROUND_SERVICE`. Brak własnej usługi i zadeklarowanego typu FGS aplikacji. Treści stosuj zgodnie z polem widocznym na tym koncie. |
| Account deletion | W `closed` nie ma konta gry do usuwania. Lokalne dane można usunąć w Androidzie. | Zakupy i logowanie w tym trybie są wyłączone. Po aktywacji konta zakupów uzupełnij procedurę usunięcia zgodnie z wymaganiami. |
| In-app purchases | Płatności nieaktywne w bieżącym zamkniętym wydaniu. Nie publikuj ofert płatnych na tej ścieżce. | Play Billing 9.1.0 pozostaje w pakiecie. Bezpieczne uruchomienie wymaga oddzielnej konfiguracji i licencji. |
| Play App Signing i eksport | Właściciel odpowiada za publiczne deklaracje konta i zgodę eksportową. | Weryfikowany pakiet ma identyfikator `pl.krystiandevelopment.highwaytycoon`. Wartość SHA klucza upload ma pochodzić z własnego wpisu Play. |
| Kraje i dostępność | Dodatkowo potwierdź faktyczne kraje toru. Wybierz uczestników z obszarów wskazanych w zaproszeniach. | Kampania nie ogranicza regionu urządzenia, jednak tor Play i reklamy mogą zależeć od kraju. |

[Manifest i uprawnienia](../01_AAB/RAPORT_WERYFIKACJI.md) · [Centrum zasad Google Play](https://play.google.com/about/developer-content-policy/)
