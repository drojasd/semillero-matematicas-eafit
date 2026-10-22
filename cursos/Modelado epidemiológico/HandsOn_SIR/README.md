# Hands-on SIR: estimación de parámetros e identificabilidad

Sesión práctica del Semillero de Matemáticas con la toolbox **GSUA-CSB**.
Recibes datos de una epidemia simulada con un modelo SIR de tiempo discreto y con ruido.
Tu tarea: **estimar sus parámetros** y decidir **cuáles son identificables**. Al final de la
sesión se revelan los valores con los que se generaron los datos.

## Archivos

- `SIRSemilleroSV.m`: el modelo (SIR discreto sin vacunación).
- `datos_semillero_SIR.mat`: los datos con ruido.
- `plantilla_estudiante.m` / `plantilla_estudiante.mlx`: guion paso a paso del ejercicio.
- `PlantillaInicio.mlx`: plantilla de arranque.

## El modelo

Población `N = S + I + R` constante (sin nacimientos ni muertes):

```
S(k+1) = S(k)·(1 − β·I(k)/N) + α·R(k)
I(k+1) = S(k)·β·I(k)/N + (1−γ)·I(k)
R(k+1) = (1−α)·R(k) + γ·I(k)
```

Parámetros a estimar: `S(0), I(0), R(0), β, γ, α`. Con `α = 0` es el SIR clásico.
`α > 0` añade pérdida de inmunidad (R → S).

## Los datos

`states_export(curva, tiempo, salida)`, con salidas `1=S, 2=I, 3=R` y `xdata = 0:100`.
Hay seis curvas con ruido multiplicativo:

| Curva | Qué se ajusta | `num_outs` | Ruido |
|:---:|:---:|:---:|:---:|
| 1, 2, 3 | **solo I** | `2` | 2 %, 5 %, 10 % |
| 4, 5, 6 | **S e I** (multiobjetivo) | `[1 2]` | 2 %, 5 %, 8 % |

## Flujo con la toolbox

1. `gsua_dataprep`: conectar el modelo con rangos y nombres.
2. Cargar `datos_semillero_SIR.mat` y visualizar la curva elegida.
3. `gsua_dmatrix` + `gsua_eval`: comprobar que el modelo puede reproducir los datos.
4. `gsua_pe`: estimar (varias corridas con `fmincon`).
5. Quedarse con las estimaciones del mismo mínimo.
6. `gsua_ia`: **análisis de identificabilidad** (intervalos, correlaciones, índice).
7. `gsua_dmatrix` + `gsua_eval`: ¿los intervalos reproducen los datos?

## Preguntas para tu equipo

- ¿Qué parámetros recuperaste con un intervalo estrecho? ¿Cuáles no?
- ¿Hay pares de parámetros muy correlacionados? ¿Qué significa eso?
- ¿Cambia tu respuesta si en lugar de solo I observas también S?
- ¿Qué pasa con más ruido?
- Un buen ajuste, ¿garantiza que los parámetros estimados son los verdaderos?
