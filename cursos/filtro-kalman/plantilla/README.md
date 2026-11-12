# Plantilla: filtro de Kalman extendido con estado aumentado

Plantilla mínima, en MATLAB y en Python, para aplicar un filtro de Kalman extendido (EKF) a un
modelo no lineal propio y estimar a la vez sus estados y al menos un parámetro. Calcula también
el número de condición de la matriz de observabilidad local. Las dos versiones hacen lo mismo y
dan los mismos números (diferencias del orden de 1e-10).

Corre de principio a fin con un ejemplo: un SIR continuo normalizado, muestreado cada día, en el
que solo se mide la fracción de infectados `i` con ruido y el filtro estima `s`, `i` y la tasa de
transmisión `beta` (partiendo de 0.45; el valor verdadero es 0.5).

## Qué hay que cambiar

En el live script (`matlab/plantilla_ekf_live.m`) o en el notebook (`python/plantilla_ekf.ipynb`),
solo las secciones marcadas con **CAMBIAR**:

1. **Modelo**: el lado derecho `g(x,p)` si el modelo es continuo (se integra con Runge-Kutta 4
   entre muestras) o el paso `x(k+1) = f(x(k),p)` si es discreto, y la medición `h(x,p)`.
2. **Parámetros**: los estimados en la entrega 2 y sus intervalos del bootstrap, y cuáles estima
   el filtro (`idx`, al menos uno).
3. **Datos**: un CSV con columnas `t` y `y` (y los estados verdaderos, si los datos son sintéticos).
4. **Configuración**: `R` (de los residuales de la entrega 2), `P(0)` y `Q`.

Los jacobianos se calculan por diferencias finitas, así que no hay que derivar a mano.

## Archivos

| MATLAB | Python | Qué hace |
| --- | --- | --- |
| `plantilla_ekf_live.m` | `plantilla_ekf.ipynb` | La plantilla, sección por sección |
| `ekfCorrer.m` | `ekf_correr` | El filtro sobre toda la serie (predicción y corrección) |
| `jacobianoNum.m` | `jacobiano_num` | Jacobiano por diferencias centrales |
| `pasoRK4.m` | `paso_rk4` | Un periodo de muestreo de un modelo continuo |
| `condObservabilidad.m` | `cond_observabilidad` | Rango y número de condición de la observabilidad local |
| `autocorrInnov.m` | `autocorr_innov` | Prueba de blancura de las innovaciones |
| `generar_ejemplo.m` | | Genera `ejemplo_datos.csv` (no hace falta correrlo) |

Las funciones de Python están en `python/ekf_plantilla.py` y solo usan NumPy; el notebook usa
además pandas y matplotlib. El live script requiere MATLAB R2025a o posterior (formato de texto
plano); las funciones sirven en cualquier versión reciente.

Material de la clase: la [presentación interactiva](https://drojasd.github.io/semillero-matematicas-eafit/cursos/filtro-kalman/presentacion.html)
y el [ejemplo del SIRS discreto](https://github.com/drojasd/semillero-matematicas-eafit/tree/main/cursos/filtro-kalman/matlab).
