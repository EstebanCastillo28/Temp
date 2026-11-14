# Cliente de prueba de la API (requiere que la API este iniciada: Rscript despliegue/iniciar_api.R)
suppressPackageStartupMessages({library(httr); library(jsonlite)})
base <- "http://127.0.0.1:8000"
cat("GET /health:\n"); print(content(GET(paste0(base, "/health"))))
caso <- list(fecha = "2019-11-15", hora = 22, localidad = "Kennedy", clase_siniestro = "Atropello", tipo_choque = "No aplica (no es choque)", diseno_lugar = "Tramo de Via",
             via_avenida = 1, n_autos = 1, n_motos = 0, n_bicicletas = 0, n_buses = 0, n_carga_pesada = 0, n_otros_vehiculos = 0, n_peatones = 1, hay_transporte_publico = 0, hay_fuga = 0, edad_min = 58, edad_max = 58)
r <- POST(paste0(base, "/predict"), body = toJSON(caso, auto_unbox = TRUE), content_type_json()); cat("\nPOST /predict (caso valido) -> HTTP", status_code(r), "\n"); print(fromJSON(content(r, "text", encoding = "UTF-8"))[, c("valido", "prob_muertos", "nivel_riesgo", "perfil")])
malo <- caso; malo$hora <- 30; malo$edad_min <- -5
r <- POST(paste0(base, "/predict"), body = toJSON(malo, auto_unbox = TRUE), content_type_json()); cat("\nPOST /predict (entrada invalida) -> HTTP", status_code(r), "\n"); print(fromJSON(content(r, "text", encoding = "UTF-8"))$errores)
