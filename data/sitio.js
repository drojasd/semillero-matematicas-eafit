// Contenido editable del sitio. Para agregar una sesión o una presentación,
// añade un objeto a la lista correspondiente; index.html se actualiza solo.

window.SEMILLERO = {
  semestre: "2026-2",
  horario: "Jueves, 3:00 – 5:00 p.m.",
  salon: "20-520",
  requisitos: "Ninguno: solo ganas de aprender",
  whatsapp: "https://chat.whatsapp.com/IOtsnojj60MFkuqQ8lJWGE",

  // Curso del semestre (e-card en assets/ecard-2026-2.webp)
  curso: {
    nivel: "Nivel 1",
    titulo: "Construyendo las bases del cálculo desde la función hasta el diferencial",
    pregunta: "¿Qué es un diferencial?",
    ecard: "assets/ecard-2026-2.webp",
  },

  // Líneas de investigación activas (proyectos, distintos de las líneas formativas)
  investigacion: [
    {
      titulo: "Wolbachia y dengue",
      linea: "biomat",
      estado: "En curso · Universo Semilleros 2026",
      descripcion:
        "¿Funciona en Colombia la liberación de mosquitos con Wolbachia para controlar el dengue? Un modelo en tiempo discreto humano-mosquito, forzado por el clima y calibrado con catorce años de vigilancia semanal de Medellín, permite construir el escenario sin liberaciones y estimar el efecto atribuible a la intervención.",
    },
    {
      titulo: "Transmisión de VIH",
      linea: "biomat",
      estado: "En curso",
      descripcion:
        "¿Cuántas personas con VIH en Medellín no saben que lo tienen? Un modelo inmuno-epidemiológico en ecuaciones en diferencias, calibrado con datos locales, busca estimar la incidencia real del VIH, incluida la población no diagnosticada que no aparece en los registros oficiales.",
    },
    {
      titulo: "Topología en espacios discretos",
      linea: "puras",
      estado: "En curso",
      descripcion:
        "Análogos de la topología en el mundo discreto: los espacios moldeados dicen qué elementos son adyacentes y permiten definir cuándo una función entre ellos es continua.",
      enlace: "charlas/espacios-moldeados/funcion-discreta.html",
    },
    {
      titulo: "Pedagogía de las matemáticas",
      linea: "ambas",
      estado: "En curso",
      descripcion:
        "Cómo se aprenden y se comunican las matemáticas: construir las ideas del cálculo desde sus fundamentos y diseñar materiales interactivos para enseñarlas.",
    },
  ],

  coordinadores: [
    { nombre: "Daniel Rojas Díaz", correo: "drojasd@eafit.edu.co" },
    { nombre: "Jacobo Ramírez Arias", correo: "jramireza4@eafit.edu.co" },
    { nombre: "Juan Pablo Peláez Montoya", correo: "jppelaezm1@eafit.edu.co" },
  ],

  // tipo: "teorica" | "practica" | "taller" | "charla" | "festivo"
  // linea: "puras" | "biomat" | "ambas"
  cronograma: [
    {
      titulo: "Continuidad en moldes: espacios moldeados",
      fecha: "Octubre 2026",
      tipo: "teorica",
      linea: "puras",
      ponentes: ["Semillero de Matemáticas"],
    },
  ],

  // Material PRIVADO (espacios moldeados) vive en data/privado.js y no se publica.
  presentaciones: [
    {
      titulo: "¿Qué es una ecuación diferencial?",
      linea: "ambas",
      descripcion:
        "La introducción del semillero, interactiva: la ecuación como operador y su kernel, el problema de valor inicial, espacio de estado y campo vectorial, existencia y unicidad, el espacio solución, autovalores, el mundo discreto y el péndulo.",
      enlace: "cursos/introduccion-edo/presentacion.html",
    },
    {
      titulo: "Función discreta · continuidad en moldes",
      linea: "puras",
      descripcion:
        "Construye la estructura y luego ponla a prueba: un laboratorio paso a paso, con estética de Manim, para graficar una función discreta y comprobar su continuidad en moldes.",
      enlace: "charlas/espacios-moldeados/funcion-discreta.html",
    },
    {
      titulo: "Nivel 1: de la función a la diferencial",
      linea: "puras",
      descripcion:
        "El Nivel 1, interactivo: funciones, topología y continuidad, límite, campos, espacios vectoriales y bases, funciones lineales, el espacio dual y la diferencial como la mejor aproximación lineal.",
      enlace: "cursos/nivel-1-diferencial/presentacion.html",
    },
  ],

  // Curso de la toolbox GSUA-CSB (las páginas viven en el sitio de la toolbox).
  cursoGSUA: {
    titulo: "Curso GSUA-CSB",
    descripcion:
      "Validación de modelos con la toolbox GSUA-CSB, en MATLAB y en Python: del modelo a la incertidumbre, la sensibilidad, la estimación de parámetros y la identificabilidad. Cada módulo está escrito dos veces, una por lenguaje, resolviendo lo mismo.",
    base: "https://drojasd.github.io/GSUA-CSB/course/",
    modulos: [
      { n: 1, titulo: "Introducción a modelos", tema: "Modelos discretos y continuos; simulación nominal y ensamble" },
      { n: 2, titulo: "Muestreo", tema: "Uniforme, hipercubo latino y Sobol" },
      { n: 3, titulo: "Incertidumbre y Monte Carlo", tema: "Bandas de percentiles y filtrado Monte Carlo" },
      { n: 4, titulo: "Análisis de sensibilidad", tema: "Índices de Sobol de primer orden y totales" },
      { n: 5, titulo: "Estimación e identificabilidad", tema: "Estimación multicomienzo, bootstrap e identificabilidad práctica" },
    ],
    enlaces: [
      { texto: "Hands-on de epidemiología con datos reales (MATLAB y Python)", url: "cursos/Modelado epidemiológico/hands_on_epi/hands_on_epi.zip" },
      { texto: "Instrucciones del hands-on", url: "https://github.com/drojasd/semillero-matematicas-eafit/blob/main/cursos/Modelado%20epidemiol%C3%B3gico/hands_on_epi/README.md" },
      { texto: "Guía de usuario", url: "https://drojasd.github.io/GSUA-CSB/gsua_userguide.html" },
      { texto: "Descargar la toolbox (.mltbx)", url: "https://github.com/drojasd/GSUA-CSB/releases/latest" },
      { texto: "Repositorio GSUA-CSB", url: "https://github.com/drojasd/GSUA-CSB" },
    ],
  },

  // Las notas fuente (a mano, .tex) NUNCA se enlazan: se presentan como HTML interactivo.
  documentos: [],
};
