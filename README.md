# Záverečný projekt – ELT a DWH v Snowflake

## Autori
- Samuel Haluza
- Tomáš Hubina

## 1. Úvod
V tejto práci analyzujeme dáta o predpovediach počasia a samotnom počasí v niekoľkých lokalitách po celom svete za 4. kvartál roku 2025. Cieľom našej analýzy je:
- porovnať predpovede počasia s finálnym meraním
- zistiť, či môžu faktory, ako napríklad zrážky, ovplyvniť predpovedanú teplotu
- zistiť, ako počasie ovplyvňovalo spoločnosť (bezpečnosť na castách, návštevnosť alebo index produktivity v našich lokalitách)

## 2. Zdrojové dáta (Snowflake Marketplace)
Zdrojové dáta pochádzajú zo Snowflake Marketplace free datasetu WEATHER_SOURCE_LLC_FROSTBYTE. Dataset sa zameriava na predpovede počasia v meraných lokalitách po celom svete a rovnako tak na skutočne namerané hodnoty. 

Dataset obsahuje 7 tabuliek: 
- 3 tabuľky sa zameriavajú na predpoveď počasia, históriu predpovedí počasia a skutočné namerané hodnoty v dňoch (forecast_day, forecast_history_day a history_day)
- 3 tabuľky sa zameriavajú na predpoveď počasia, históriu predpovedí počasia a skutočné namerané hodnoty v hodinách (forecast_history, forecast_history_hour a history_hour)
- 1 tabuľka obsahuje zoznam lokalít, kde prebieha meranie (postal_codes)

Nakoľko tento projekt slúži ako záverečný projekt do školy a pôvodný dataset obsahuje obrovské množstvo dát, rozhodli sme sa dáta trochu orezať na menej lokalít, meraní, či kratší časový úsek.

Surové dáta sú usporiadané v relačnom modeli, ktorý je znázornený na entitno-relačnom diagrame (ERD):

<img width="2811" height="2691" alt="ERD_raw" src="https://github.com/user-attachments/assets/e259e21e-be96-4c2d-8cf6-06a2e460e1ef" />


Diagram bol vytvorený pomocou dbdiagram.io. Dôvodom bolo lepšie vykreslenie vzájomných "vzťahov" medzi tabuľkami - nakoľko neobsahuje PKs.

## 3. Dimenzionálny model
V ukážke bola navrhnutá **schéma hviezdy** (star schema) podľa Kimballovej metodológie, ktorá obsahuje **2 tabuľky faktov fact_weather_day** a **fact_weather_hour**, ktoré sú prepojené s nasledujúcimi 5 dimenziami:

- **dim_location**: obsahuje údaje o lokalite (krajine, meste a kóde) - SCD Typ 1
- **dim_data_type**: pomáha s rozdeľovaním medzi predpoveďou a meraním - SCD Typ 0
- **dim_granularity**: pomáha s rozdeľovaním medzi hodinou a dňom - SCD Typ 0
- **dim_date**: obsahuje záznamy o dátumoch, pre ktoré je meranie platné - SCD Typ 0
- **dim_time**: obsahuje záznamy o časoch 00:00:00-23:00:00 - SCD Typ 0

Štruktúra hviezdicového modelu je znázornená na diagrame nižšie. Diagram ukazuje prepojenia medzi faktovou tabuľkou a dimenziami.

<img width="917" height="691" alt="star_scheme_weather" src="https://github.com/user-attachments/assets/d3c8077e-d689-43d5-9f78-2e2c9f933c6d" />

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
**1. Index Produktivity Práce**

Čo vidíme: Krajiny zoradené podľa priemerného produktívneho indexu, ktorý kombinuje teplotu, vlhkosť a rýchlosť vetra.

Význam: Firmy môžu identifikovať krajiny s najlepším prostredím pre prácu a optimalizovať lokalizáciu výroby alebo outsourcing.

Pozorovania:

Egypt (87) a Austrália (85) majú najlepšie podmienky pre prácu: teplé počasie, primeraná vlhkosť a mierny vietor.

Švédsko (64) a Poľsko (67) majú nižší index kvôli chladnejšej teplote a vyššej vlhkosti.

Vizualizácia: Horizontálny bar chart, krajiny na osi X, index na osi Y, zoradené zostupne.

![produktivita](https://github.com/user-attachments/assets/8aa91f1c-a494-4867-b5ed-36be6876e9e9)


**2. Index Bezpečnosti Dopravy**

Čo vidíme: Hodnotenie bezpečnosti dopravy podľa počasia: dážď, vietor, oblačnosť a riziko ľadu.

Význam: Logistické spoločnosti môžu optimalizovať medzinárodné trasy a vybrať krajiny s najbezpečnejšími podmienkami pre transport.

Pozorovania:

Egypt (98) je najbezpečnejší, vďaka nízkym zrážkam a miernemu vetru.

Taliansko (94) a Austrália (94) sú tiež veľmi bezpečné, s minimom dažďa a priaznivou teplotou.

Švédsko (88) a Poľsko (88) majú nižší index kvôli chladnejšiemu a vlhkejšiemu počasiu.

Vizualizácia: Horizontálny bar chart, krajiny zoradené podľa bezpečnostného indexu.

![doprava](https://github.com/user-attachments/assets/544ab9c6-0e8d-4016-9c8f-5a20402e39ad)


**3. Index Očakávanej Návštevnosti**

Čo vidíme: Predpokladaná návštevnosť obchodov podľa klimatických podmienok: teplota, oblačnosť, dážď a extrémy.

Význam: Retail reťazce môžu plánovať expanziu, predpovedať tržby a optimalizovať marketing podľa krajiny.

Pozorovania:

Egypt (90) a Austrália (91) sú ideálne pre vysokú návštevnosť: teplé a slnečné dni s minimom dažďa.

Francúzsko (78) a Taliansko (75) majú strednú návštevnosť – priaznivé počasie väčšinu času, ale viac oblačnosti a zrážok.

Švédsko (63) a Poľsko (63) majú nižší index kvôli chladnejším a vlhkejším podmienkam.

Vizualizácia: Horizontálny bar chart, krajiny zoradené podľa očakávaného indexu návštevnosti.

![navstevnost](https://github.com/user-attachments/assets/cbde027e-d011-4675-ad20-4a9bd2f77acb)


Kombinácia Krajina + Hodina
Čo vidíme: Detailný pohľad na vybrané top krajiny s priemernými hodinovými hodnotami teploty a vlhkosti.
Význam: Pomáha analyzovať denné vzorce počasia, napríklad pre plánovanie pracovných zmien, logistiku alebo retail prevádzku.
Pozorovania:
V teplých krajinách (Egypt, Austrália) je počas dňa stabilná teplota a nízka vlhkosť, ideálne pre vonkajšie aktivity a prácu.
V chladnejších krajinách (Švédsko, Poľsko) je viac kolísania teploty počas dňa, čo môže ovplyvniť logistiku a návštevnosť obchodov.

**4. Porovnanie predpovedí počasia oproti skutočnému meraniu**

Vizualizácia zobrazuje súčastne predpovede počasia a skutočné merania počas obdobia 1.10.2025-31.12.2025 teda obdobím 4. kvartálu 2025. 
Zároveň obsahuje aj kryvku samotnej odchýlky medzi meraním s predpoveďou.

Pomocou grafu tak vieme posúdiť relatívnu presnosť predpovedí počasia.

![odchylky_teplota](https://github.com/user-attachments/assets/56ff62d9-e0b7-40cb-880e-0bd988295f7c)


**5. Ovplyvnenie predpovedí teplôt zrážkami**

Vizualizácia sa delí do 2 hlavných skupín dňami so zrážkami a dňami bez zrážok. Tieto skupiny sa ďalej delia podľa lokalít a jednotlivé stĺpce značia odchýlku teplôt v týchto lokalitách.
Vizualizáciou vieme povedať, či zrážky majú vplyv na predpoveď teploty:
- Zoberme si príklad, kde je tento rozdieľ najväčší - Egypt - 90 dní bez zrážok a 2 dni so zrážkami
- Rozdiel medzi týmito 2 záznamami je približne dvojnásobný
- Na základe toho by sme mohli subjektívne posúdiť, že zrážky skutočne môžu ovlyvniť teplotnú predpoveď.

![odchylky_vplyv_zrazok](https://github.com/user-attachments/assets/d49ab6cc-2594-48ee-86d0-5005a0546769)


**6. Ovplyvnenie predpovedí teplôt zrážkami - celokvo**

Vizualizácia funguje na podobnom princípe ako vyššie spomenutá. Rozdiel je v tom, že táto nám už nezobrazuje spomínané 2 hlavné skupiny (so zrážkami a bez zrážok) rozdelené ďalej na lokality, ale celkovo všetky lokality bez rozdielu.
Získali sme tak ďalší bod k našej otázke, či na základe poskytnutých dát môžu zrážky ovplyvniť predpoveď teploty. A opäť vidíme, že pri zrážkach je tento rozdiel väčší.

![odchylky_vplyv_zrazok_celkovo](https://github.com/user-attachments/assets/efd65395-10bc-4708-89e0-4afb8ea95474)


**7. Celkový bias predpovedí počasia**

Na záver našej analýzy máme len jedno číslo - -0,69 - to nám ale vie veľa povedať. Číslo -0,69 nám totiž vyjadruje celkový bias našich predpovedí počasia. A na základe neho vieme povedať, že predpovede počasia sú v priemere o 0,69 Fahrenheita podhodnotené.

![celkovy_bias_predpovedi](https://github.com/user-attachments/assets/3c43a1fe-14f4-4873-919f-bd1e404e22c3)
