# Etap 7 · wydanie techniczne 0.8.0

| Wymaganie | Wykonanie i granice weryfikacji |
| --- | --- |
| 1. Jakość wizualna | Zachowano modele źródłowe, kolory, układ, animacje i główne efekty. Wysoki zachowuje bazową rozdzielczość i 2× MSAA. Porównanie pod tym samym kątem znajduje się w galerii. |
| 2. Audyt | Bazę `aec0754` zmierzono w działającym Godocie. Zebrano czasy klatek, wywołania, prymitywy, alokacje, czas wejścia i źródła rozmiaru APK. |
| 3. Grafika 3D | Powtarzalne siatki i fragmenty mapy korzystają z instancjonowania, współdzielonych materiałów i wydzielonych granic frustum. LOD działa według profilu. Geometria ulepszeń materializuje się przy otwarciu odpowiedniego progu. |
| 4. Renderer | Porównano OpenGL Compatibility i Mobile/Vulkan na programowym sterowniku Mesa. Android zachowuje Compatibility. Vulkan wymaga oddzielnych prób GPU na telefonach. |
| 5. Profile | Niski, Średni, Wysoki i Ultra zmieniają skalę, LOD, cienie lub efekty. Automatyka reaguje na RAM i obciążenie z histerezą. Stary ręczny wybór zachowuje się po aktualizacji. |
| 6. Pojazdy | Pula ostatnich modeli, filtrowanie obliczeń kolizji siatką przestrzenną przy dużym ruchu, animacja tylko w poszerzonym kadrze. Próby z 20, 50, 100 i 200 aktywnymi pojazdami. |
| 7. Postacie | Pracownicy i goście zachowują stan obsługi, kolejki i płatności. Poza kadrem zatrzymano animację szkieletu. Niski profil aktualizuje prezentację świata w 30 Hz. |
| 8. Sześć lokalizacji | Wczytywanie w tle z paskiem podróży, jedna aktywna scena i ograniczone wstępne wczytanie modeli. Scena wyjazdu jest zwalniana przed zamontowaniem celu. Zapis pozostaje wspólny, stan lokalizacji rozdzielny. |
| 9. Ekonomia | Prefiksy dokładnych kosztów, wyszukiwanie maksymalnego zakupu, przyrostowy obrót za minutę i aktualizacje geometrii przy zmianie stanu. Zweryfikowano wszystkie 41 biznesów oraz kwoty powyżej int64. |
| 10. BOOST | Próby 5/30 minut, restartów, zmiany zegara, sześciu lokalizacji, powtórzenia sygnału, przerwania i wypłaty offline. Próba Androida z prawdziwym SDK nadal otwarta. |
| 11. Bateria i temperatura | Tryb 30 FPS, mniej cząsteczek, ograniczenie odsłuchu przestrzeni, ograniczony zapis spokojnej gry i pauza 3D po zdarzeniu Androida. Poboru energii ani temperatury telefonu nie zmierzono. |
| 12. Start | Logo i pasek ładowania, paczki modeli asynchronicznie, późniejsze wczytanie sklepu i warstw dźwięku. Podstawowa rozgrywka startuje bez udostępnienia reklam i sieci. |
| 13. Rozmiar | APK telefonów ma około 118 MB dzięki jednemu ABI. Sceny używane dynamicznie pozostają w pakiecie. Eksport pomija trzy modele źródłowe ilustracji i wykluczone materiały deweloperskie. |
| 14. Zapis | Autentyczny profil `0.7.0` i jego kopia przeszły test sześciu lokalizacji, BOOST, uprawnień, ustawień i odzyskania po uszkodzeniu. Podpis pakietu jest zgodny z aktualizacją. Instalacja wymaga urządzenia. |
| 15. SDK | Natywny most utrzymuje zdarzenia pełnoekranowe i wznawia ładowanie reklam na pierwszym planie. Diagnostyka SDK jest dostępna w APK testowym. Płatności i formularz UMP wymagają środowiska Play i urządzenia. |
| 16. Weryfikator | Gotowe pliki systemd i Caddy, oddzielne poświadczenia i kopie SQLite. Przepływ HTTPS sprawdzono na lokalnym serwerze. Publicznego weryfikatora i płatnego hostingu nie uruchomiono. |
| 17. Kompatybilność | Potwierdzono API 36, ARM64 i wyrównanie 16 KiB. Format interfejsu sprawdzono w oknie dla telefonów i tabletu. Telefony różnych klas, rzeczywiste przerwania i rozruch z pamięcią 16 KiB czekają na urządzenie. |
| 18. Obciążenie | Próby cyklicznych podróży, maksymalnie rozwiniętych usług, 200 pojazdów, odtwarzania zapisu i zakupu z odpowiedzią testową. Raport rozróżnia test ciągły silnika, renderowanie i fizyczny Android. |
| 19. FPS | Opcjonalny panel z FPS, czasem, pamięcią, geometrią, pojazdami i załogą. Aktywuje się w ustawieniach wersji testowej. |
| 20. Podpis | `versionCode 8000`, ten sam pakiet i certyfikat testowy. Preset AAB wymaga właściwego klucza upload, identyfikatorów Google i weryfikatora. |
| 21. Porównanie | Tabela i surowe wyniki z Linuksa oraz galeria właściwych widoków 0.7.0 i 0.8.0. Wyniki sprzętowe Androida pozostają niezmierzone. |
| 22. Dostawa | Podpisane APK, zrzuty i film, kod, instrukcje i raporty. Brak konfiguracji produkcyjnej blokuje prawidłowo podpisany AAB oraz test zakupów rzeczywistych. |

[Wydajność](performance-0.8.0.md) · [Rozmiar aplikacji](app-size-0.8.0.md) · [Testy](../TEST_REPORT.md) · [Stabilność](stability-0.8.0.md) · [Galeria](../screenshots/0.8.0/README.md) · [Android](ANDROID_QA.md) · [Wdrożenie weryfikatora](HTTPS_VERIFIER.md)
