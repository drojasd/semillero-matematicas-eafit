"""Modelo discreto con cuarentena y detección de Cataño-López et al. 2022
(Bull Math Biol 84:127), ec. (6)-(8). Paso de 1 día.

Gemelo de ``matlab/modelos/sir_cuarentena_cl.m`` (allí están las ecuaciones completas).

Estados: Sf, Sq, If, Iq, Ij, R. Contagio G~ sobre (Sf, If, N), opt["prob"]:
    'G1' (por omisión) 1 - (1 - 1/Sf)^(z If (Sf/N)^aleph)
    'G2'               1 - (1 - (If/N)^aleph)^z
    'G3'               (If/N)^aleph
aleph = 1 + nu If/(If+Sf) (artículo; opt["aleph"]='articulo', por omisión) o
1 + nu (If+Iq+Ij)/(Sf+If+Iq+Ij) (opt["aleph"]='autores', como CHIMERA_FQ.m).

pars (orden de CHIMERA_FQ.m, sin los parámetros que la opción no usa):
    'G1','G2': [lambda alpha mu theta gamma nu z beta If0 Ij0]
    'G3'     : [lambda alpha mu theta gamma nu beta If0 Ij0]
Sf0 = N - If0 - Ij0, Sq0 = Iq0 = R0 = 0; opt["N"]: 5e7 por omisión.

Filas: 1 Sf, 2 Sq, 3 If, 4 Iq, 5 Ij, 6 R, 7 activos_detectados (= Ij),
8 casos_nuevos_detectados (convención hacia atrás: theta(1-gamma)(If+Iq) evaluado en t-1,
detecciones en el paso que TERMINA en t; en t0 vale Ij0).
"""
import math

import numpy as np

try:
    from ._rejilla import puntos_salida, indices_discretos
except ImportError:  # importado como módulo suelto
    from _rejilla import puntos_salida, indices_discretos

_ESPERADO = {
    "G1": (10, "[lambda alpha mu theta gamma nu z beta If0 Ij0]"),
    "G2": (10, "[lambda alpha mu theta gamma nu z beta If0 Ij0]"),
    "G3": (9, "[lambda alpha mu theta gamma nu beta If0 Ij0]"),
}


def sir_cuarentena_cl(pars, domain, **opt):
    N = float(opt.get("N", 5e7))
    prob = str(opt.get("prob", "G1"))
    modo = str(opt.get("aleph", "articulo"))
    if prob not in _ESPERADO:
        raise ValueError(f"opt.prob desconocido: {prob} (use G1, G2 o G3).")
    if modo not in ("articulo", "autores"):
        raise ValueError(f"opt.aleph desconocido: {modo} (use articulo o autores).")
    p = [float(v) for v in np.asarray(pars, dtype=float).ravel()]
    esperado, nombres = _ESPERADO[prob]
    if len(p) != esperado:
        raise ValueError(f"Con prob='{prob}' se esperan {esperado} valores {nombres}; llegaron {len(p)}.")
    lam, alpha, mu, theta, gamma = p[:5]
    nu = z = 0.0
    if prob in ("G1", "G2"):
        nu, z, beta = p[5], p[6], p[7]
    else:  # G3
        nu, beta = p[5], p[6]
    If0, Ij0 = p[-2], p[-1]

    t0, tf, puntos = puntos_salida(domain)
    t0r, tfr = round(t0), round(tf)
    Nt = tfr - t0r + 1
    Y = np.zeros((8, Nt))
    Sf, Sq, If, Iq, Ij, R = N - If0 - Ij0, 0.0, If0, 0.0, Ij0, 0.0
    nuevos_det = Ij0  # casos_nuevos_detectados(t0) = detectados iniciales
    for k in range(Nt):
        Y[:, k] = (Sf, Sq, If, Iq, Ij, R, Ij, nuevos_det)
        if k == Nt - 1:
            break
        if modo == "articulo":
            den, num = Sf + If, If
        else:
            den, num = Sf + If + Iq + Ij, If + Iq + Ij
        aleph = 1.0 + nu * num / den if den > 0 else 1.0
        if prob == "G1":
            if Sf > 1:
                G = -math.expm1(z * If * (Sf / N) ** aleph * math.log1p(-1.0 / Sf))
            else:
                G = 0.0
        elif prob == "G2":
            q = (If / N) ** aleph
            G = -math.expm1(z * math.log1p(-q)) if q < 1 else 1.0
        else:  # G3
            G = (If / N) ** aleph
        P = beta * G
        sl, nd = 1 - gamma, 1 - theta  # sobrevive a la recuperación / no detectado
        nuevos_det = (If + Iq) * sl * theta
        Sf, Sq, If, Iq, Ij, R = (
            Sf * (1 - P) * (1 - lam) + Sq * alpha + mu * R,
            Sf * (1 - P) * lam + Sq * (1 - alpha),
            Sf * P + If * sl * nd * (1 - lam) + Iq * sl * nd * alpha,
            If * sl * nd * lam + Iq * sl * nd * (1 - alpha),
            (If + Iq) * sl * theta + Ij * sl,
            R * (1 - mu) + gamma * (If + Iq + Ij),
        )
    return Y[:, indices_discretos(t0r, puntos)]
