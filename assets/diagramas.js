// Diagramas de compartimientos de los modelos del hands-on, dibujados en SVG a partir de las
// ecuaciones de cada paper (no son las figuras de los papers). Los usan index.html (tarjetas de
// papers) y el tablero del hands-on.
//
// Cada diagrama: nodos {id, t (texto), x, y, c ("h" humano | "m" mosquito | "q" cuarentena)}
// y flechas {a, b, t (etiqueta), curva (desvío), punteada}. "b" puede ser el id de otra flecha
// ("flecha:<a>><b>") para señalar a qué transición afecta un contagio cruzado.
(function () {
  const D = {
    sir: {
      titulo: "SIR",
      alto: 120,
      nodos: [
        { id: "S", t: "S", x: 90, y: 60, c: "h" },
        { id: "I", t: "I", x: 300, y: 60, c: "h" },
        { id: "R", t: "R", x: 510, y: 60, c: "h" },
      ],
      flechas: [
        { a: "S", b: "I", t: "β·I/N" },
        { a: "I", b: "R", t: "γ" },
      ],
      nota: "En el SIR discreto la probabilidad de contagio es P = 1 − e^(−βI/N), o una de las G de Cataño-López et al. (2022).",
    },
    sir_cuarentena: {
      titulo: "SIR con cuarentena y detección (Cataño-López et al. 2022, ec. 6)",
      alto: 290,
      nodos: [
        { id: "Sf", t: "Sf", x: 70, y: 110, c: "h" },
        { id: "Sq", t: "Sq", x: 70, y: 250, c: "q" },
        { id: "If", t: "If", x: 290, y: 110, c: "h" },
        { id: "Iq", t: "Iq", x: 290, y: 250, c: "q" },
        { id: "Ij", t: "Ij", x: 440, y: 180, c: "q" },
        { id: "R", t: "R", x: 590, y: 180, c: "h" },
      ],
      flechas: [
        { a: "Sf", b: "If", t: "β·G̃" },
        { a: "Sf", b: "Sq", t: "λ", curva: -18 },
        { a: "Sq", b: "Sf", t: "α", curva: -18 },
        { a: "If", b: "Iq", t: "λ", curva: -18 },
        { a: "Iq", b: "If", t: "α", curva: -18 },
        { a: "If", b: "Ij", t: "θ" },
        { a: "Iq", b: "Ij", t: "θ" },
        { a: "Ij", b: "R", t: "γ" },
        { a: "R", b: "Sf", t: "μ", curva: 190 },
      ],
      nota: "f = libre, q = cuarentena, j = detectado; μ = pérdida de inmunidad. G̃ = probabilidad de contagio con heterogeneidad ℵ.",
    },
    dengue_lizarralde: {
      titulo: "Dengue, 7 EDO (Lizarralde-Bejarano et al. 2020, modelo 3)",
      alto: 250,
      nodos: [
        { id: "L", t: "Λ", x: 40, y: 60, c: "fuente" },
        { id: "Ms", t: "Ms", x: 140, y: 60, c: "m" },
        { id: "Me", t: "Me", x: 300, y: 60, c: "m" },
        { id: "Mi", t: "Mi", x: 460, y: 60, c: "m" },
        { id: "Hs", t: "Hs", x: 140, y: 190, c: "h" },
        { id: "He", t: "He", x: 300, y: 190, c: "h" },
        { id: "Hi", t: "Hi", x: 460, y: 190, c: "h" },
        { id: "Hr", t: "Hr", x: 590, y: 190, c: "h" },
      ],
      flechas: [
        { a: "L", b: "Ms", t: "" },
        { a: "Ms", b: "Me", t: "βm·Hi/H" },
        { a: "Me", b: "Mi", t: "θm" },
        { a: "Hs", b: "He", t: "βh·Mi/M" },
        { a: "He", b: "Hi", t: "θh" },
        { a: "Hi", b: "Hr", t: "γh" },
        { a: "Mi", b: "flecha:Hs>He", t: "pica", punteada: true },
        { a: "Hi", b: "flecha:Ms>Me", t: "pica", punteada: true },
      ],
      nota: "Mortalidad μm en mosquitos y μh en humanos (no dibujadas). Tiempo en semanas.",
    },
    dengue_cl: {
      titulo: "Dengue discreto (Cataño-López et al. 2022, ec. 9)",
      alto: 250,
      nodos: [
        { id: "A", t: "A(t)", x: 50, y: 60, c: "fuente" },
        { id: "Sm", t: "Sm", x: 220, y: 60, c: "m" },
        { id: "Im", t: "Im", x: 440, y: 60, c: "m" },
        { id: "Sh", t: "Sh", x: 220, y: 190, c: "h" },
        { id: "Ih", t: "Ih", x: 440, y: 190, c: "h" },
        { id: "Rh", t: "Rh", x: 590, y: 190, c: "h" },
      ],
      flechas: [
        { a: "A", b: "Sm", t: "Ricker" },
        { a: "Sm", b: "Im", t: "βhm·G̃hm" },
        { a: "Sh", b: "Ih", t: "βmh·G̃mh" },
        { a: "Ih", b: "Rh", t: "γ" },
        { a: "Im", b: "flecha:Sh>Ih", t: "pica", punteada: true },
        { a: "Ih", b: "flecha:Sm>Im", t: "pica", punteada: true },
      ],
      nota: "A(t) = r·Nm(t−2)·e^(1 − Nm(t)/C). Paso semanal; mortalidades μm, μh.",
    },
  };

  // Qué diagrama corresponde a cada modelo del catálogo del hands-on.
  const POR_MODELO = {
    sir_continuo: "sir", sir_discreto: "sir", sir_discreto_G1: "sir", sir_discreto_G2: "sir", sir_discreto_G3: "sir",
    sir_cuarentena_cl: "sir_cuarentena", sir_cuarentena_cl_G2: "sir_cuarentena", sir_cuarentena_cl_G3: "sir_cuarentena",
    dengue_lizarralde: "dengue_lizarralde", dengue_cl_discreto: "dengue_cl",
  };

  const COLOR = { h: "#53d5cd", m: "#f5c96f", q: "#bda0ff", fuente: "#a6bdcb" };
  const R = 27; // radio de los nodos

  function dibujar(clave) {
    const d = D[clave];
    if (!d) return "";
    const n = Object.fromEntries(d.nodos.map((x) => [x.id, x]));
    const medio = {}; // punto medio de cada flecha, para los contagios cruzados
    let flechas = "";
    const etiquetas = [];
    for (const f of d.flechas) {
      if (f.b.startsWith("flecha:")) continue;
      const a = n[f.a], b = n[f.b];
      const dx = b.x - a.x, dy = b.y - a.y, L = Math.hypot(dx, dy) || 1;
      const ux = dx / L, uy = dy / L, ra = a.c === "fuente" ? 14 : R;
      const x1 = a.x + ux * ra, y1 = a.y + uy * ra, x2 = b.x - ux * (R + 4), y2 = b.y - uy * (R + 4);
      const k = f.curva || 0, cx = (x1 + x2) / 2 - uy * k, cy = (y1 + y2) / 2 + ux * k;
      medio[`${f.a}>${f.b}`] = { x: (x1 + 2 * cx + x2) / 4, y: (y1 + 2 * cy + y2) / 4 };
      flechas += `<path d="M${x1},${y1} Q${cx},${cy} ${x2},${y2}" class="dg-f" marker-end="url(#dg-p)"/>`;
      const m = medio[`${f.a}>${f.b}`], s = k ? Math.sign(k) : -1;
      // La etiqueta va del lado hacia el que se curva la flecha (encima, si es recta y va a la derecha).
      if (f.t) etiquetas.push({ x: m.x - uy * 16 * s, y: m.y + ux * 16 * s + 6, t: f.t, ancla: Math.abs(uy) > 0.7 ? (-uy * s > 0 ? "start" : "end") : "middle" });
    }
    for (const f of d.flechas) {
      if (!f.b.startsWith("flecha:")) continue;
      const a = n[f.a], p = medio[f.b.slice(7)];
      const dx = p.x - a.x, dy = p.y - a.y, L = Math.hypot(dx, dy) || 1;
      const x1 = a.x + (dx / L) * R, y1 = a.y + (dy / L) * R;
      flechas += `<path d="M${x1},${y1} L${p.x},${p.y}" class="dg-c" marker-end="url(#dg-pc)"/>`;
      etiquetas.push({ x: x1 + (p.x - x1) * 0.2 + (p.x > x1 ? 8 : -8), y: y1 + (p.y - y1) * 0.2, t: f.t, cruz: true, ancla: p.x > x1 ? "start" : "end" });
    }
    const nodos = d.nodos.map((x) => x.c === "fuente"
      ? `<text x="${x.x}" y="${x.y + 7}" class="dg-fuente">${x.t}</text>`
      : `<circle cx="${x.x}" cy="${x.y}" r="${R}" fill="${COLOR[x.c]}22" stroke="${COLOR[x.c]}" stroke-width="2"/>` +
        `<text x="${x.x}" y="${x.y + 7}" class="dg-n">${x.t}</text>`).join("");
    const textos = etiquetas.map((e) => `<text x="${e.x}" y="${e.y}" text-anchor="${e.ancla}" class="dg-t${e.cruz ? " dg-tc" : ""}">${e.t}</text>`).join("");
    return `<svg viewBox="0 0 640 ${d.alto}" class="diagrama" role="img" aria-label="${d.titulo}">
      <defs>
        <marker id="dg-p" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10z" fill="#a6bdcb"/></marker>
        <marker id="dg-pc" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto"><path d="M0,0 L10,5 L0,10z" fill="#ff8194"/></marker>
      </defs>${flechas}${nodos}${textos}</svg>`;
  }

  window.DIAGRAMAS = { specs: D, porModelo: POR_MODELO, dibujar };
})();
