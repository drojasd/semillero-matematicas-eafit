// Pinta el contenido de data/sitio.js en index.html.
(function () {
  const S = window.SEMILLERO;
  // En el repositorio interno, data/privado.js agrega material que no se publica.
  const P = window.SEMILLERO_PRIVADO;
  if (P) {
    S.presentaciones = S.presentaciones.concat(P.presentaciones || []);
    S.documentos = S.documentos.concat(P.documentos || []);
  }
  const $ = (sel) => document.querySelector(sel);
  const esc = (t) =>
    String(t).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

  const LINEAS = { puras: "Puras", biomat: "Biomat", ambas: "Puras · Biomat" };
  const TIPOS = { teorica: "Teórica", practica: "Práctica", taller: "Taller", charla: "Charla", festivo: "Festivo" };

  $("[data-horario]").textContent = S.horario;
  $("[data-salon]").textContent = S.salon;
  $("[data-requisitos]").textContent = S.requisitos;
  $("[data-semestre]").textContent = S.semestre;
  $("[data-semestre-text]").textContent = S.semestre;
  $("[data-semestre-spaced]").textContent = S.semestre.split("").join(" ");

  document.querySelectorAll("[data-whatsapp]").forEach((a) => (a.href = S.whatsapp));
  $("[data-ecard]").src = S.curso.ecard;
  $("[data-curso-nivel]").textContent = S.curso.nivel;
  $("[data-curso-pregunta]").textContent = S.curso.pregunta;
  $("[data-curso-titulo]").textContent = S.curso.titulo;
  $("#lista-coordinadores").innerHTML = S.coordinadores
    .map((c) => `<div><strong>${esc(c.nombre)}</strong><a href="mailto:${esc(c.correo)}">${esc(c.correo)}</a></div>`)
    .join("");

  const sesiones = $("#lista-sesiones");
  sesiones.innerHTML = S.cronograma
    .map((s, i) => {
      const titulo = s.enlace ? `<a href="${esc(s.enlace)}">${esc(s.titulo)}</a>` : esc(s.titulo);
      return `<li class="sesion" data-linea="${esc(s.linea)}">
        <span class="num">${i + 1}</span>
        <div>
          <h3>${titulo}</h3>
          <p class="fecha">${esc(s.fecha)}</p>
          <p class="meta"><span class="pill ${esc(s.tipo)}">${esc(TIPOS[s.tipo] || s.tipo)}</span>
            <span class="pill linea-${esc(s.linea)}">${esc(LINEAS[s.linea] || s.linea)}</span>
            ${esc((s.ponentes || ["Por definir"]).join(", "))}</p>
        </div>
      </li>`;
    })
    .join("");

  const card = (p, accion) => `<article class="card linea-${esc(p.linea)}">
      <p class="tag">${esc(LINEAS[p.linea] || "")}</p>
      <h3>${esc(p.titulo)}</h3>
      <p>${esc(p.descripcion)}</p>
      <a class="cta" href="${esc(p.enlace)}">${accion} →</a>
    </article>`;
  $("#lista-investigacion").innerHTML = S.investigacion
    .map(
      (p) => `<article class="card linea-${esc(p.linea)}">
      <p class="tag">${esc(p.estado)}</p>
      <h3>${esc(p.titulo)}</h3>
      <p>${esc(p.descripcion)}</p>
      ${p.enlace ? `<a class="cta" href="${esc(p.enlace)}">Explorar →</a>` : ""}
    </article>`
    )
    .join("");
  $("#lista-presentaciones").innerHTML = S.presentaciones.map((p) => card(p, "Abrir presentación")).join("");
  $("#lista-documentos").innerHTML = S.documentos.map((p) => card(p, "Abrir documento")).join("");
  // Una sección sin contenido se oculta (su pestaña también, si queda vacía).
  ["presentaciones", "documentos"].forEach((id) => {
    if (!S[id].length) $("#" + id).hidden = true;
  });

  // Curso GSUA-CSB: cada módulo enlaza a su página en MATLAB y en Python.
  const K = S.cursoGSUA;
  if (K) {
    $("[data-curso-desc]").textContent = K.descripcion;
    $("#lista-curso").innerHTML = K.modulos
      .map((m) => {
        const n = String(m.n).padStart(2, "0");
        return `<article class="card linea-biomat">
      <p class="tag">Módulo ${m.n}</p>
      <h3>${esc(m.titulo)}</h3>
      <p>${esc(m.tema)}</p>
      <p class="cta-par"><a class="cta" href="${esc(K.base)}modulo-${n}-matlab.html" target="_blank" rel="noopener">MATLAB →</a>
        <a class="cta" href="${esc(K.base)}modulo-${n}-python.html" target="_blank" rel="noopener">Python →</a></p>
    </article>`;
      })
      .join("");
    // Hands-on destacado, con el tablero de vista previa de los datos.
    const H = K.handson;
    $("#curso-handson").innerHTML = `<div>
        <p class="tag">Hands-on · MATLAB y Python</p>
        <h3>${esc(H.titulo)}</h3>
        <p class="muted">${esc(H.texto)}</p>
        <div class="botones">
          <a class="boton" href="${esc(H.tablero)}">Ver el tablero de datos →</a>
          <a class="boton sec" href="${esc(H.zip)}">Descargar (.zip)</a>
          <a class="boton sec" href="${esc(H.instrucciones)}" target="_blank" rel="noopener">Instrucciones</a>
          <a class="boton sec" href="${esc(H.fuentes)}" target="_blank" rel="noopener">Fuentes de los datos</a>
        </div>
      </div>
      <a href="${esc(H.tablero)}" class="vista-datos" aria-label="Abrir el tablero"></a>`;
    // Vista previa: casos semanales de dengue en Medellín y Cali (SIVIGILA), leídos de los CSV del hands-on.
    const carpeta = H.tablero.replace(/[^/]+$/, "datos/");
    Promise.all(["dengue_medellin_sivigila.csv", "dengue_cali_sivigila.csv"].map((f) =>
      fetch(carpeta + f).then((r) => (r.ok ? r.text() : Promise.reject(f)))))
      .then((txt) => {
        const ys = txt.map((t) => t.trim().split(/\r?\n/).slice(1).map((l) => +l.split(",")[3]));
        const W = 420, Hh = 190, top = Math.max(...ys.flat());
        const ruta = (y) => y.map((v, i) => `${i ? "L" : "M"}${((i / (y.length - 1)) * W).toFixed(1)},${(Hh - 22 - (v / top) * (Hh - 40)).toFixed(1)}`).join("");
        const anios = [2010, 2014, 2018, 2022].map((a) => `<text x="${((a - 2010) * 52 / (ys[0].length - 1)) * W}" y="${Hh - 4}">${a}</text>`).join("");
        $(".vista-datos").innerHTML = `<svg viewBox="0 0 ${W} ${Hh}" role="img" aria-label="Casos semanales de dengue en Medellín y Cali, 2010 a 2024">
          <path d="${ruta(ys[0])}" fill="none" stroke="var(--biomat)" stroke-width="1.4"/>
          <path d="${ruta(ys[1])}" fill="none" stroke="var(--puras)" stroke-width="1.4" opacity=".85"/>
          <g class="ejes">${anios}</g>
          <text x="0" y="12" style="fill:var(--biomat);font-weight:600">Medellín</text><text x="70" y="12" style="fill:var(--puras);font-weight:600">Cali</text>
          <text x="${W}" y="12" text-anchor="end">dengue, casos por semana</text></svg>`;
      })
      .catch(() => {});
    // Papers de los modelos, con su diagrama de compartimientos.
    const D = window.DIAGRAMAS;
    $("#curso-papers").innerHTML = K.papers
      .map((p) => `<article class="paper">
      <p class="tag">${p.anio} · ${esc(p.revista)}</p>
      <h3>${esc(p.titulo)}</h3>
      <p class="autores">${esc(p.autores)}</p>
      <p>${esc(p.aporte)}</p>
      ${D ? p.diagramas.map((d) => D.dibujar(d) + `<p class="nota">${esc(D.specs[d].titulo)}. ${esc(D.specs[d].nota || "")}</p>`).join("") : ""}
      <p class="usa">En el hands-on: ${p.modelos.map((m) => `<code>${esc(m)}</code>`).join(", ")}</p>
      <p class="cta-par" style="margin-top:auto"><a class="cta" href="https://doi.org/${esc(p.doi)}" target="_blank" rel="noopener">Leer el paper (doi:${esc(p.doi)}) →</a></p>
    </article>`)
      .join("");
    // Resto de enlaces, agrupados.
    const grupos = [...new Set(K.enlaces.map((e) => e.grupo))];
    $("#curso-enlaces").innerHTML = grupos
      .map((g) => `<div><h4>${esc(g)}</h4><ul>${K.enlaces
        .filter((e) => e.grupo === g)
        .map((e) => `<li><a href="${esc(e.url)}" target="_blank" rel="noopener">${esc(e.texto)}</a></li>`)
        .join("")}</ul></div>`)
      .join("");
  } else {
    $("#curso").hidden = true;
  }

  // Retos de identificabilidad (data/retos.js, generado por retos/calificar.py --sitio).
  const R = window.SEMILLERO_RETOS || [];
  const num = (x, d) => Number(x).toFixed(d);
  $("#lista-retos").innerHTML = R.map((r) => {
    const filas = r.posiciones
      .map(
        (f) => `<tr${f.posicion === 1 ? ' class="primero"' : ""}>
          <td>${f.posicion}</td><td>${esc(f.equipo)}</td><td>${num(f.penalizacion, 2)}</td>
          <td>${f.aciertos}/${f.total}</td><td>${num(100 * f.cobertura, 0)} %</td>
          <td>${num(f.error_relativo, 3)}</td></tr>`
      )
      .join("");
    const tabla = r.posiciones.length
      ? `<div class="tabla"><table>
          <thead><tr><th>#</th><th>Equipo</th><th>Penalización</th><th>Aciertos</th>
          <th>Cobertura</th><th>Error</th></tr></thead><tbody>${filas}</tbody></table></div>`
      : `<p class="muted">Reto abierto: aún no hay posiciones.</p>`;
    return `<article class="reto">
      <p class="tag">Reto R${esc(r.reto)} · ${esc(r.casos)} casos · ${esc(r.parametros.length)} parámetros</p>
      <h3>${esc(r.titulo)}</h3>
      <p class="sello"><span>SHA-256 de la verdad</span> <code>${esc(r.sha256_verdad)}</code></p>
      ${r.kit ? `<p class="cta-par"><a class="cta" href="${esc(r.kit)}" download>Descargar el kit del reto →</a>
        ${r.instrucciones ? `<a class="cta" href="${esc(r.instrucciones)}" target="_blank" rel="noopener">Instrucciones →</a>` : ""}</p>` : ""}
      ${tabla}
    </article>`;
  }).join("");
  if (!R.length) {
    $("#retos").hidden = true;
  }

  document.querySelectorAll("[data-filter]").forEach((btn) =>
    btn.addEventListener("click", () => {
      document.querySelectorAll("[data-filter]").forEach((b) => b.classList.toggle("on", b === btn));
      const f = btn.dataset.filter;
      sesiones.querySelectorAll(".sesion").forEach((li) => {
        const l = li.dataset.linea;
        li.hidden = !(f === "todas" || l === f || l === "ambas");
      });
    })
  );

  // Pestañas: el #hash elige cuál se muestra. Un #hash de una sección interna
  // (por ejemplo #cronograma o #documentos) abre su pestaña y baja hasta ella.
  const pestanas = [...document.querySelectorAll(".pestana")];
  const nombres = [...new Set(pestanas.map((p) => p.dataset.pestana))];
  nombres.forEach((n) => {
    const vacia = pestanas.filter((p) => p.dataset.pestana === n).every((p) => [...p.querySelectorAll("section")].every((x) => x.hidden));
    const a = document.querySelector(`.nav a[href="#${n}"]`);
    if (vacia && a) a.hidden = true;
  });
  function mostrar() {
    const id = decodeURIComponent(location.hash.slice(1));
    const destino = id && document.getElementById(id);
    const caja = destino && destino.closest(".pestana");
    const n = caja ? caja.dataset.pestana : nombres.includes(id) ? id : "inicio";
    pestanas.forEach((p) => (p.hidden = p.dataset.pestana !== n));
    document.querySelectorAll(".nav nav a").forEach((a) => {
      if (a.getAttribute("href") === "#" + n) a.setAttribute("aria-current", "page");
      else a.removeAttribute("aria-current");
    });
    const primera = caja && caja.querySelector("section:not([hidden])");
    if (destino && destino !== primera) destino.scrollIntoView({ behavior: "instant", block: "start" });
    else window.scrollTo({ top: 0, behavior: "instant" });
  }
  window.addEventListener("hashchange", mostrar);
  mostrar();
})();
