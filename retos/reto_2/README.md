# Reto R2 · SIR discreto con pérdida de inmunidad

Es el [hands-on SIR](../../cursos/Modelado%20epidemiológico/HandsOn_SIR/README.md) convertido
en competencia. Reglas generales y calificación: [`../README.md`](../README.md).

## El modelo

`SIRSemilleroSV` (en `../modelos/`, también en Python: `sir_semillero_sv.py`). Población
`N = S + I + R` constante:

```
S(k+1) = S(k)·(1 − β·I(k)/N) + α·R(k)
I(k+1) = S(k)·β·I(k)/N + (1−γ)·I(k)
R(k+1) = (1−α)·R(k) + γ·I(k)
```

Seis factores por caso: `S0, I0, R0, beta, gamma, alpha`. Los rangos de búsqueda están en
`reto_2.json` y contienen la verdad.

## Los datos

Seis curvas, `t = 0, 1, …, 100`, con ruido multiplicativo gaussiano:

| Caso | Se observa | Ruido |
|:---:|:---:|:---:|
| c1, c2, c3 | solo I | 2 %, 5 %, 10 % |
| c4, c5, c6 | S e I | 2 %, 5 %, 8 % |

Cada caso tiene sus propios parámetros. Solo recibes las salidas observadas.

## Lo que entregas

`entrega_plantilla.json` llena (36 parámetros: 6 casos × 6 factores), con una justificación por
caso. Preguntas que vale la pena discutir en el equipo:

- ¿Qué parámetros recuperaste con un intervalo estrecho? ¿Cuáles no? ¿Por qué?
- ¿Hay pares de parámetros que se compensan entre sí?
- ¿Cambia tu respuesta si observas S además de I? ¿Y con más ruido?
- Un buen ajuste, ¿garantiza que los parámetros estimados son los verdaderos?
