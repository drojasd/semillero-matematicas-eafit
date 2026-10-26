"""Corre el hands-on de Python en modo rápido para cada escenario y sus modelos sugeridos.

    python pruebas/correr_handson.py            # todas las combinaciones
    python pruebas/correr_handson.py dengue     # solo escenarios cuyo id contiene "dengue"

Sale con error si alguna combinación falla. Es una prueba de que todo corre, no de calidad del
ajuste: para eso, correr handson.py con los tamaños por omisión.
"""
import json
import os
import subprocess
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
filtro = sys.argv[1] if len(sys.argv) > 1 else ""
fallas = []
entorno = {**os.environ, "PYTHONIOENCODING": "utf-8", "PYTHONUTF8": "1"}  # salida del hijo en UTF-8
for e in json.loads((RAIZ / "escenarios.json").read_text(encoding="utf-8")):
    if filtro not in e["id"]:
        continue
    for m in e["modelos_sugeridos"]:
        r = subprocess.run([sys.executable, "-W", "ignore", "handson.py", "--rapido", "--sin-sa",
                            "--escenario", e["id"], "--modelo", m],
                           cwd=RAIZ / "python", capture_output=True, text=True, encoding="utf-8", env=entorno)
        ok = r.returncode == 0
        ultima = (r.stdout.strip().splitlines() or [""])[-1]
        print(f"{'OK ' if ok else 'FALLA'} {e['id']:24s} {m:22s} {ultima if ok else r.stderr.strip().splitlines()[-1]}")
        if not ok:
            fallas.append((e["id"], m))
sys.exit(1 if fallas else 0)
