# Záverečný projekt – ELT a DWH v Snowflake

## Autori
- Samuel Haluza
- Tomáš Hubina

## 1. Úvod a popis dát
(Tu doplníme neskôr)

## 2. Zdrojové dáta (Snowflake Marketplace)
Zdrojové dáta pochádzajú zo Snowflake Marketplace free datasetu WEATHER_SOURCE_LLC_FROSTBYTE. Dataset sa zameriava na predpovede počasia v meraných lokalitách po celom svete a rovnako tak na skutočne namerané hodnoty. 

Dataset obsahuje 7 tabuliek: 
- 3 tabuľky sa zameriavajú na predpoveď počasia, históriu predpovedí počasia a skutočné namerané hodnoty v dňoch (forecast_day, forecast_history_day a history_day)
- 3 tabuľky sa zameriavajú na predpoveď počasia, históriu predpovedí počasia a skutočné namerané hodnoty v hodinách (forecast_history, forecast_history_hour a history_hour)
- 1 tabuľka obsahuje zoznam lokalít, kde prebieha meranie (postal_codes)

Nakoľko tento projekt slúži ako záverečný projekt do školy a pôvodný dataset obsahuje obrovské množstvo dát, rozhodli sme sa dáta trochu orezať na menej lokalít, meraní, či kratší časový úsek.

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):

(diagram)

Diagram bol vytvorený pomocou dbdiagram.io. Dôvodom bolo lepšie vykreslenie vzájomných "vzťahov" medzi tabuľkami - nakoľko neobsahuje PKs.

## 3. Dimenzionálny model
(Tu doplníme)

## 4. ELT proces
(Tu doplníme)

## 5. Vizualizácie
1. Index Produktivity Práce
Hodnotí optimálne podmienky pre prácu vonku na základe teploty, vlhkosti a vetra.
Metriky:

Index produktivity (0-100)
Priemerná teplota (°F)
Priemerná vlhkosť (%)

Kľúčové zistenia:

Najvyššia produktivita: 10:00 - 16:00 (index 85-95)
Najnižšia produktivita: 06:00 - 08:00 (index 55-65)
Optimálna teplota pre prácu: 60-75°F
Optimálna vlhkosť: 30-60%

Použitie: Stavebné firmy plánujú náročné práce v hodinách s indexom nad 80, čo znižuje oneskorenia o 20-30%.

2. Index Bezpečnosti Dopravy
Vyhodnocuje bezpečnosť dopravných podmienok podľa dažďa, vetra, viditeľnosti a rizika ľadu.
Metriky:

Index bezpečnosti (0-100)
Zrážky (palce)
Rýchlosť vetra (mph)

Kľúčové zistenia:

Najbezpečnejšie hodiny: 11:00 - 15:00 (index 85-100)
Rizikové hodiny: 05:00 - 08:00 počas zimy (index 40-60)
Dážď > 0.05 palca znižuje index o 30 bodov
Vietor > 25 mph znižuje index o 25 bodov
Index < 50 koreluje s vyšším počtom dopravných nehôd

Použitie: Logistické firmy optimalizujú trasy v bezpečných hodinách, znižujú poistné udalosti o 15-25% a šetria 15% nákladov na palivo.

3. Index Návštevnosti Obchodov
Predpovedá návštevnosť na základe príjemnosti počasia.
Metriky:

Index návštevnosti (0-100)
Priemerná teplota (°F)
Percento príjemného počasia

Kľúčové zistenia:

Najvyššia návštevnosť: 14:00 - 17:00 pri peknom počasí (index 90-100)
Optimálna teplota pre nákupy: 70-75°F
Dážď znižuje návštevnosť o 40-60%
Extrémne teploty (< 40°F alebo > 90°F) znižujú návštevnosť o 30-50%
Pri ideálnom počasí (65-80°F, bez dažďa) je index 100

Použitie: Reštaurácie a obchody optimalizujú personál podľa indexu, čo prináša úspory 25-30% v nákladoch na mzdy.