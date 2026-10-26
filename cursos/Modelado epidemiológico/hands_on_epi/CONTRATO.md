# Hands-on de epidemiología: contrato común (MATLAB ⇄ Python)

Material del curso de modelado epidemiológico del semillero. Se usan datos **reales** y una
**familia de modelos intercambiables**, discretos y continuos, cada uno escrito en MATLAB y en
Python, conectado a la toolbox GSUA-CSB:
- MATLAB: `gsua_dataprep`, función de usuario de 3 entradas, Kind 5.
- Python: `gsua_csb.UserFunctionModel`.

## Estructura

```
hands_on_epi/
  CONTRATO.md              este archivo
  datos/                   series reales (CSV) + datos/FUENTES.md (procedencia y licencia)
  modelos/catalogo_*.json  FUENTE ÚNICA de nombres, rangos, unidades y salidas de cada modelo
                           (una lista JSON por archivo: catalogo_humanos.json, catalogo_vectores.json;
                           los guiones leen todos los catalogo_*.json)
  matlab/modelos/<id>.m    un archivo por modelo
  python/modelos/<id>.py   un archivo por modelo (mismo <id>)
  matlab/handson.m         guion principal (selector de modelo y datos)
  python/handson.py (+ .ipynb)
  pruebas/                 pruebas de cada lenguaje + paridad MATLAB vs Python
```

## Firma de cada modelo

- **MATLAB:** `sol = <id>(pars, domain, opt)`
  - `pars` es un vector fila con el orden de `catalogo.json`; los parámetros van primero y
    después las condiciones iniciales, como esté declarado.
  - `domain = [t0 tf]`.
  - Devuelve `sol.x` (1×Nt, tiempos `t0:tf` con paso 1 en la unidad del modelo) y
    `sol.y` (Nsalidas×Nt).
  - En los continuos, `ode45` va dentro de la función y `deval` o la interpolación se evalúan en
    `t0:tf`, para que la salida tenga la misma rejilla que los discretos. `sol.solver = ''`.
- **Python:** `def <id>(pars, domain, **opt) -> np.ndarray` con forma `(Nsalidas, Nt)` y el mismo
  orden de filas. `gsua_csb` llama a la función con la rejilla de observación (`xdata`), así que
  `domain` puede ser `[t0, tf]` (se devuelve la rejilla entera `t0..tf`) o un vector de tiempos
  (se simula de `domain[0]` a `domain[-1]` y se devuelven exactamente esos puntos). Continuos con `scipy.integrate.solve_ivp(method="RK45",
  t_eval=...)` y tolerancias `rtol=1e-6, atol=1e-6` (iguales a las de MATLAB).
- **Filas de `sol.y`:** primero los estados del modelo, en el orden de `catalogo.json`; al final,
  las **salidas observables** (por ejemplo `casos_semanales`, `casos_acumulados`,
  `activos_detectados`). `catalogo.json` dice qué índice (base 1) corresponde a cada salida.
- **Incidencia (casos nuevos), convención hacia atrás:** `casos(t) = C(t) − C(t−1)`, es decir,
  las infecciones nuevas del paso que **termina** en `t`, igual que un reporte semanal. En `t0`,
  `casos(t0)` = infectados iniciales. En las EDO se agrega el estado acumulado `C' = incidencia`.
- **`opt`** solo lleva elecciones estructurales, nunca parámetros a estimar. Ejemplo:
  `opt.prob = 'exp' | 'G1' | 'G2' | 'G3'`, la función de probabilidad de contagio en
  los discretos, y `opt.N` si la población es fija.
- **Sin estado global y sin aleatoriedad:** dados `pars`, `domain` y `opt`, el resultado es
  determinista e idéntico en ambos lenguajes (tolerancia relativa 1e-8 en los discretos y 1e-4 en
  los continuos).

## Modelos

| id | Tipo | Estados | Fuente |
|---|---|---|---|
| `sir_continuo` | EDO | S, I, R | SIR clásico de Kermack–McKendrick |
| `sir_discreto` | Discreto | S, I, R | SIR con probabilidad de contagio seleccionable (`opt.prob`). Por omisión **`'exp'`**: P = 1 − exp(−β·I/N). Las demás opciones son G1/G2/G3 de Cataño-López et al. 2022 (ec. 3–5, con ℵ) |
| `sir_cuarentena_cl` | Discreto | Sf, Sq, If, Iq, Ij, R | Cataño-López et al. 2022, ec. (6)–(8), con contagio G̃1/G̃2/G̃3 (`opt.prob`). Salida: activos detectados Ij |
| `dengue_lizarralde` | EDO | Ms, Me, Mi, Hs, He, Hi, Hr | Lizarralde-Bejarano et al. 2020, PLOS ONE, **modelo (3)**, con reclutamiento constante Λ. Salidas: casos acumulados (θh·He integrado) y casos semanales |
| `dengue_cl_discreto` | Discreto | Sm, Im, Sh, Ih, Rh | Cataño-López et al. 2022, ec. (9)–(10). Ricker con retardo de 2 pasos; contagio G̃ con ℵ entre humanos y mosquitos. Salida: casos instantáneos (ec. 10) |

Referencias, verificadas en la biblioteca de Octopus:
- Cataño-López A, Rojas-Díaz D, Lizarralde DP, Puerta Yepes ME (2022). *Discrete Models in
  Epidemiology: New Contagion Probability Functions Based on Real Data Behavior*. Bull Math Biol
  84:127. doi:10.1007/s11538-022-01076-6
- Lizarralde-Bejarano DP, Rojas-Díaz D, Arboleda-Sánchez S, Puerta-Yepes ME (2020). *Sensitivity,
  uncertainty and identifiability analyses to define a dengue transmission model with real data
  of an endemic municipality of Colombia*. PLOS ONE. doi:10.1371/journal.pone.0229668

Código de referencia de los autores, solo para comparar y nunca para copiar sin entender:
- `D:\MATLAB Drive.source-of-truth-20260718T095207\CHIMERITApaper\Repository\Dengue\CHIMERA_Vector.m`
- `...\CHIMERITApaper\Repository\Covid19\CHIMERA_FQ.m`
- `C:\Users\Lanre\MATLAB Drive\PaperCSB\Repositorio\Dengue\Model.m` (Lizarralde en forma simbólica)

## `catalogo.json` (una entrada por modelo)

```json
{
  "id": "sir_discreto",
  "nombre": "SIR discreto (probabilidad de contagio exponencial)",
  "tipo": "discreto",
  "unidad_tiempo": "dia",
  "transmision": "humano-humano",
  "parametros": [
    {"id": "beta", "nombre": "β", "descripcion": "...", "rango": [0, 1], "unidad": "1/día"}
  ],
  "condiciones_iniciales": [ {"id": "I0", "rango": [1, 100]} ],
  "estados": ["S", "I", "R"],
  "salidas": [{"id": "activos", "fila": 2}, {"id": "casos_nuevos", "fila": 4}],
  "opt_defecto": {"prob": "exp", "N": 50000000},
  "fuente": "..."
}
```

Los rangos vienen de los papers (Tabla 1 de Lizarralde 2020; Tablas 1–3 de Cataño-López 2022) o
de los guiones de los autores, y cada uno cita de dónde sale.

## Pruebas obligatorias

1. Cada modelo, en cada lenguaje, corre con el nominal (punto medio de los rangos) sin NaN ni
   negativos, y conserva la población donde corresponde.
2. **Paridad:** `pruebas/paridad_<familia>.py` (`humanos`, `vectores`) corre los N=20 vectores de `pruebas/pars_paridad_<id>.csv` en
   Python y compara con `pruebas/salidas_matlab_<id>.csv`, que genera `pruebas/generar_paridad_<familia>.m`.
3. Cada modelo se construye con la toolbox (`gsua_dataprep` / `UserFunctionModel`) y un
   `gsua_pe` / `parameter_estimation` corto (N=2) termina sin error.
