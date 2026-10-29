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
      { n: 0, titulo: "Cómo se escribe un modelo", tema: "La firma del modelo, factores y salidas; modelos discretos y continuos listos para la toolbox" },
      { n: 1, titulo: "Introducción a modelos", tema: "Modelos discretos y continuos; simulación nominal y ensamble" },
      { n: 2, titulo: "Muestreo", tema: "Uniforme, hipercubo latino y Sobol" },
      { n: 3, titulo: "Incertidumbre y Monte Carlo", tema: "Bandas de percentiles y filtrado Monte Carlo" },
      { n: 4, titulo: "Análisis de sensibilidad", tema: "Índices de Sobol de primer orden y totales" },
      { n: 5, titulo: "Estimación e identificabilidad", tema: "Estimación multicomienzo, bootstrap e identificabilidad práctica" },
    ],
    // Hands-on destacado en la pestaña del curso, con el tablero de datos.
    handson: {
      titulo: "Hands-on de epidemiología con datos reales",
      texto: "Dengue en Medellín, Cali, Bello e Itagüí (SIVIGILA y los datos de los papers) y COVID-19 en Colombia (JHU): 18 brotes, cada uno un escenario para estimar con los modelos de los papers del grupo, en MATLAB y en Python.",
      tablero: "cursos/Modelado epidemiológico/hands_on_epi/tablero.html",
      zip: "cursos/Modelado epidemiológico/hands_on_epi/hands_on_epi.zip",
      instrucciones: "https://github.com/drojasd/semillero-matematicas-eafit/blob/main/cursos/Modelado%20epidemiol%C3%B3gico/hands_on_epi/README.md",
      fuentes: "https://github.com/drojasd/semillero-matematicas-eafit/blob/main/cursos/Modelado%20epidemiol%C3%B3gico/hands_on_epi/datos/FUENTES.md",
    },
    // Papers de los modelos del hands-on, con el diagrama de compartimientos (assets/diagramas.js).
    papers: [
      {
        autores: "Lizarralde-Bejarano DP, Rojas-Díaz D, Arboleda-Sánchez S, Puerta-Yepes ME",
        anio: 2020,
        titulo: "Sensitivity, uncertainty and identifiability analyses to define a dengue transmission model with real data of an endemic municipality of Colombia",
        revista: "PLOS ONE 15(3): e0229668",
        doi: "10.1371/journal.pone.0229668",
        aporte: "Compara modelos de dengue vector-huésped con los casos de Bello y escoge, por sensibilidad e identificabilidad, un SEI-SEIR con reclutamiento constante de mosquitos (modelo 3).",
        diagramas: ["dengue_lizarralde"],
        modelos: ["dengue_lizarralde"],
      },
      {
        autores: "Cataño-López A, Rojas-Díaz D, Lizarralde-Bejarano DP, Puerta-Yepes ME",
        anio: 2022,
        titulo: "Discrete Models in Epidemiology: New Contagion Probability Functions Based on Real Data Behavior",
        revista: "Bulletin of Mathematical Biology 84: 127",
        doi: "10.1007/s11538-022-01076-6",
        aporte: "Propone probabilidades de contagio G1, G2 y G3 con heterogeneidad ℵ para modelos discretos, y las aplica a dengue (Itagüí, con reclutamiento de Ricker) y a COVID-19 con cuarentena y detección.",
        diagramas: ["dengue_cl", "sir_cuarentena"],
        modelos: ["dengue_cl_discreto", "sir_discreto_G1", "sir_cuarentena_cl"],
      },
    ],
    // En orden: material, fuentes de datos (verificadas el 2026-10-26), papers de los modelos
    // (DOI comprobados en Crossref) y la toolbox. `grupo` sirve para agruparlos al mostrarlos.
    enlaces: [
      { grupo: "Datos", texto: "Portal SIVIGILA (INS)", url: "https://portalsivigila.ins.gov.co/" },
      { grupo: "Datos", texto: "Microdatos del SIVIGILA", url: "https://portalsivigila.ins.gov.co/Paginas/Buscador.aspx" },
      { grupo: "Datos", texto: "Boletín Epidemiológico Semanal (INS)", url: "https://www.ins.gov.co/buscador-eventos/Paginas/Vista-Boletin-Epidemilogico.aspx" },
      { grupo: "Datos", texto: "Dengue en Medellín (datos.gov.co)", url: "https://www.datos.gov.co/d/ke8u-qixu" },
      { grupo: "Datos", texto: "Dengue en las Américas (OPS, PLISA)", url: "https://www.paho.org/es/arbo-portal/dengue-datos-analisis" },
      { grupo: "Datos", texto: "COVID-19, JHU CSSE", url: "https://github.com/CSSEGISandData/COVID-19" },
      { grupo: "Datos", texto: "COVID-19, Our World in Data", url: "https://ourworldindata.org/covid-cases" },
      { grupo: "Otros papers", texto: "Cataño-López et al. 2023 (COVID-19 en Colombia, PLOS ONE)", url: "https://doi.org/10.1371/journal.pone.0275546" },
      { grupo: "Otros papers", texto: "Kermack y McKendrick 1927 (SIR)", url: "https://doi.org/10.1098/rspa.1927.0118" },
      { grupo: "Otros papers", texto: "Ricker 1954 (reclutamiento)", url: "https://doi.org/10.1139/f54-039" },
      { grupo: "Otros papers", texto: "Rojas-Díaz et al. 2024 (caja CSB, Comput Stat)", url: "https://doi.org/10.1007/s00180-023-01362-4" },
      { grupo: "Toolbox", texto: "Guía de usuario", url: "https://drojasd.github.io/GSUA-CSB/gsua_userguide.html" },
      { grupo: "Toolbox", texto: "Descargar la toolbox (.mltbx)", url: "https://github.com/drojasd/GSUA-CSB/releases/latest" },
      { grupo: "Toolbox", texto: "Repositorio GSUA-CSB", url: "https://github.com/drojasd/GSUA-CSB" },
    ],
  },

  // Las notas fuente (a mano, .tex) NUNCA se enlazan: se presentan como HTML interactivo.
  documentos: [],
};
