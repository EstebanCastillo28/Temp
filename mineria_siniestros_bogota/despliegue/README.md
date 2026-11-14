# Despliegue — Estimador de gravedad de siniestros viales (Bogotá D.C.)

Artefacto que **carga el modelo ya entrenado** (`../modelos/`) y estima, para un siniestro descrito por el usuario, la probabilidad de cada desenlace (solo daños, heridos, víctimas fatales), un nivel de riesgo (Bajo/Medio/Alto), el perfil del siniestro y una recomendación orientativa. **No reentrena nada.**

Incluye tres formas de uso, según el tipo de usuario:

| Archivo | Para qué | Quién lo usa |
|---|---|---|
| `app.R` | Aplicación web interactiva (Shiny): formulario, lote CSV y monitoreo | Analistas de movilidad / autoridad de tránsito |
| `api.R` + `iniciar_api.R` | API REST (plumber) para integrarlo con otros sistemas | Equipo técnico |
| `funciones_despliegue.R` | Función `predecir_gravedad(df, A)` en R | Analistas que trabajan en R |
| `probar_despliegue.R`, `probar_api.R` | Pruebas automáticas en consola | Revisión / mantenimiento |
| `monitoreo.R` | PSI por variable y desempeño de un lote | Mantenimiento del modelo |

## Requisitos

* R ≥ 4.2 con locale UTF-8 y los paquetes: `shiny bslib ggplot2 dplyr tidyr stringr lubridate glmnet ranger xgboost plumber jsonlite httr`
  (instalación: `source("instalar_dependencias.R")` en la raíz del proyecto).
* La carpeta `modelos/` y `scripts/` deben estar junto a `despliegue/` (no mover archivos).

## Cómo ejecutarlo (paso a paso)

**Aplicación Shiny** (recomendado para la demostración)
1. Abrir el proyecto en RStudio y abrir `despliegue/app.R`.
2. Pulsar **Run App** (o en la consola: `shiny::runApp("despliegue")`).
3. En la pestaña *Estimar un siniestro*, cargar un ejemplo o completar el formulario y pulsar **Estimar gravedad**.

**Función en R / archivo CSV nuevo**
```r
source("despliegue/funciones_despliegue.R"); A <- cargar_artefactos()
casos <- read.csv("despliegue/ejemplos/casos_ejemplo.csv", encoding = "UTF-8")
predecir_gravedad(casos, A)
```

**API**
```bash
Rscript despliegue/iniciar_api.R            # terminal 1: queda escuchando en http://127.0.0.1:8000
Rscript despliegue/probar_api.R             # terminal 2: cliente de prueba
curl -X POST http://127.0.0.1:8000/predict -H "Content-Type: application/json" \
  -d '{"fecha":"2019-11-15","hora":22,"localidad":"Kennedy","clase_siniestro":"Atropello","tipo_choque":"No aplica (no es choque)","diseno_lugar":"Tramo de Via","via_avenida":1,"n_autos":1,"n_motos":0,"n_bicicletas":0,"n_buses":0,"n_carga_pesada":0,"n_otros_vehiculos":0,"n_peatones":1,"edad_min":58,"edad_max":58}'
```

**Pruebas automáticas:** `Rscript despliegue/probar_despliegue.R` (verifica que el modelo guardado reproduce las predicciones de Test, el caso límite y las entradas inválidas).

## Entrada esperada (una fila por siniestro)

`fecha` (AAAA-MM-DD) · `hora` (0–23,99) · `localidad` · `clase_siniestro` · `tipo_choque` · `diseno_lugar` · `via_avenida` (0/1) · `n_autos`, `n_motos`, `n_bicicletas`, `n_buses`, `n_carga_pesada`, `n_otros_vehiculos`, `n_peatones` (enteros ≥ 0; al menos un vehículo) · `hay_transporte_publico`, `hay_fuga` (0/1) · `edad_min`, `edad_max`, `edad_media`, `prop_mujeres` (opcionales; si faltan se imputan con los parámetros de Train).
Los valores válidos de las categorías están en `funciones_despliegue.R` (`LOCALIDADES`, `CLASES_SIN`, `TIPOS_CHOQUE`, `DISENOS`). Plantilla: `ejemplos/plantilla_casos.csv`.

## Salida

`valido`, `errores`, `advertencias`, `prob_solo_danos`, `prob_heridos`, `prob_muertos`, `clase_predicha`, `nivel_riesgo`, `perfil`, `recomendacion`, `mensaje`.

Ejemplo (atropello nocturno a un peatón de 58 años, Kennedy): probabilidad de víctimas fatales **≈ 20 %**, nivel **Alto**, perfil *Peatón o moto, un solo vehículo*.
(Resultados de todos los ejemplos en la sección 9.2 del informe.)

## Validación de entradas y casos límite

* Se **rechazan** (sin predicción, con mensaje): fecha u hora inválidas, localidad o categorías desconocidas, cantidades negativas o no enteras, ningún vehículo, > 30 vehículos, edades fuera de 0–109 o mínima > máxima, proporción de mujeres fuera de 0–1.
* Se **advierten** (se predice igual): valores extremos (más de 4 vehículos se acotan al tope aprendido en Train), incoherencias entre clase de siniestro y peatones, edades no informadas.

## Cómo interpretar la salida (usuario sin formación técnica)

Una probabilidad de 6 % de víctimas fatales significa que, de 100 siniestros con condiciones parecidas en 2015–2020, unos 6 terminaron con muertos. El *nivel de riesgo* ordena los casos: «Alto» agrupa al 5 % de siniestros con mayor probabilidad estimada. La herramienta **apoya la priorización de intervenciones**; no reemplaza el criterio de la autoridad ni debe usarse para decidir sobre personas.

## Plan de monitoreo y mantenimiento

1. **Cada trimestre**: calcular el PSI de las variables de entrada del lote nuevo frente a Train (`monitorear_lote()` o pestaña *Monitoreo*). PSI < 0,10 estable · 0,10–0,25 vigilar · > 0,25 reentrenar o investigar.
2. **Cuando llegan las etiquetas reales** (gravedad confirmada): medir recall de la clase fatal, precisión y F1 macro del lote con `desempeno_lote()`. Alerta si el recall fatal cae más de 10 puntos respecto a Test o si el nivel «Alto» deja de concentrar la mayoría de los fatales.
3. **Reentrenamiento**: ante deriva (PSI > 0,25) o caída de desempeño, o al incorporar datos posteriores a 2020, ejecutar `scripts/02_…`, `04_…`, `05_…` con los datos nuevos y publicar una versión nueva en `modelos/` (`modelo_final.rds` registra versión y fecha).
4. **Registro**: guardar cada predicción con su fecha y versión del modelo para auditoría.

## Limitaciones

Datos 2015–2020 (incluyen el año de pandemia), sin velocidad, clima ni flujo vehicular; el registro depende del diligenciamiento del IPAT. La probabilidad es una **estimación estadística** sobre siniestros ya ocurridos, no un pronóstico de dónde ocurrirá el próximo. Ver sección de limitaciones y ética del informe.
