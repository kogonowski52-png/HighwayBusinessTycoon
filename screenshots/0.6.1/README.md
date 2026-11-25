# Highway Business Tycoon 0.6.1 w Godocie

Kadry są bezpośrednimi odczytami renderowanego widoku Godota. Panoramy mają 1152 × 782, ujęcia pionowe 640 × 1138. Scenariusz przechodzi przez przyciski atlasu i rzeczywiste trasy pojazdów. Część ujęć używa przygotowanych w testach poziomów i załóg, żeby pokazać późne etapy budynków.

| Lokalizacja | Panorama | Działająca usługa |
| --- | --- | --- |
| Stacja Północ | [Kompleks](06-polnoc-panorama.jpg) | [Ręczne tankowanie](02-polnoc-tankowanie.jpg) |
| Desert Highway | [Copper Mile](13-copper-mile-panorama.jpg) | [Serwis TIR Red Mesa](10-red-mesa-serwis.jpg) |
| Green Valley | [Riverbend i mosty](16-green-valley-panorama.jpg) | [Dostawa do Greenbank](20-greenbank-dostawa.jpg) |
| Alpine Pass | [Przełęcz](23-alpine-panorama.jpg) | [Autokar pod Snowline Lodge](25-snowline-autokar.jpg) |
| Ocean Coast | [Coral Key i plaża](28-ocean-coast-panorama.jpg) | [Myjnia Pearl Bay](32-pearl-bay-myjnia.jpg) |
| Metro City | [Meridian nocą](34-metro-panorama-noc.jpg) | [Przeładunek w Meridian Freight](37-terminal-zaladunek.jpg) |

[Mapa świata](03-atlas-szesciu-lokalizacji.jpg) · [Podgląd i wymagania](04-green-valley-warunki.jpg) · [Wydarzenie](05-wydarzenie-wakacyjny-kurort.jpg) · [Lokalny kontrakt](45-kontrakt-meridian.jpg) · [Album trasy](46-znaki-podrozy.jpg) · [Powrót i offline](50-powrot-zarobki-offline.jpg)

[Magazyn przed rozbudową](44-magazyn-prog-01.jpg) · [Poziom 30](44-magazyn-prog-30.jpg) · [Poziom 90](44-magazyn-prog-90.jpg) · [Ekran magazynu](43-panel-magazynu.jpg) · [Salon](39-apex-motors.jpg) · [Centrum handlowe](40-crossline-klienci.jpg)

[Przejazd z gry w Movie Maker](podroz-meridian-riverbend.mp4) · [Porównanie z ekspansją 0.6.0](../0.6.0/README.md)

```bash
godot --path . --script tests/regional_window.gd -- --capture-dir=/tmp/hbt-061-gallery
godot --path . --write-movie /tmp/hbt-061.avi --fixed-fps 30 --script tests/regional_recording.gd
```
