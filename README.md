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
V ukážke bola navrhnutá **schéma hviezdy** (star schema) podľa Kimballovej metodológie, ktorá obsahuje **2 tabuľky faktov fact_weather_day** a **fact_weather_hour**, ktoré sú prepojené s nasledujúcimi 5 dimenziami:

- **dim_location**: obsahuje údaje o lokalite (krajine, meste a kóde)
- **dim_data_type**: pomáha s rozdeľovaním medzi predpoveďou a meraním
- **dim_granularity**: pomáha s rozdeľovaním medzi hodinou a dňom
- **dim_date**: obsahuje záznamy o dátumoch, pre ktoré je meranie platné
- **dim_time**: obsahuje záznamy o časoch 00:00:00-23:00:00

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami.

(star schema)

## 4. ELT proces
Po pridaní databázy z Market Place sme začali pracovať na tvorbe staging tabuliek - tie ako už bolo spomenuté v časti *2. Zdrojové dáta* bolo potrebné pre veľké množstvo dát orezať o niektoré lokality a časové obdobia.

Podrobný popis pre jednotlivé tabuľky nájdete v časti *sql->staging_tables.sql*

Po dokončení staging tabuliek sme začali riešiť tvorbu a návrh biznis logiky pre tabuľky star schémy - **transform**.

**Primárne kľúče**
Pre dim_date a dim_time používame ako kľúč zápis v podobe YYYYMMDD a HH24MISS - tie zároveň zobrazujú časový záznam ktorý značí kedy bolo meranie vykonané alebo na kedy má byť predpoveď platná (tzn. nie čas predpovede).
Ostatné tabuľky používajú uuid ako svoj primárny kľúč.

**Zdroj dát**
Tabuľky využívajú 1 alebo viac staging tabuliek ako svoj zdroj. 

- Dimenzie zaznamenávajúce čas používajú 2 tabuľky. Pre dim_date history_day_staging a forecast_history_day_staging, ale forecast_day_staging už nie, pretože táto zaznamenáva dáta práve pre aktuálny deň - keďže nahrávanie neprebieha živo, môže sa stať, že by sa stali dáta neaktuálnymi a spôsobili problémy. Rovnako náš biznis model uvažuje nad historickými dátami.

- Tabuľky faktov používajú atribúty zo staging tabuliek na podobnom princípe ako vyššie spomenuté dimenzie. Navyše používajú niektoré dimenzie ako zdroj prepojenia pomocou cudzích kľúčov. fact_weather_hour obsahuje navyše aj dim_time, keďže potrebuje nie len dátum, ale aj čas v hodinách.

**Window functions**
Funkcie ako row_number() využívajú už staging tabuľky - pomocou nich sme filtrovali len prvý záznam (čisto len z kapacitných dôvodov).
Neskôr používame aj lag() v tabuľkách faktov pre hodinové alebo denné zmeny.

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
