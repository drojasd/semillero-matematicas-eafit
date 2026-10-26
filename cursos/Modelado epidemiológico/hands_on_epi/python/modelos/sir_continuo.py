"""SIR clásico de Kermack-McKendrick (EDO), población fija N.

Gemelo de ``matlab/modelos/sir_continuo.m``.

pars = [beta, gamma, I0, R0]
    beta  tasa de contagio (1/día), gamma tasa de recuperación (1/día),
    I0, R0 condiciones iniciales (personas); S0 = N - I0 - R0.

    S' = -beta*S*I/N,  I' = beta*S*I/N - gamma*I,  R' = gamma*I,
    C' =  beta*S*I/N   (estado auxiliar: infecciones acumuladas)

Filas de la salida: 1 S, 2 I, 3 R, 4 activos (= I),
5 casos_nuevos (convención hacia atrás: C(t) - C(t-1), infecciones nuevas en el paso
que TERMINA en t; en t0 vale I0, los infectados iniciales).
opt: N (5e7 por omisión).
"""
import numpy as np
from scipy.integrate import solve_ivp

try:
    from ._rejilla import puntos_salida
except ImportError:  # importado como módulo suelto
    from _rejilla import puntos_salida


def sir_continuo(pars, domain, **opt):
    N = float(opt.get("N", 5e7))
    p = np.asarray(pars, dtype=float).ravel()
    if p.size != 4:
        raise ValueError(f"sir_continuo espera 4 valores [beta gamma I0 R0]; llegaron {p.size}.")
    beta, gamma, I0, R0 = p
    t0, tf, puntos = puntos_salida(domain)

    def f(_t, x):
        inc = beta * x[0] * x[1] / N
        return [-inc, inc - gamma * x[1], gamma * x[1], inc]

    # Se evalúa en los puntos y en puntos-1 (incidencia del paso que termina en t).
    previos = puntos[puntos - 1.0 >= t0 - 1e-12] - 1.0
    t_eval = np.unique(np.concatenate([puntos, previos]))
    if tf > t0:
        sol = solve_ivp(f, (t0, tf), [N - I0 - R0, I0, R0, 0.0], method="RK45",
                        t_eval=t_eval, rtol=1e-6, atol=1e-6)
        if not sol.success:
            raise RuntimeError(f"solve_ivp falló: {sol.message}")
        X = sol.y
    else:
        X = np.array([[N - I0 - R0], [I0], [R0], [0.0]])
    i0 = np.searchsorted(t_eval, puntos)
    casos = np.full(puntos.shape, float(I0))
    hay_previo = puntos - 1.0 >= t0 - 1e-12
    i_prev = np.searchsorted(t_eval, puntos[hay_previo] - 1.0)
    casos[hay_previo] = X[3, i0[hay_previo]] - X[3, i_prev]
    return np.vstack([X[0:3, i0], X[1, i0], casos])
