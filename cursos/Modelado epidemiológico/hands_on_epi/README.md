# Hands-on de epidemiología con datos reales · GSUA-CSB

Semillero de Investigación en Matemáticas · Universidad EAFIT

Ajustamos modelos epidemiológicos a **datos reales** y nos preguntamos qué tanto se puede saber
de sus parámetros. Hay dos tipos de transmisión:

- **Entre personas:** COVID-19 en Colombia: primera, segunda y tercera ola.
- **Por vectores:** dengue en Bello, Medellín e Itagüí.

Cada uno se puede estudiar con modelos discretos o continuos. Todo funciona igual en **MATLAB** y
en **Python**.

## Requisitos

- **MATLAB:** la toolbox **GSUA-CSB v1.13** (`GSUA-CSB.mltbx`).
- **Python ≥ 3.10:** el paquete `gsua_csb` (carpeta `python/` de
  <https://github.com/drojasd/GSUA-CSB>), además de numpy, scipy, pandas y matplotlib.

## Cómo correrlo

**MATLAB:** abre `matlab/handson.m`, elige `ESCENARIO` y `MODELO` en la sección 0 y ejecuta por
secciones. Para una prueba rápida: `RAPIDO = true; handson`.

**Python:**

```bash
cd python
python handson.py --listar
python handson.py --escenario dengue_bello_2009_2011 --modelo dengue_cl_discreto
python handson.py --rapido          # tamaños mínimos, para comprobar que todo corre
```

Los resultados (un JSON con estimaciones, intervalos y veredictos, más tres figuras) quedan en
`resultados/`.

## El recorrido (igual en los dos lenguajes)

| Paso | Qué hace | Pregunta |
|---|---|---|
| 1. Datos | Carga la serie real y la ventana del escenario | ¿Qué forma tiene el brote? |
| 2. Modelo | Arma el modelo de la toolbox con los rangos del catálogo, ajustados a la localidad | ¿Qué factores son libres y cuáles fijos? |
| 3. Nominal | Simula con el centro de los rangos | ¿Se parece a los datos sin ajustar nada? |
| 4. Incertidumbre | Banda P5–P95 sobre una muestra del hipercubo latino | ¿Los datos caben en lo que el modelo puede producir? |
| 5. Sensibilidad | Índices totales STᵢ (Xiao) | ¿Qué factores mueven la salida? |
| 6. Estimación | Mínimos cuadrados multicomienzo | ¿Cuál es el mejor ajuste? ¿Cuántos arranques hacen falta? |
| 7. Bootstrap | Re-ajusta datos sintéticos (ajuste + residuos re-muestreados) | ¿Cuánto cambian los parámetros si los datos cambian un poco? |
| 8. Identificabilidad | IC 95 % del bootstrap, ancho relativo al rango, índice de `gsua_ia`, correlaciones | ¿Qué parámetros determinan de verdad los datos? |

El veredicto sugerido depende del ancho del IC relativo al rango de búsqueda: menos de 25 % es
**sí**, más de 50 % es **no**, y en medio es **dudoso**. Es una guía, no una prueba: la decisión es
tuya. El `Range` de `gsua_ia` es un intervalo para la **mediana** del conjunto de estimaciones, no
para el parámetro. Por eso aquí el intervalo sale de los percentiles del bootstrap.

## Escenarios (`escenarios.json`)

Hay un escenario por brote: **elige uno** y estímalo. `python handson.py --listar` los muestra
todos.

| id | Datos | Salida comparada | Modelos sugeridos |
|---|---|---|---|
| `covid_colombia_ola1` | COVID-19 Colombia, 2020-03-06 a 2020-11-30, activos diarios (JHU) | activos (detectados en el modelo con cuarentena) | `sir_continuo`, `sir_discreto`, `sir_discreto_G1`, `sir_cuarentena_cl` |
| `covid_colombia_ola2` | Segunda ola, 2020-11-16 a 2021-03-10 | igual | los mismos |
| `covid_colombia_ola3` | Tercera ola, 2021-03-10 a 2021-08-04 | igual | los mismos |
| `dengue_bello_2009_2011` | Dengue Bello, SE 49/2009 – SE 7/2011 | casos semanales | `dengue_lizarralde`, `dengue_cl_discreto` |
| `dengue_bello_acumulado` | La misma ventana, en casos acumulados como en el paper | casos acumulados | los mismos |
| `dengue_medellin_2010` | Dengue Medellín 2010, SIVIGILA | casos semanales | los mismos |
| `dengue_itagui_2010` | Dengue Itagüí, brote de 2010 | casos semanales | los mismos |

**Pendientes:** ya están identificados y definidos otros 11 brotes (Medellín 2014, 2016 y 2024;
Cali 2010, 2013, 2015, 2016, 2015–2016, 2020 y 2024; las tres olas de COVID-19 juntas), con la
serie de Cali en `datos/dengue_cali_sivigila.csv`. Entran a `escenarios.json` cuando su corrida
completa quede comprobada en MATLAB y en Python. La lista, con sus ventanas y picos, está en
[`datos/FUENTES.md`](datos/FUENTES.md).

Procedencia y licencias de cada serie, y **dónde descargar más datos reales** (SIVIGILA, INS,
datos.gov.co, OPS, JHU, Our World in Data): [`datos/FUENTES.md`](datos/FUENTES.md).

## Modelos (`modelos/catalogo_*.json`)

| id | Tipo | Idea |
|---|---|---|
| `sir_continuo` | EDO | SIR clásico |
| `sir_discreto` | Discreto | SIR con probabilidad de contagio **exponencial**, P = 1 − e^(−βI/N) |
| `sir_discreto_G1`, `_G2`, `_G3` | Discreto | El mismo SIR con las probabilidades de contagio de Cataño-López et al. (2022), con heterogeneidad ℵ |
| `sir_cuarentena_cl` (`_G2`, `_G3`) | Discreto | Modelo con cuarentena y detección de Cataño-López et al. (2022), ec. (6) |
| `dengue_lizarralde` | EDO, 7 ecuaciones | Lizarralde-Bejarano et al. (2020), modelo (3): Ms, Me, Mi, Hs, He, Hi, Hr |
| `dengue_cl_discreto` | Discreto | Cataño-López et al. (2022), ec. (9): humano–mosquito con reclutamiento de Ricker |

Cada entrada del catálogo trae los rangos con su fuente (tabla del paper o guion de los autores) y
notas de dónde difieren el paper y el código de los autores.

**Papers de los modelos** (DOI comprobados en Crossref y doi.org)

| Modelo | Paper |
|---|---|
| `sir_continuo` | Kermack WO, McKendrick AG (1927). A contribution to the mathematical theory of epidemics. *Proc R Soc Lond A* 115(772):700–721. [doi:10.1098/rspa.1927.0118](https://doi.org/10.1098/rspa.1927.0118) |
| `sir_discreto` (exponencial) | SIR discreto clásico, con probabilidad de escape tipo Reed–Frost; no viene de un artículo único |
| `sir_discreto_G1`, `_G2`, `_G3`; `sir_cuarentena_cl` (y `_G2`, `_G3`); `dengue_cl_discreto` | Cataño-López A, Rojas-Díaz D, Lizarralde-Bejarano DP, Puerta Yepes ME (2022). Discrete Models in Epidemiology: New Contagion Probability Functions Based on Real Data Behavior. *Bull Math Biol* 84(11):127. [doi:10.1007/s11538-022-01076-6](https://doi.org/10.1007/s11538-022-01076-6) |
| `sir_cuarentena_cl` con datos de Colombia (y la población usada) | Cataño-López A, Rojas-Díaz D, Lizarralde-Bejarano DP, Puerta Yepes ME (2023). A discrete model for the evaluation of public policies: The case of Colombia during the COVID-19 pandemic. *PLOS ONE* 18(2):e0275546. [doi:10.1371/journal.pone.0275546](https://doi.org/10.1371/journal.pone.0275546) |
| `dengue_lizarralde` | Lizarralde-Bejarano DP, Rojas-Díaz D, Arboleda-Sánchez S, Puerta-Yepes ME (2020). Sensitivity, uncertainty and identifiability analyses to define a dengue transmission model with real data of an endemic municipality of Colombia. *PLOS ONE* 15(3):e0229668. [doi:10.1371/journal.pone.0229668](https://doi.org/10.1371/journal.pone.0229668) |
| Reclutamiento de mosquitos en `dengue_cl_discreto` | Ricker WE (1954). Stock and Recruitment. *J Fish Res Board Can* 11(5):559–623. [doi:10.1139/f54-039](https://doi.org/10.1139/f54-039) |

Para ir más allá:
- Cataño-López A, Rojas-Díaz D, Vélez CM (2022). The Influence of Anthropogenic and Environmental
  Disturbances on Parameter Estimation of a Dengue Transmission Model. *Trop Med Infect Dis*
  8(1):5. [doi:10.3390/tropicalmed8010005](https://doi.org/10.3390/tropicalmed8010005). Ajusta dos
  brotes seguidos de Bello (2010–2014) con control químico: una respuesta a los escenarios de
  varios picos.
- Rojas-Díaz D, Cataño-López A, Vélez CM, Ortiz S, Laniado H (2024; en línea en 2023). Confidence
  sub-contour box: an alternative to traditional confidence intervals. *Comput Stat*
  39(5):2821–2858. [doi:10.1007/s00180-023-01362-4](https://doi.org/10.1007/s00180-023-01362-4). El método CSB que
  da nombre a la toolbox.

## Tiempos de referencia

En un portátil, con los tamaños por omisión:
- Los modelos discretos tardan segundos a pocos minutos.
- `dengue_lizarralde` (EDO, 14 factores) puede tardar decenas de minutos en Python. Usa `--sin-sa`
  y menos arranques (`--n-multi 20`) para explorar, y la corrida completa para la conclusión.

## Preguntas para el equipo

1. Con COVID-19, compara `sir_discreto` (exponencial) con `sir_discreto_G1` (contagio heterogéneo). ¿Cambian β y γ?
   ¿Cuál es el par más correlacionado y por qué?
2. ¿Por qué el SIR no reproduce la meseta ni las olas posteriores? ¿Qué agrega `sir_cuarentena_cl`?
3. En dengue de Bello, ajusta casos **semanales** y **acumulados** con el mismo modelo. ¿Cuál
   identifica más parámetros? ¿Por qué el paper ajustó acumulados?
4. `dengue_cl_discreto` con 10 arranques frente a 60. ¿Qué te dice sobre los mínimos locales?
5. ¿Qué parámetros de los mosquitos son identificables solo con casos humanos? ¿Qué dato de campo
   ayudaría?
6. Los rangos de Medellín se escalaron desde Bello por población. ¿Qué tan sensibles son
   tus conclusiones a esa elección?
7. Ajusta el mismo modelo a dos olas de COVID-19 (`covid_colombia_ola2` y `covid_colombia_ola3`).
   ¿Salen los mismos parámetros? ¿Qué papel juega R0, la inmunidad que dejó la ola anterior?

## Para la coordinación

- `CONTRATO.md`: cómo está construido el material (firmas, convenciones, pruebas).
- Pruebas: `pruebas/test_*.py`, `pruebas/paridad_*.py` (pytest), `pruebas/pruebas_*.m`. La
  paridad cubre los modelos, cada escenario con sus modelos sugeridos y la preparación de datos
  (ver `CONTRATO.md`).
- Datos y escenarios de cada pico: `datos/preparar_datos.py` o su espejo `datos/preparar_datos.m`
  (con `--solo-escenarios` no necesitan los archivos originales del grupo).
- Para correr todas las combinaciones: `python pruebas/correr_handson.py` y, en MATLAB,
  `correr_handson`.
