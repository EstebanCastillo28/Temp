# ------------------------------------------------------------------
# api.R — API REST (plumber) del modelo de gravedad de siniestros viales.
# Iniciar:  Rscript despliegue/iniciar_api.R      (puerto 8000)
# Probar:   Rscript despliegue/probar_api.R   o   curl (ver README.md)
# ------------------------------------------------------------------
source(file.path(if (file.exists("funciones_despliegue.R")) "." else "despliegue", "funciones_despliegue.R"), encoding = "UTF-8")
A <- cargar_artefactos()

#* Estado del servicio y datos del modelo
#* @get /health
function() list(estado = "ok", modelo = A$final$campeon, version = A$final$version, entrenado = A$final$fecha)

#* Metricas del modelo en el conjunto de prueba
#* @get /info
function() list(modelo = A$final$campeon, version = A$final$version, metricas_test = A$final$metricas_test[c("f1_macro", "recall_fatal", "precision_fatal", "accuracy")],
                columnas_entrada = COLS_ENTRADA)

#* Predice la gravedad de uno o varios siniestros. Cuerpo JSON: un objeto o una lista de objetos con las columnas de entrada.
#* @post /predict
#* @serializer json list(na = "null", auto_unbox = TRUE)
function(req, res) {
  d <- tryCatch(jsonlite::fromJSON(req$postBody, simplifyDataFrame = TRUE), error = function(e) NULL)
  if (is.null(d)) { res$status <- 400; return(list(error = "El cuerpo debe ser JSON valido.")) }
  d <- as.data.frame(d, stringsAsFactors = FALSE)
  faltan <- setdiff(COLS_ENTRADA[c(1:8, 14)], names(d))
  if (length(faltan)) { res$status <- 400; return(list(error = paste("Faltan columnas:", paste(faltan, collapse = ", ")))) }
  r <- predecir_gravedad(d, A)
  if (!any(r$valido)) res$status <- 422
  r
}
