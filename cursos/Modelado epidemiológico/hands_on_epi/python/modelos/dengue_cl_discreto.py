"""Modelo discreto vector-huésped de Cataño-López et al. 2022 (Bull Math Biol 84:127), ec. (9)-(10).

Paso semanal. Implementación equivalente a ``CHIMERA_Vector.m`` de los autores y a
``matlab/modelos/dengue_cl_discreto.m`` (ver allí la descripción completa de las ecuaciones).

pars = [gamma, mu_m, z, r, C, beta_mh, beta_hm, nu_m, nu_h, Hs0, Hi0, Hr0, Ms0, Mi0]
opt:   mu_h (natalidad = mortalidad humana por semana; 0 por omisión).

Filas de la salida (base 0 en Python; el catálogo usa base 1):
    0 Sm, 1 Im, 2 Sh, 3 Ih, 4 Rh, 5 casos_semanales (Ih_ins), 6 casos_acumulados
"""

from __future__ import annotations

import numpy as np

NPARS = 14


def _rejilla(domain):
    """Devuelve (t0, tf, puntos). ``domain`` es [t0, tf] o un vector de tiempos enteros."""
    d = np.atleast_1d(np.asarray(domain, dtype=float)).ravel()
    if d.size == 1:
        d = np.array([d[0], d[0]])
    if d.size == 2:
        t0, tf = int(round(d[0])), int(round(d[1]))
        return t0, tf, np.arange(t0, tf + 1)
    puntos = np.rint(d).astype(int)
    return int(puntos[0]), int(puntos[-1]), puntos


def dengue_cl_discreto(pars, domain, **opt) -> np.ndarray:
    """Simula el modelo; devuelve un arreglo (7, Nt) en la rejilla pedida.

    ``domain`` puede ser [t0, tf] (se devuelve la rejilla entera t0..tf) o un vector de tiempos
    enteros crecientes (se simula de domain[0] a domain[-1] y se devuelven esos puntos).
    """
    mu_h = float(opt.get("mu_h", 0.0))
    p = np.asarray(pars, dtype=float).ravel()
    if p.size != NPARS:
        raise ValueError(
            f"dengue_cl_discreto espera {NPARS} valores (9 parámetros + 5 condiciones iniciales); "
            f"llegaron {p.size}."
        )
    gamma, mu_m, z, r, C, beta_mh, beta_hm, nu_m, nu_h = p[:9]
    Hs0, Hi0, Hr0, Ms0, Mi0 = p[9:]

    t0, tf, puntos = _rejilla(domain)
    nt = tf - t0 + 1
    Y = np.zeros((7, nt))
    Y[:, 0] = [Ms0, Mi0, Hs0, Hi0, Hr0, Hi0, Hi0]
    NM = np.zeros(nt)

    for k in range(nt - 1):
        Sm, Im, Sh, Ih, Rh = Y[:5, k]
        NH = Sh + Ih + Rh
        NM[k] = Sm + Im

        alephH = 1.0 + nu_h * Ih / (Sh + Ih) if Sh + Ih > 0 else 1.0
        alephM = 1.0 + nu_m * Im / (Sm + Im) if Sm + Im > 0 else 1.0

        psi = beta_hm * (1.0 - (1.0 - (Ih / NH) ** alephM) ** z)
        if Sh >= 1:
            phi = beta_mh * (1.0 - (1.0 - 1.0 / Sh) ** (z * Im * (Sh / NH) ** alephH))
        else:
            phi = 0.0

        # Ricker con retardo de 2 pasos; en los dos primeros pasos se usa N_M(t0) (código de los autores).
        if k >= 2:
            A = r * NM[k - 2] * np.exp(1.0 - NM[k] / C)
        else:
            A = r * NM[0] * np.exp(1.0 - NM[0] / C)

        nuevos = Sh * phi * (1.0 - mu_h)
        Y[0, k + 1] = Sm * (1.0 - psi) * (1.0 - mu_m) + A
        Y[1, k + 1] = Sm * psi * (1.0 - mu_m) + Im * (1.0 - mu_m)
        Y[2, k + 1] = Sh * (1.0 - phi) * (1.0 - mu_h) + NH * mu_h
        Y[3, k + 1] = nuevos + Ih * (1.0 - gamma) * (1.0 - mu_h)
        Y[4, k + 1] = Rh * (1.0 - mu_h) + Ih * gamma * (1.0 - mu_h)
        Y[5, k + 1] = nuevos
        Y[6, k + 1] = Y[6, k] + nuevos

    return Y[:, puntos - t0]
