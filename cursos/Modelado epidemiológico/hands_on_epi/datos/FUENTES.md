# Datos reales del hands-on: procedencia

Los CSV se regeneran con `python datos/preparar_datos.py` o, en MATLAB, con `preparar_datos` (el
mismo resultado, comprobado por `pruebas/paridad_datos.py`), a partir de los archivos originales
del grupo, cuyas rutas están en los guiones. Todas son series **agregadas**: no contienen datos
personales.

| Archivo | Enfermedad · lugar | Resolución | Periodo | Columnas | Procedencia |
|---|---|---|---|---|---|
| `dengue_medellin_sivigila.csv` | Dengue · Medellín | Semana epidemiológica | 2010–2024 (780 semanas) | `t, anio, semana_epi, casos, poblacion` | Casos notificados al SIVIGILA (INS), por semana de ocurrencia, compilados en el proyecto Wolbachia del grupo (`Dengue_Cali_Med_Ocurrencia.xlsx`). La población anual es la que usa ese mismo proyecto |
| `dengue_cali_sivigila.csv` | Dengue · Cali | Semana epidemiológica | 2010–2024 (780 semanas) | `t, anio, semana_epi, casos, poblacion` | Igual que Medellín: casos notificados al SIVIGILA por semana de ocurrencia, del mismo archivo del proyecto Wolbachia (hoja `CALI`). La población anual es la de `Poblacion_CALI_2010_2024.csv` de ese proyecto (primera semana de cada año) |
| `dengue_bello_lizarralde.csv` | Dengue · Bello | Semanal | 124 semanas desde la SE 49 de 2009 | `t, casos` | Serie de Bello del repositorio de los autores (`ChimeraAedes/.../Datos/Dengue/Bello.mat`). Es la usada por Lizarralde-Bejarano et al. (2020): de la SE 49 de 2009 a la SE 7 de 2011, unos 1880 casos acumulados en el paper; en las 65 primeras semanas de este archivo suman 1894 |
| `dengue_itagui_2010.csv` | Dengue · Itagüí | Semanal | 70 semanas, brote de 2010 | `t, casos` | Repositorio de Cataño-López et al. (2022) (`CHIMERITApaper/Repository/Data/Itagui.mat`), el mismo usado en el paper del CSB |
| `covid19_colombia_jhu.csv` | COVID-19 · Colombia | Diaria | 2020-03-06 a 2021-08-04 | `t, fecha, confirmados_acum, muertes_acum, recuperados_acum, casos_nuevos, activos` | JHU CSSE COVID-19 Data Repository (licencia CC BY 4.0), copia local de `CHIMERITApaper/RawData`. Se corta cuando JHU dejó de reportar recuperados. `activos = confirmados − muertes − recuperados` |

## Picos y ventanas: un escenario por brote

Cada brote es un escenario de `escenarios.json`, para que cada estudiante elija cuál estimar. Las
ventanas van de valle a valle de la serie suavizada (media móvil de 5 semanas). Los escenarios de
cada pico los genera `python datos/preparar_datos.py --solo-escenarios` o, en MATLAB,
`preparar_datos('--solo-escenarios')`, que da lo mismo. El guion también calcula
el pico y escala los rangos de los modelos de dengue desde los de Bello: por población (Λ, Ms0,
Hs0, Hr0, C) y por los casos de la primera semana (He0, Hi0). Ese escalamiento es una **elección
del curso**, no un valor publicado.

En `escenarios.json` están hoy los que tienen la corrida completa comprobada en MATLAB y en
Python; los marcados **pendiente** están definidos en `preparar_datos` (`PENDIENTES`) y entran
cuando se comprueben.

| Escenario | Ventana | Duración | Pico |
|---|---|---|---|
| `dengue_medellin_2010` | 2010, SE 1–52 | 52 semanas | 819 casos, SE 23 de 2010 |
| `dengue_medellin_2014` (**pendiente**) | SE 13/2014 – SE 20/2015 | 60 semanas | 124 casos, SE 36 de 2014 (brote pequeño sobre una endemia alta) |
| `dengue_medellin_2016` (**pendiente**) | SE 17/2015 – SE 13/2017 | 101 semanas | 589 casos, SE 27 de 2016 |
| `dengue_medellin_2024` (**pendiente**) | SE 21/2023 – SE 52/2024 | 84 semanas | 176 casos, SE 34 de 2024 (la serie termina antes de que el brote baje del todo) |
| `dengue_cali_2010` (**pendiente**) | SE 1/2010 – SE 13/2011 | 65 semanas | 557 casos, SE 7 de 2010 (la serie empieza cerca del pico) |
| `dengue_cali_2013` (**pendiente**) | SE 37/2012 – SE 13/2014 | 81 semanas | 478 casos, SE 16 de 2013 (salto en la SE 1 de 2013 y meseta) |
| `dengue_cali_2015` (**pendiente**) | SE 33/2014 – SE 41/2015 | 61 semanas | 575 casos, SE 14 de 2015 |
| `dengue_cali_2016` (**pendiente**) | SE 41/2015 – SE 13/2017 | 77 semanas | 834 casos, SE 6 de 2016 |
| `dengue_cali_2015_2016` (**pendiente**) | SE 33/2014 – SE 13/2017 | 137 semanas | Los dos anteriores en una sola ventana |
| `dengue_cali_2020` (**pendiente**) | SE 21/2019 – SE 52/2020 | 84 semanas | 676 casos, SE 10 de 2020 (coincide con el inicio de la pandemia) |
| `dengue_cali_2024` (**pendiente**) | SE 13/2023 – SE 52/2024 | 92 semanas | 1295 casos, SE 21 de 2024, el mayor de la serie |
| `dengue_bello_2009_2011` | `t = 0…64` (SE 49/2009 – SE 7/2011) | 65 semanas | La ventana de Lizarralde et al. (2020): permite comparar con el paper |
| `dengue_itagui_2010` | `t = 0…69` | 70 semanas | El brote de 2010 del paper del CSB |
| `covid_colombia_ola1` | 2020-03-06 a 2020-11-30 | 270 días | 169 326 activos, 2020-08-14 |
| `covid_colombia_ola2` | 2020-11-16 a 2021-03-10 | 115 días | 131 943 activos, 2021-01-24 |
| `covid_colombia_ola3` | 2021-03-10 a 2021-08-04 | 148 días | 201 607 activos, 2021-06-28 |
| `covid_colombia_tres_olas` (**pendiente**) | 2020-03-06 a 2021-08-04 | 517 días | Las tres olas juntas |

En las olas 2 y 3 de COVID-19 ya hay infectados y recuperados al empezar: I0 y R0 parten de los
activos y recuperados reportados el primer día (detalle en las notas de cada escenario).

Lo que **no** se volvió escenario:
- En Medellín, la subida de 2019 (unos 40 casos por semana) es pequeña frente al ruido, y de 2020 a
  2023 la serie está en niveles muy bajos.
- `Casos_Medellin_Itagui_Bello_Semanal.xlsx` y los `*_weekly.xlsx` del proyecto Wolbachia reparten
  datos **mensuales** en semanas: el mismo valor se repite dentro de cada mes. No sirven como serie
  semanal.

## Población

- **Medellín y Cali:** columna `poblacion`, una por año. En Medellín falta 2024.
- **Bello:** del proyecto Wolbachia, unos 359 515 habitantes en 2010; los autores usaron 450 000 en
  `CHIMERA_Vector`.
- **Itagüí:** los autores usaron 280 000.
- **Colombia:** 50 372 424, el valor de Cataño-López et al. (2023, PLOS ONE).

Las poblaciones de Bello e Itagüí no vienen en los CSV. Cada modelo las recibe en `opt` y el guion
las documenta.

## Cosas a tener en cuenta en clase

- Son casos **notificados**, no infecciones: hay subregistro, y en dengue la mayoría de
  infecciones son asintomáticas.
- En el SIVIGILA, las semanas recientes se completan con notificaciones tardías.
- Los recuperados de JHU para Colombia son un dato administrativo, no clínico.

## Dónde descargar datos reales

Enlaces abiertos y revisados el 26 de octubre de 2026. Los portales cambian: si alguno se mueve,
búscalo por su nombre.

**Colombia: INS y SIVIGILA**
- [Portal SIVIGILA](https://portalsivigila.ins.gov.co/) (INS): entrada al sistema de vigilancia, con
  el tablero en Power BI y el geovisor.
- [Microdatos del SIVIGILA](https://portalsivigila.ins.gov.co/Paginas/Buscador.aspx): se elige el
  evento (por ejemplo, dengue) y el año, se pulsa **Buscar** y, antes de descargar, se llena un
  formulario corto (correo, entidad, nombre y propósito). Hay datos desde 2007. Son registros
  individuales **sin datos de identificación personal**. Para el curso se cuentan por año y semana
  epidemiológica y se trabaja solo con la serie agregada.
- [Boletín Epidemiológico Semanal (BES)](https://www.ins.gov.co/buscador-eventos/Paginas/Vista-Boletin-Epidemilogico.aspx)
  del INS: un número por semana desde 2006, con la situación de cada evento. Sirve para entender el
  contexto de un brote y contrastar cifras.
- [Informes de evento](https://www.ins.gov.co/buscador-eventos/Paginas/Info-Evento.aspx) del INS:
  informes por evento y periodo; el dengue tiene varios por año.

**Datos abiertos: datos.gov.co y alcaldías**
- [Dengue, Alcaldía de Medellín](https://www.datos.gov.co/d/ke8u-qixu) (datos.gov.co): enlaza a un
  CSV de MEData, `sivigila_dengue.csv` (unos 7,8 MB, licencia CC BY-SA 4.0), con los casos de
  Medellín notificados al SIVIGILA desde 2008, uno por fila y sin nombres. Las columnas `year_` y
  `semana` permiten agregar por semana epidemiológica.
- [Dengue geográfico, GeoMedellín](https://www.medellin.gov.co/giscatalogacion/srv/api/records/aa832bc9-e17e-42b8-a99f-632fb3b9f325):
  casos y tasa por 100 000 habitantes por comuna y corregimiento, como capa geográfica (CC BY-SA).
  Sirve para mirar el espacio, no para series semanales.
- [Dengue, Distrito de Santiago de Cali](https://www.datos.gov.co/d/fapv-a47d) (datos.gov.co): ficha
  que apunta al portal de datos de Cali (casos notificados al SIVIGILA en 2022, CSV, licencia CC0).
  El 26 de octubre de 2026 la Alcaldía tenía ese portal suspendido temporalmente, así que la
  descarga no se pudo comprobar.
- [Búsqueda «dengue» en datos.gov.co](https://www.datos.gov.co/browse?q=dengue): otros municipios y
  departamentos publican sus propias series (Bucaramanga, Pereira, Caquetá, Tuluá, Bogotá…).

**Internacionales**
- [PLISA, OPS/OMS](https://opendata.paho.org/es): portal de datos abiertos de la OPS. Su sección
  [Dengue: datos y análisis](https://www.paho.org/es/arbo-portal/dengue-datos-analisis) reúne lo que
  reportan cada semana 46 países y territorios de las Américas: casos, incidencia, casos graves,
  muertes y serotipos, con incidencia histórica desde 1980. Es a escala de país.
- [JHU CSSE COVID-19 Data Repository](https://github.com/CSSEGISandData/COVID-19): series diarias
  por país de confirmados, muertes y recuperados, en
  [`csse_covid_19_time_series`](https://github.com/CSSEGISandData/COVID-19/tree/master/csse_covid_19_data/csse_covid_19_time_series)
  (por ejemplo, `time_series_covid19_confirmed_global.csv`). Licencia CC BY 4.0. Archivado el 10 de
  marzo de 2023. Es la fuente de `covid19_colombia_jhu.csv`.
- [Our World in Data, COVID-19](https://ourworldindata.org/covid-cases): casos y muertes por país.
  El CSV completo es
  [`compact.csv`](https://catalog.ourworldindata.org/garden/covid/latest/compact/compact.csv)
  (columnas `country`, `date`, `new_cases`, `new_cases_smoothed`, …), documentado en
  [docs.owid.io](https://docs.owid.io/projects/etl/api/covid/). Su repositorio en GitHub,
  [owid/covid-19-data](https://github.com/owid/covid-19-data), está archivado desde agosto de 2024.
