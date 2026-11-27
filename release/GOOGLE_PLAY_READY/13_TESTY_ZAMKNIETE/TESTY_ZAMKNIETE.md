# Zamknięty tor od pierwszego wydania do produkcji

Najpierw przygotuj aplikację i kartę zgodnie z [instrukcją główną](../00_START/START_TUTAJ_GOOGLE_PLAY.md). Sprawdź dostępność publicznej polityki, wybierz właściwy klucz upload i podpisz AAB. Play App Signing stosuje własny klucz do APK instalowanych ze sklepu. Gdy telefon ma bezpośrednio instalowane APK podpisane innym certyfikatem, Android może odrzucić aktualizację z Play. Testuj instalację Play na odpowiednim urządzeniu, a zapis użytkownika zabezpiecz przed odinstalowaniem.

## Tor i uczestnicy

1. Otwórz **Testing → Closed testing**. Utwórz tor albo wybierz istniejący. Ustaw kraje zgodne z uczestnikami. Zapisz ich na liście e-mail lub dodaj Google Group. Dodaj kanał zwrotny `kogonowski52@gmail.com` i pliki testów z tego katalogu.
2. Otwórz **Create new release**. Wgraj podpisany AAB, ustaw nazwę wydania i notatki PL oraz EN. Odczytaj ostrzeżenia o certyfikacie, API i kodzie. Zapisz i zatwierdź wysyłkę na tor po akceptacji właściciela. Jeśli pojawia się **Publishing overview**, sprawdź stan weryfikacji.
3. Po udostępnieniu wydania skopiuj link do przystąpienia z karty **Testers** i link do instalacji z toru. Przekaż oba wybranym osobom. Tester loguje się do Play kontem z listy, otwiera opt-in, potwierdza udział i otwiera link instalacji. Uczestnictwo samo w sobie nie zastępuje realnych prób gry.
4. Jeżeli panel konta stosuje zasadę nowych kont osobistych, utrzymuj co najmniej 12 zapisanych testerów przez minimum 14 kolejnych dni. Kontroluj stan na pulpicie. Uczestnicy zachowują członkostwo przy normalnych aktualizacjach toru, jeśli ustawienia toru i lista nadal ich obejmują.
5. Do poprawek buduj wyższy `versionCode` od wykorzystanych. Zachowaj Application ID, certyfikat upload i ten sam tor. W notatce wskaż faktycznie naprawiony błąd. Sprawdź aktualizację na istniejącym zapisie.
6. Po spełnieniu wymogu wybierz w panelu **Apply for production access**. Podaj rzeczywistą liczbę testerów, sposób rekrutacji, zasięg prób, znalezione błędy i reakcje. Zgoda na dostęp produkcyjny i publikacja są osobnymi działaniami właściciela.

## Wiadomość dla testera

> Zapraszam do zamkniętego testu Highway Business Tycoon. Otwórz link opt-in przekazany z Play Console. Zastosuj konto z zaproszenia i wybierz przystąpienie. Następnie otwórz link instalacji z toru. Użyj listy prób i zgłoś wyniki na kogonowski52@gmail.com. W zgłoszeniu podaj model, wersję Androida, kod aplikacji i kroki odtworzenia. Przed publicznym wysłaniem zdjęć usuń z nich prywatne informacje.

Adresy dostarcza konsola dopiero po przyjęciu toru. [Wymogi kont osobistych](https://support.google.com/googleplay/android-developer/answer/14151465) · [Wydania](https://support.google.com/googleplay/android-developer/answer/9859455)
