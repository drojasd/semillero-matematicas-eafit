"""SIR en tiempo discreto (paso de 1 día) con probabilidad de contagio seleccionable.

Gemelo de ``matlab/modelos/sir_discreto.m``.

    S(t+1) = S(t)(1 - P(t))
    I(t+1) = I(t) + S(t)P(t) - gamma*I(t)
    R(t+1) = R(t) + gamma*I(t)

opt["prob"] (define también qué parámetros lleva ``pars``):
    'exp' (por omisión)  P = 1 - exp(-beta I/N)         pars = [beta, gamma, I0, R0]
    'G1'  P = beta*(1 - (1 - 1/S)^(z I (S/N)^aleph))    pars = [beta, gamma, nu, z, I0, R0]
    'G2'  P = beta*(1 - (1 - (I/N)^aleph)^z)            pars = [beta, gamma, nu, z, I0, R0]
    'G3'  P = beta*(I/N)^aleph                          pars = [beta, gamma, nu, I0, R0]
con aleph = 1 + nu I/(S+I) (Cataño-López et al. 2022, ec. 3-5). opt["N"]: 5e7 por omisión.

Filas: 1 S, 2 I, 3 R, 4 activos (= I), 5 casos_nuevos (convención hacia atrás:
S(t-1)P(t-1), contagios en el paso que TERMINA en t; en t0 vale I0).
"""
import math

import numpy as np

try:
    from ._rejilla import puntos_salida, indices_discretos
except ImportError:  # importado como módulo suelto
    from _rejilla import puntos_salida, indices_discretos

_ESPERADO = {
    "exp": (4, "[beta gamma I0 R0]"),
    "G1": (6, "[beta gamma nu z I0 R0]"),
    "G2": (6, "[beta gamma nu z I0 R0]"),
    "G3": (5, "[beta gamma nu I0 R0]"),
}


def _prob_contagio(prob, S, I, N, beta, nu, z):
    """Probabilidad de que un susceptible se contagie en un paso de tiempo."""
    if prob == "exp":
        return -math.expm1(-beta * I / N)
    aleph = 1.0 + nu * I / (S + I) if S + I > 0 else 1.0
    if prob == "G1":
        # 1 - (1 - 1/S)^x escrito con log1p/expm1 para no perder precisión.
        if S > 1:
            x = z * I * (S / N) ** aleph
            G = -math.expm1(x * math.log1p(-1.0 / S))
        else:
            G = 0.0
    elif prob == "G2":
        q = (I / N) ** aleph
        G = -math.expm1(z * math.log1p(-q)) if q < 1 else 1.0
    else:  # G3
        G = (I / N) ** aleph
    return beta * G


def sir_discreto(pars, domain, **opt):
    N = float(opt.get("N", 5e7))
    prob = str(opt.get("prob", "exp"))
    if prob not in _ESPERADO:
        raise ValueError(f"opt.prob desconocido: {prob} (use exp, G1, G2 o G3).")
    p = [float(v) for v in np.asarray(pars, dtype=float).ravel()]
    esperado, nombres = _ESPERADO[prob]
    if len(p) != esperado:
        raise ValueError(f"Con prob='{prob}' se esperan {esperado} valores {nombres}; llegaron {len(p)}.")
    beta, gamma = p[0], p[1]
    nu = z = 0.0
    if prob in ("G1", "G2"):
        nu, z = p[2], p[3]
    elif prob == "G3":
        nu = p[2]
    I0, R0 = p[-2], p[-1]

    t0, tf, puntos = puntos_salida(domain)
    t0r, tfr = round(t0), round(tf)
    Nt = tfr - t0r + 1
    Y = np.zeros((5, Nt))
    S, I, R = N - I0 - R0, I0, R0
    nuevos = I0  # casos_nuevos(t0) = infectados iniciales
    for k in range(Nt):
        Y[:, k] = (S, I, R, I, nuevos)
        if k < Nt - 1:
            P = _prob_contagio(prob, S, I, N, beta, nu, z)
            nuevos = S * P
            S, I, R = S - nuevos, I + nuevos - gamma * I, R + gamma * I
    return Y[:, indices_discretos(t0r, puntos)]
