# Minería de datos: gravedad de los siniestros viales en Bogotá D.C. — Segunda entrega

Ciclo KDD hasta preprocesamiento y transformación (dominio, selección, limpieza, transformación sin fuga de datos).
Fuente: *Siniestros Viales Consolidados Bogotá D.C.* (Secretaría Distrital de Movilidad, SIGAT/IPAT), 2015–2020.

## Contenido

| Ruta | Descripción |
|---|---|
| `informe_final.Rmd` / `informe_final.pdf` | Informe reproducible (rutas relativas) y su versión compilada |
| `scripts/00_descarga_datos.R` | Descarga el consolidado oficial y exporta cada hoja a `datos/raw/*.csv` |
| `scripts/01_integracion_limpieza.R` | Reglas deterministas de limpieza + integración Siniestros/Actor Vial/Vehículos a nivel de siniestro |
| `scripts/02_particion_transformacion.R` | Partición estratificada 70/30 (semilla 2025), ajuste de parámetros **solo en Train** y transformación de Train y Test |
| `scripts/funciones.R` | `ajustar_transformacion()` y `aplicar_transformacion()` (idempotente), calendario de festivos |
| `datos/raw/` | CSV crudos (una hoja por archivo) |
| `datos/clean/` | `siniestros_integrado.rds`; `train_/test_` en versión legible, ML (one-hot + Z) y PCA |
| `modelos/parametros_transformacion.rds` | Medianas, topes de winsorización, medias/desvíos, niveles y rotación PCA aprendidos en Train |
| `resultados/auditoria_limpieza.rds` | Contadores de la auditoría de limpieza usados por el informe |

## Requisitos

* R ≥ 4.2 con locale UTF-8. Paquetes: `dplyr tidyr readr stringr lubridate stringi ggplot2 scales gridExtra knitr kableExtra rmarkdown readxl`.
* Para compilar el PDF: una distribución LaTeX con `xelatex` (por ejemplo `tinytex::install_tinytex()` o TeX Live) y la fuente *DejaVu* (o cambie `mainfont` en el encabezado del `.Rmd`).

## Cómo ejecutar

Desde la raíz del proyecto:

```r
# Opción A: solo compilar (el informe ejecuta los scripts que falten)
rmarkdown::render("informe_final.Rmd")

# Opción B: paso a paso
source("scripts/00_descarga_datos.R")           # solo si falta datos/raw (requiere internet)
source("scripts/01_integracion_limpieza.R")
source("scripts/02_particion_transformacion.R")
```

Para regenerar todo desde cero, borre `datos/clean/`, `modelos/` y `resultados/` y vuelva a compilar.

## Garantías contra fuga de datos

* Las reglas de `01_` son deterministas (no aprenden parámetros).
* Todo lo aprendido (mediana de edad, topes P99,5, media/desvío, niveles de categorías, PCA) se calcula **solo con Train** y se guarda en `modelos/parametros_transformacion.rds`.
* `aplicar_transformacion(datos, parametros)` es idempotente y se usa igual para Train, Test y el futuro despliegue.
* El informe ejecuta cuatro pruebas automáticas (idempotencia, columnas idénticas, sin solape Train/Test, parámetros ajustados sin Test) y falla si alguna no se cumple.

## Uso de la transformación sobre datos nuevos

```r
source("scripts/funciones.R")
P <- readRDS("modelos/parametros_transformacion.rds")
nuevos <- readRDS("datos/clean/siniestros_integrado.rds")   # mismas columnas que la tabla integrada
X <- aplicar_transformacion(nuevos, P)$ml
```
