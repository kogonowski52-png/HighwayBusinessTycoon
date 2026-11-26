# Android · kontrola wersji 0.8.0

## Kompilacja i zgodność pakietu

APK testowy dla telefonów używa `arm64-v8a`, ma `minSdkVersion 24`, `targetSdkVersion 36` i zachowuje certyfikat testowego `0.7.0`. Osobny preset testowy buduje `x86_64`. Preset AAB używa obu ABI 64-bitowych oraz rozdzielania pakietów przez Google Play. Identyfikator pakietu pozostaje `pl.krystiandevelopment.highwaytycoon`. [Podpis](ANDROID_SIGNING.md)

Test archiwum sprawdza wyrównanie ZIP poleceniem `zipalign -c -P 16 4` oraz wyrównanie wszystkich segmentów `PT_LOAD` w bibliotekach `.so`. W APK ARM64 wynosi ono 16 KiB dla `libgodot_android.so` i `libc++_shared.so`. Ten test sprawdza plik. Test rozruchu na jądrze z wielkością strony 16 KiB wykonuje się osobno. Oficjalne repozytorium SDK Google udostępniło metadane API 36 i obrazów 16 KiB. Serwisy dokumentacji Developer Android i centrum pomocy Play zwróciły HTTP 403 z Cloud. Aktualny termin polityki target API trzeba potwierdzić w Play Console przed wysłaniem wydania. [Target API](https://developer.android.com/google/play/requirements/target-sdk) · [Wymóg 64-bit](https://developer.android.com/google/play/requirements/64-bit) · [Strony 16 KiB](https://developer.android.com/guide/practices/page-sizes) · [Oficjalne obrazy SDK](https://dl.google.com/android/repository/sys-img/google_apis_playstore/sys-img2-3.xml)

## Testy rozruchu i cyklu życia na urządzeniu

| Klasa urządzenia | Próba |
| --- | --- |
| 4 GB, ARM64, telefon z węższym ekranem | Automatyczny dobór profilu, Niski, limit 30 FPS, gest wstecz, powroty do aplikacji. |
| 6 GB, ARM64, GPU Mali lub PowerVR | Średni, ruch w Metro, myjnia i efekty, przejście z Wi‑Fi na tryb samolotowy. |
| 8 GB, ARM64, GPU Adreno | Wysoki, pamięć po trzech rundach po sześciu lokalizacjach, przyjęcie nagrody oraz anulowanie reklamy. |
| 12 GB i więcej, ARM64 | Ultra, stabilność renderera i pobór energii przy dłuższej grze, powrót po blokadzie i połączeniu. |
| Tablet 4:3 lub 16:10 | Panel ustawień, przyciski w safe area, przeciąganie, gesty systemowe i skalowanie. |
| Android z aktywnymi stronami 16 KiB | Rozruch, dwukrotna podróż, aktualizacja starej kompilacji z istniejącym zapisem i start natywnych bibliotek. |

Na urządzeniu z kompatybilnym podpisem przygotuj zapis 0.7.0, zbuduj stanowisko, zatrudnij pracownika i aktywuj BOOST. Następnie wykonaj aktualizację, pozostawiając dane aplikacji na urządzeniu.

```bash
adb shell getconf PAGE_SIZE
adb install -r HighwayBusinessTycoon-0.8.0-test.apk
adb shell dumpsys meminfo pl.krystiandevelopment.highwaytycoon
adb shell dumpsys thermalservice
```

W testowym APK otwórz **Ustawienia → Diagnostyka wersji testowej**. Panel FPS pokazuje czasy klatek, obiekty, draw calls, pamięć silnika, pojazdy, załogę, region i profil. Oddzielny ekran pokazuje inicjalizację, zgody, gotowość reklam, potwierdzenia nagród, pozostały BOOST, Billing, produkty i wynik ręcznego zapytania HTTPS. Panel wymaga kompilacji debug i testowego znacznika Androida. Ekran może wywołać normalne pobranie reklamy testowej albo odczyt katalogu. Nagrody nadal zależą od zdarzeń SDK i weryfikatora.

Sprawdź rozgrywkę po naciśnięciu Home, blokadzie, odblokowaniu, symulowanym powiadomieniu o połączeniu, wymuszeniu zamknięcia i utracie sieci. Sprawdź zarówno wyświetlenie, jak i przerwanie filmu. Do pomiaru telefonów zapisz temperaturę otoczenia, model, Android, ABI, typ GPU, profil, czas testu oraz próg temperatury. FPS mierzy panel i Perfetto. Zużycie baterii oraz temperatura wymagają rzeczywistego urządzenia. [Plany prób Play Billing](PLAY_BILLING.md) · [Konfiguracja testowych reklam](MONETIZATION.md)

W Cloud można było zweryfikować podpis, manifest i archiwum oraz przeprowadzić próby kodu obsługi cyklu życia. Nie było dostępnego urządzenia ani KVM dla emulatora x86_64. Oficjalny emulator odrzucił też próbę ARM64 w QEMU2 na hoście x86_64. Dopasowanie interfejsu sprawdzono w oknie Linuksa przy zasymulowanych wcięciach. Fizyczny dotyk, gesty systemowe, blokada urządzenia, temperatura, pobór baterii, emisja AdMob, formularz UMP i transakcje Play pozostają testami urządzeniowymi.
