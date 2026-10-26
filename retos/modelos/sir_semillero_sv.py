"""SIR de tiempo discreto sin vacunación, con pérdida de inmunidad (espejo de SIRSemilleroSV.m).

    pars = [S0, I0, R0, beta, gamma, alpha]

    P(k)   = 1 - exp(-beta*I(k)/N)      (probabilidad de contagio, calculada con -expm1)
    S(k+1) = S(k)*(1 - P(k)) + alpha*R(k)
    I(k+1) = S(k)*P(k) + (1-gamma)*I(k)
    R(k+1) = (1-alpha)*R(k) + gamma*I(k)

Con alpha = 0 es el SIR clásico. N = S+I+R se conserva.
"""
from __future__ import annotations

import numpy as np

SALIDAS = ["S", "I", "R"]


def sir_semillero_sv(pars, tiempos, **_):
    """Devuelve una matriz 3 x len(tiempos) con las filas [S; I; R].

    `tiempos` son enteros; la simulación arranca en tiempos[0] con las condiciones iniciales.
    La firma func(pars, tiempos) es la que espera gsua_csb.UserFunctionModel(domain=tiempos).
    """
    tiempos = np.asarray(tiempos, dtype=float)
    t0, tf = int(round(tiempos[0])), int(round(tiempos[-1]))
    s, i, r, beta, gamma, alpha = (float(p) for p in pars)
    m = np.zeros((3, tf - t0 + 1))
    m[:, 0] = (s, i, r)
    for k in range(tf - t0):
        s, i, r = m[:, k]
        n = s + i + r
        prob = -np.expm1(-beta * i / n)  # P(k) = 1 - exp(-beta*I(k)/N)
        m[0, k + 1] = s * (1 - prob) + alpha * r
        m[1, k + 1] = s * prob + (1 - gamma) * i
        m[2, k + 1] = (1 - alpha) * r + gamma * i
    return m[:, np.round(tiempos).astype(int) - t0]
