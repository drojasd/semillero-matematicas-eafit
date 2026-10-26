"""Modelo (3) de Lizarralde-Bejarano et al. 2020 (PLOS ONE), EDO, tiempo en semanas.

Equivalente a ``matlab/modelos/dengue_lizarralde.m`` (ver allí las ecuaciones).

pars = [Lambda, mu_m, beta_h, beta_m, theta_m, theta_h, gamma_h, Ms0, Me0, Mi0, Hs0, He0, Hi0, Hr0]
opt:   mu_h (natalidad = mortalidad humana por semana; 0.0004 por omisión, Tabla 1).

Filas de la salida (base 0 en Python; el catálogo usa base 1):
    0 Ms, 1 Me, 2 Mi, 3 Hs, 4 He, 5 Hi, 6 Hr,
    7 casos_semanales  (C(t) - C(t-1); en t0 vale Hi0),
    8 casos_acumulados (C, con C(t0) = Hi0 y C' = theta_h*He)

solve_ivp(method="RK45", rtol=1e-6, atol=1e-6), evaluado en la rejilla pedida.
"""

from __future__ import annotations

import numpy as np
from scipy.integrate import solve_ivp

NPARS = 14


def _campo(t, x, Lambda, mu_m, beta_h, beta_m, theta_m, theta_h, gamma_h, mu_h):
    """Lado derecho del modelo (3) más el estado auxiliar C."""
    Ms, Me, Mi, Hs, He, Hi, Hr, _ = x
    M = Ms + Me + Mi
    H = Hs + He + Hi + Hr
    fm = Mi / M if M > 0 else 0.0
    fh = Hi / H if H > 0 else 0.0
    return [
        Lambda - beta_m * fh * Ms - mu_m * Ms,
        beta_m * fh * Ms - (theta_m + mu_m) * Me,
        theta_m * Me - mu_m * Mi,
        mu_h * H - beta_h * fm * Hs - mu_h * Hs,
        beta_h * fm * Hs - (theta_h + mu_h) * He,
        theta_h * He - (gamma_h + mu_h) * Hi,
        gamma_h * Hi - mu_h * Hr,
        theta_h * He,
    ]


def dengue_lizarralde(pars, domain, **opt) -> np.ndarray:
    """Simula el modelo; devuelve un arreglo (9, Nt).

    ``domain`` puede ser [t0, tf] (se devuelve la rejilla entera t0..tf) o un vector de tiempos
    crecientes (se integra de domain[0] a domain[-1] y se devuelven esos puntos; los casos
    semanales en un punto t son C(t) - C(t-1), y en domain[0] valen Hi0).
    """
    mu_h = float(opt.get("mu_h", 0.0004))
    p = np.asarray(pars, dtype=float).ravel()
    if p.size != NPARS:
        raise ValueError(
            f"dengue_lizarralde espera {NPARS} valores (7 parámetros + 7 condiciones iniciales); "
            f"llegaron {p.size}."
        )
    args = tuple(p[:7]) + (mu_h,)
    x0 = np.concatenate([p[7:14], [p[12]]])  # C(t0) = Hi0

    d = np.atleast_1d(np.asarray(domain, dtype=float)).ravel()
    if d.size == 1:
        d = np.array([d[0], d[0]])
    if d.size == 2:
        puntos = np.arange(d[0], d[1] + 1.0)
    else:
        puntos = d
    t0, tf = float(puntos[0]), float(puntos[-1])

    # Se evalúa también en t-1 para poder calcular los casos semanales en cada punto.
    previos = puntos[1:] - 1.0
    teval = np.unique(np.concatenate([puntos, previos[previos >= t0]]))

    if tf > t0:
        s = solve_ivp(_campo, (t0, tf), x0, method="RK45", t_eval=teval,
                      rtol=1e-6, atol=1e-6, args=args)
        if not s.success:
            raise RuntimeError(f"dengue_lizarralde: solve_ivp falló: {s.message}")
        X = s.y
    else:
        X = x0[:, None]
        teval = np.array([t0])

    idx = np.searchsorted(teval, puntos)
    C = X[7]
    semanales = np.empty(puntos.size)
    semanales[0] = C[idx[0]]
    if puntos.size > 1:
        semanales[1:] = C[idx[1:]] - C[np.searchsorted(teval, previos)]
    return np.vstack([X[:7, idx], semanales, C[idx]])
