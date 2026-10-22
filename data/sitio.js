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
  presentaciones: [],

  documentos: [
    {
      titulo: "Introducción a las ecuaciones diferenciales",
      linea: "ambas",
      descripcion:
        "Notas a mano de la introducción del semillero: la ecuación diferencial como operador, espacio de estado y campo vectorial, existencia y unicidad, el espacio solución y el caso discreto.",
      enlace: "cursos/introduccion-edo/notas-introduccion-edo.pdf",
    },
  ],
};
