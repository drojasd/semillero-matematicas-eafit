# Datos reales del hands-on: procedencia

Los CSV se regeneran con `python datos/preparar_datos.py` a partir de los archivos originales
del grupo, cuyas rutas están en el guion. Todas son series **agregadas**: no contienen datos
personales.

| Archivo | Enfermedad · lugar | Resolución | Periodo | Columnas | Procedencia |
|---|---|---|---|---|---|
| `dengue_medellin_sivigila.csv` | Dengue · Medellín | Semana epidemiológica | 2010–2024 (780 semanas) | `t, anio, semana_epi, casos, poblacion` | Casos notificados al SIVIGILA (INS), por semana de ocurrencia, compilados en el proyecto Wolbachia del grupo (`Dengue_Cali_Med_Ocurrencia.xlsx`). La población anual es la que usa ese mismo proyecto |
| `dengue_bello_lizarralde.csv` | Dengue · Bello | Semanal | 124 semanas desde la SE 49 de 2009 | `t, casos` | Serie de Bello del repositorio de los autores (`ChimeraAedes/.../Datos/Dengue/Bello.mat`). Es la usada por Lizarralde-Bejarano et al. (2020): de la SE 49 de 2009 a la SE 7 de 2011, unos 1880 casos acumulados en el paper; en las 65 primeras semanas de este archivo suman 1894 |
| `dengue_itagui_2010.csv` | Dengue · Itagüí | Semanal | 70 semanas, brote de 2010 | `t, casos` | Repositorio de Cataño-López et al. (2022) (`CHIMERITApaper/Repository/Data/Itagui.mat`), el mismo usado en el paper del CSB |
| `covid19_colombia_jhu.csv` | COVID-19 · Colombia | Diaria | 2020-03-06 a 2021-08-04 | `t, fecha, confirmados_acum, muertes_acum, recuperados_acum, casos_nuevos, activos` | JHU CSSE COVID-19 Data Repository (licencia CC BY 4.0), copia local de `CHIMERITApaper/RawData`. Se corta cuando JHU dejó de reportar recuperados. `activos = confirmados − muertes − recuperados` |

## Ventanas sugeridas para ajustar

| Serie | Ventana | Por qué |
|---|---|---|
| Dengue Medellín | 2010, SE 1–52 (pico en la SE 23, 819 casos) o 2016 (pico en la SE 27, 589) | Dos brotes grandes y bien definidos |
| Dengue Bello | `t = 0…64` (SE 49/2009 – SE 7/2011) | La ventana de Lizarralde et al. (2020): permite comparar con el paper |
| Dengue Itagüí | `t = 0…69` | El brote de 2010 del paper del CSB |
| COVID-19 Colombia | 2020-03-06 a 2020-11-30 (pico de activos el 2020-08-14, 169 326) | Primera ola; después hay varias olas, que un SIR simple no reproduce |

## Población

- **Medellín:** columna `poblacion`, una por año.
- **Bello:** del proyecto Wolbachia, unos 359 515 habitantes en 2010; los autores usaron 450 000 en
  `CHIMERA_Vector`.
- **Itagüí:** los autores usaron 280 000.
- **Colombia:** 50 372 424, el valor de Cataño-López et al. (2023, PLOS ONE).

Las poblaciones de Bello e Itagüí no vienen en los CSV. Cada modelo las recibe en `opt` y el guion
las documenta.

## Cosas a tener en cuenta en clase

- Son casos **notificados**, no infecciones: hay subregistro, y en dengue la mayoría de
  infecciones son asintomáticas.
- En el SIVIGILA, las semanas recientes se completan con notificaciones tardías.
- Los recuperados de JHU para Colombia son un dato administrativo, no clínico.
