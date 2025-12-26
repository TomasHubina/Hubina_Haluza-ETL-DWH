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
(Tu doplníme)
