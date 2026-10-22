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
  // Una sección sin contenido se oculta, junto con su enlace en el menú.
  ["presentaciones", "documentos"].forEach((id) => {
    if (S[id].length) return;
    $("#" + id).hidden = true;
    const a = document.querySelector(`.nav a[href="#${id}"]`);
    if (a) a.hidden = true;
  });

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
})();
