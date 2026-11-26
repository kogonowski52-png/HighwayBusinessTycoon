# Wdrożenie weryfikatora zakupów przez HTTPS

Wersja 0.9.0 zawiera konfigurację dla pojedynczego serwera Debian lub Ubuntu z systemd, Caddy 2.10+, Pythonem 3.11+ i SQLite w trybie WAL. Backend udostępnia wyłącznie `GET /health` oraz cztery trasy weryfikacji. SQLite zapisuje paragony z unikalnym hashem tokena, a zadania w tle ponawiają finalizację i uwzględniają zwroty. Konto usługi Play, domena i działający adres produkcyjny pozostają do skonfigurowania przez właściciela. [Kod wdrożenia](../backend/play/deploy/) · [Produkty i zabezpieczenia](PLAY_BILLING.md)

## Wymagania i orientacyjny koszt

| Zasób | Konfiguracja | Orientacyjny koszt |
| --- | --- | --- |
| VPS | 1–2 vCPU, 1–2 GiB RAM, trwały dysk 10 GiB, IPv4 lub publiczne IPv6 z poprawnym DNS | około 20–50 zł miesięcznie zależnie od hostingu i regionu |
| Domena | Rekord A/AAAA dla subdomeny, np. `billing.example.net` | zazwyczaj 40–150 zł rocznie za nową domenę lub 0 zł za subdomenę z posiadanej |
| Kopia poza serwerem | Zaszyfrowane kopie bazy i oddzielna kopia sekretu konta | w ramach istniejącego sejfu lub koszt jego dostawcy |
| TLS | Caddy i automatyczny certyfikat ACME | 0 zł za certyfikat |

Kwoty służą do planowania. Obciążenie zależy od liczby zakupów i okien ponowień. Najpierw uruchom osobną domenę oraz bazę w trybie `HBT_PLAY_TEST=1`. [Instrukcja rejestracji w Play](PLAY_BILLING.md)

## Instalacja

1. W Play Console i Google Cloud skonfiguruj pakiet `pl.krystiandevelopment.highwaytycoon`, OAuth Web Client ID i tożsamość z dostępem do zamówień tej aplikacji. Użyj niezależnej tożsamości do testów. W firewallu otwórz 80/443 dla Caddy i ogranicz dostęp administracyjny SSH do swoich operatorów. Gunicorn nasłuchuje na `127.0.0.1:8074`.
2. Na serwerze zainstaluj `python3-venv` i Caddy, utwórz konto systemowe `hbt-play` z wyłączonym logowaniem. Skopiuj z zaufanego checkoutu `backend/play/requirements.txt`, `service.py` i `backup.py` do `/opt/hbt-play`. Kod i środowisko Pythona mogą pozostać tylko do odczytu dla procesu usługi.
3. Katalog `/etc/hbt-play` pozostaw przypisany do `root` z prawami `0700`. Zainstaluj `deploy/verifier.env.example` jako `/etc/hbt-play/verifier.env` z prawami `0600` i wpisz właściwy `HBT_GOOGLE_CLIENT_ID`. Umieść JSON konta usługi jako `/etc/hbt-play/publisher.json`. Zapisz co najmniej 32 losowe bajty jako `/etc/hbt-play/account.secret`. Pliki poświadczeń mają prawa `0600`, a systemd wczytuje kopie do prywatnego katalogu poświadczeń usługi. Zachowaj sekret konta w oddzielnym sejfie. Jego zmiana zmieni powiązania już zapisanych zakupów.
4. Zainstaluj trzy pliki systemd z `backend/play/deploy/`. Skonfiguruj Caddy według dostarczonego `Caddyfile`. Możesz zastąpić `{$HBT_HOST}` własną nazwą DNS bezpośrednio w pliku. Caddy uzyska certyfikat po poprawnym skierowaniu DNS i dostępie do portów 80/443. Pozostaw szczegółowe logowanie dostępu wyłączone. Dziennik backendu zgłasza typ błędu bez sekretów ani zawartości żądania.

```bash
sudo python3 -m venv /opt/hbt-play/venv
sudo /opt/hbt-play/venv/bin/pip install -r /opt/hbt-play/requirements.txt
sudo install -m 0644 backend/play/deploy/hbt-play*.service backend/play/deploy/hbt-play-maintenance.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now hbt-play.service hbt-play-maintenance.timer
sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl reload caddy
curl -fsS https://billing.example.net/health
```

`status: ready` oznacza działające połączenie TLS z usługą. Pole `mode` ma wartość `sandbox` dla konta licencyjnego albo `production` dla produkcji. Poprawność tożsamości Play i Google Publisher trzeba potwierdzić transakcją licencyjną na właściwym torze. Podaj właścicielski adres HTTPS do `HBT_PLAY_BACKEND` w eksporcie testowym. Aby udostępnić prawdziwe płatności, użyj osobnego środowiska z `HBT_PLAY_TEST=0` oraz kluczem upload i tożsamością przypisanymi do produkcyjnego pakietu. [Kroki Google Play](PLAY_BILLING.md)

## Utrzymanie i odzyskiwanie

- Timer ponawia potwierdzenie lub konsumpcję zakupu i sprawdza 14 dni zwrotów co godzinę. Uruchamia też atomową kopię SQLite raz na dobę do `/var/lib/hbt-play/backups`. Lokalnie pozostaje 14 kopii. Przenieś zaszyfrowaną kopię poza VPS, a klucze do oddzielnego sejfu.
- Obserwuj `hbt-play.service`, `hbt-play-maintenance.service` i mechanizm odnowienia certyfikatu. Używaj liczników statusów HTTP i krótkiego dziennika błędów. Nagłówki `Authorization`, tokeny, treści żądań i prywatne pliki pozostają poza logami.
- Przećwicz odtwarzanie na oddzielnym serwerze testowym. Przy odtwarzaniu produkcyjnym zatrzymaj usługę i timer, zachowaj kopię aktualnej bazy z jej WAL, a następnie podstaw zweryfikowany snapshot pod `HBT_PLAY_DB` z prawami `0600` i użytkownikiem `hbt-play`. Usuń z aktywnej ścieżki stare pliki WAL/SHM dopiero po ich zabezpieczeniu. Wznów usługę z tym samym sekretem konta i uruchom uzgodnienie zwrotów.
- Pliki instalacyjne zabezpieczają lokalną usługę i HTTP. Potwierdzenie zakupów oraz zwrotów na prawdziwym koncie wymaga testu z Play Console. Zewnętrzny hosting nie został aktywowany.

## Sprawdzenie po aktualizacji do 0.9.0

Przed aktualizacją zrób sprawdzoną kopię bazy. Wersja tworzy indeksy wygasania logowania w bieżącym schemacie. Zakupy zapisane jako oczekujące na potwierdzenie lub konsumpcję stają się dostępne w `/v1/sync` dopiero po finalizacji. W przypadku niejednoznacznej odpowiedzi Publisher proces ponawia weryfikację i korzysta z istniejącego stanu na koncie użytkownika.

```bash
curl --fail --silent --show-error https://billing.example.net/health
sudo journalctl -u hbt-play -u hbt-play-maintenance --since '24 hours ago'
sudo systemctl status hbt-play-maintenance.timer
```

W konsoli utrzymania można wykonać `python service.py monitor` z tym samym bezpiecznym plikiem ustawień i uprawnieniami co usługa. Polecenie drukuje tylko rozmiar kolejki finalizacji i wiek najstarszego elementu. Ustaw alert na brak odpowiedzi 200 z `/health` oraz rosnącą kolejkę. Zewnętrzny punkt `/health` weryfikuje, czy można czytać bazę. Pełny test poświadczeń wymaga transakcji na torze licencyjnym. Ustaw limity częstotliwości na publicznych trasach w warstwie ochrony hostingu, z kontrolą obciążenia `/v1/challenge` i `/v1/session`. Domyślna konfiguracja Caddy ogranicza treść do 16 KB.
