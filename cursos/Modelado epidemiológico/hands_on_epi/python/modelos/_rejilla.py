"""Utilidades comunes de los modelos humano-humano: interpretación de ``domain``.

``domain`` puede ser:
- un par ``[t0, tf]`` -> la salida usa la rejilla entera t0, t0+1, ..., tf;
- un vector de tiempos de observación (más de 2 elementos), como el que pasa
  ``gsua_csb.UserFunctionModel`` -> se simula de domain[0] a domain[-1] y la salida
  se entrega exactamente en esos tiempos.

Nota: un vector de exactamente 2 elementos se interpreta siempre como ``[t0, tf]``.
"""
import numpy as np


def puntos_salida(domain):
    """Devuelve (t0, tf, puntos) con los tiempos en que se entrega la salida."""
    d = np.atleast_1d(np.asarray(domain, dtype=float)).ravel()
    t0, tf = float(d[0]), float(d[-1])
    if d.size <= 2:
        puntos = np.arange(t0, tf + 1.0)
    else:
        puntos = d
    return t0, tf, puntos


def indices_discretos(t0, puntos):
    """Índices enteros (contados desde t0) de los puntos en un modelo de paso 1."""
    idx = np.rint(puntos - t0).astype(int)
    if np.any(np.abs(puntos - t0 - idx) > 1e-9):
        raise ValueError("En los modelos discretos los tiempos de salida deben ser enteros.")
    return idx
