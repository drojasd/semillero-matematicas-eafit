"""Llena la entrega de un reto a partir de lo que devuelve gsua_csb (espejo de llenar_entrega.m).

    from llenar_entrega import leer_entrega, llenar_entrega, guardar_entrega
    E = leer_entrega("reto_2/entrega_plantilla.json")
    boot = ...  # B x Np: re-ajustes de B réplicas del ruido (como en course/05)
    ia = gsua_csb.identifiability_analysis(modelo, boot)
    llenar_entrega(E, "c4", boot, identificable=ia.index < 0.5,
                   justificacion="R(0) se va al borde del rango...")
    guardar_entrega(E, "entrega_mi_equipo.json")

`resultado` puede ser:
- un IdentifiabilityResult (gsua_ia): usa nominal, range e index; identificable = index < umbral
  (ojo: range es el IC de la MEDIANA del ensamble que recibió, no un intervalo para el parámetro);
- un PEResult (gsua_pe) o una matriz N x Np de estimaciones: estimación = mediana, intervalo =
  cuantiles (1-nivel)/2 y (1+nivel)/2; el veredicto hay que darlo con `identificable=`;
- un dict con listas estimacion, ic_inferior, ic_superior (y opcional identificable), para
  intervalos de perfil de verosimilitud, del CSB o propios.
Las filas van en el orden de los parámetros de la plantilla.
"""
from __future__ import annotations

import json
import sys
import warnings
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from comun import escribir_json  # noqa: E402


def leer_entrega(ruta) -> dict:
    return json.loads(Path(ruta).read_text(encoding="utf-8"))


def llenar_entrega(entrega, caso, resultado, umbral=0.5, identificable=None, nivel=0.95,
                   justificacion=None, equipo=None, integrantes=None) -> dict:
    if isinstance(entrega, (str, Path)):
        entrega = leer_entrega(entrega)
    if caso not in entrega["casos"]:
        raise KeyError(f"La entrega no tiene el caso {caso}")
    pars = entrega["casos"][caso]["parametros"]
    ids = list(pars)

    ident = None
    if hasattr(resultado, "index") and hasattr(resultado, "nominal"):  # IdentifiabilityResult
        est = np.asarray(resultado.nominal, float)
        rango = np.asarray(resultado.range, float)
        lo, hi = rango[:, 0], rango[:, 1]
        ident = np.asarray(resultado.index, float) < umbral
    elif isinstance(resultado, dict):
        est = np.asarray(resultado["estimacion"], float)
        lo = np.asarray(resultado["ic_inferior"], float)
        hi = np.asarray(resultado["ic_superior"], float)
        if resultado.get("identificable") is not None:
            ident = np.asarray(resultado["identificable"], bool)
    else:
        x = np.asarray(getattr(resultado, "x", resultado), float)  # PEResult o matriz N x Np
        if x.ndim != 2 or x.shape[1] != len(ids):
            raise ValueError(f"Se esperaba una matriz N x {len(ids)} (una fila por estimación)")
        est = np.quantile(x, 0.5, axis=0)
        lo = np.quantile(x, (1 - nivel) / 2, axis=0)
        hi = np.quantile(x, (1 + nivel) / 2, axis=0)
    if identificable is not None:
        ident = np.asarray(identificable, bool)
    if len(est) != len(ids):
        raise ValueError(f"Se esperaban {len(ids)} parámetros ({', '.join(ids)}), llegaron {len(est)}")
    if ident is None:
        warnings.warn(f"Caso {caso}: falta el veredicto de identificabilidad; pásalo con identificable=")

    for k, p in enumerate(ids):
        pars[p]["estimacion"] = float(est[k])
        pars[p]["ic_inferior"] = float(lo[k])
        pars[p]["ic_superior"] = float(hi[k])
        if ident is not None:
            pars[p]["identificable"] = bool(ident[k])
    if justificacion is not None:
        entrega["casos"][caso]["justificacion"] = justificacion
    if equipo is not None:
        entrega["equipo"] = equipo
    if integrantes is not None:
        entrega["integrantes"] = list(integrantes)
    return entrega


def guardar_entrega(entrega: dict, ruta) -> None:
    for caso, c in entrega["casos"].items():
        for p, q in c["parametros"].items():
            if any(q.get(k) is None for k in ("estimacion", "ic_inferior", "ic_superior", "identificable")):
                warnings.warn(f"Caso {caso}, {p}: campos sin llenar.")
    escribir_json(ruta, entrega)
