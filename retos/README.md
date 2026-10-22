# Retos de identificabilidad

Cada reto es una competencia por equipos. La coordinación simula datos con un modelo, unos
parámetros **secretos** y ruido. Tu equipo recibe los datos y responde, para cada caso y cada
parámetro:

1. ¿Es **identificable** con estos datos?
2. ¿Cuál es su **estimación**?
3. ¿Cuál es su **intervalo de confianza**?

Gana quien mejor recupere la verdad **y** sea honesto sobre lo que no se puede recuperar.

## Archivos

| Archivo | Qué es |
|---|---|
| `reto_K/reto_K.json` | Enunciado: modelo, parámetros y rangos de búsqueda, casos (qué se observa, cuántos tiempos, cuánto ruido), nivel del intervalo y **sello SHA-256 de la verdad** |
| `reto_K/reto_K_datos.csv` | Los datos: `caso,t,salida,valor` |
| `reto_K/reto_K_datos.mat` | Los mismos datos para MATLAB: `casos.<id>.t`, `casos.<id>.y` (una columna por salida observada), `casos.<id>.observadas`, `rangos`, `parametros` |
| `reto_K/entrega_plantilla.json` | La plantilla de tu entrega |
| `modelos/` | Los modelos, en MATLAB y en Python |
| `llenar_entrega.m` / `.py`, `guardar_entrega.m` | Llenan la plantilla con lo que devuelve la toolbox |
| `calificar.m` / `.py` | El calificador. Es público desde el principio: así sabes exactamente cómo se te califica |

## La entrega

Un `entrega.json` por equipo. Por cada caso (`c1`, `c2`, …) y cada parámetro:

```json
"beta": {
  "estimacion": 0.351,
  "ic_inferior": 0.342,
  "ic_superior": 0.361,
  "identificable": true
}
```

y por cada caso un párrafo de `justificacion`: por qué decidiste lo que decidiste. Los
identificadores de los parámetros (`S0`, `beta`, …) son los de `reto_K.json`.

### Llenarla desde la toolbox

MATLAB (GSUA-CSB):

```matlab
addpath('retos')
E = jsondecode(fileread('retos/reto_2/entrega_plantilla.json'));
E.equipo = 'Los Gamma';  E.integrantes = {'Ana', 'Luis'};
% ... gsua_dataprep, gsua_pe, gsua_ia sobre el caso c4 ...
E = llenar_entrega(E, 'c4', CT_ia, 'umbral', 0.5, 'justificacion', '...');
% o con tus propias estimaciones repetidas (columnas) y tu propio veredicto:
E = llenar_entrega(E, 'c1', Est, 'identificable', [1 1 0 1 1 1]);
% o con intervalos de perfil de verosimilitud, del CSB o propios:
E = llenar_entrega(E, 'c2', struct('estimacion', x, 'ic_inferior', lo, 'ic_superior', hi, ...
                                   'identificable', id));
guardar_entrega(E, 'entrega_los_gamma.json')
```

Python (gsua_csb):

```python
import sys; sys.path.insert(0, "retos")
from llenar_entrega import leer_entrega, llenar_entrega, guardar_entrega
E = leer_entrega("retos/reto_2/entrega_plantilla.json")
E["equipo"] = "Los Gamma"
llenar_entrega(E, "c4", ia, umbral=0.5, justificacion="...")       # ia = identifiability_analysis(...)
llenar_entrega(E, "c1", est, identificable=[1, 1, 0, 1, 1, 1])     # est: N x Np
guardar_entrega(E, "entrega_los_gamma.json")
```

Con `gsua_ia`, el veredicto automático es `index < umbral`; puedes reemplazarlo con
`identificable`. **La decisión es tuya**, y también lo es qué intervalo reportas. Ten en cuenta
que `gsua_ia` resume el conjunto de estimaciones que le pases, y que su `Range` es, según su
ayuda, un intervalo de confianza para la **mediana** de ese conjunto.

## Cómo se califica

Para cada caso y parámetro, con verdad $x$, intervalo $[l, u]$, ancho del rango de búsqueda $W$
y $\alpha = 1 - \text{nivel}$ (con nivel 0.95, $\alpha = 0.05$):

1. **Puntaje de intervalo** (Gneiting y Raftery, 2007), dividido por $W$ para poder sumar
   parámetros de escalas distintas:

   $$IS = (u - l) + \tfrac{2}{\alpha}(l - x)\,[x < l] + \tfrac{2}{\alpha}(x - u)\,[x > u]$$

   Es una regla de puntuación *propia*: a la larga, lo que más conviene es reportar tu intervalo
   honesto. Uno estrecho que contiene la verdad cuesta poco. Uno que no la contiene paga
   $2/\alpha = 40$ veces la distancia que le faltó. Un intervalo ausente o inválido cuenta como
   todo el rango ("no sé").

2. **Veredicto de identificabilidad:**

   | Tu respuesta | Penalización |
   |---|---:|
   | Acertaste | 0 |
   | Dijiste "no" y sí lo era (o no respondiste) | 1 |
   | Dijiste "sí" y no lo era, pero tu intervalo contiene la verdad | 2 |
   | Dijiste "sí" y no lo era, **y tu intervalo no contiene la verdad** | **5** |

3. **Penalización total** = suma de $IS/W$ + veredicto, sobre todos los casos y parámetros.
   **Gana la menor.** Desempate: el error relativo medio $|\hat x - x|/W$ en los parámetros que
   sí son identificables.

La tabla de posiciones también muestra los **aciertos** de identificabilidad y la **cobertura**
(fracción de intervalos que contienen la verdad).

## El sello SHA-256

Al lanzar el reto se publica la huella SHA-256 del archivo con la verdad (`sha256_verdad` en
`reto_K.json` y en el sitio del semillero). Cuando se revela la verdad, cualquiera puede
comprobar que es la misma:

```bash
sha256sum reto_2_verdad.json
```

(en Windows, `Get-FileHash reto_2_verdad.json`). El calificador lo comprueba antes de calificar y
se niega a hacerlo si no coincide.

Para calificar tú mismo, una vez revelada la verdad:

```bash
python retos/calificar.py retos/reto_2 --verdad reto_2_verdad.json --entregas CARPETA
```

o, en MATLAB, `calificar('retos/reto_2', 'reto_2_verdad.json', 'CARPETA')`. Ambos dan
exactamente los mismos números.
