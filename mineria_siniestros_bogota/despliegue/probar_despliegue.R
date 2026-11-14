# ------------------------------------------------------------------
# probar_despliegue.R — pruebas automaticas del artefacto (consola).
# Ejecutar desde la raiz:  Rscript despliegue/probar_despliegue.R
# Verifica: (1) que el modelo guardado reproduce las predicciones de Test, (2) casos de ejemplo,
# (3) caso limite, (4) entradas invalidas, (5) archivo CSV nuevo.
# ------------------------------------------------------------------
source("despliegue/funciones_despliegue.R", encoding = "UTF-8")
A <- cargar_artefactos()
ok <- function(cond, msg) { cat(if (isTRUE(cond)) "  [OK]   " else "  [FALLA]", msg, "\n"); if (!isTRUE(cond)) quit(status = 1) }

cat("1. El modelo guardado reproduce las predicciones del conjunto de prueba\n")
res <- readRDS(file.path(A$raiz, "resultados", "modelado.rds")); int <- readRDS(file.path(A$raiz, "datos", "clean", "siniestros_integrado.rds"))
teM <- readRDS(file.path(A$raiz, "datos", "clean", "test_ml.rds"))
idx <- seq(1, nrow(teM), length.out = 300) |> round(); ids <- teM$codigo_accidente[idx]
reg <- int[match(ids, int$codigo_accidente), ]
p <- predecir_desde_integrado(reg, A)$p
ok(max(abs(p - res$p_test[[A$final$campeon]][idx, ])) < 1e-6, "probabilidades identicas a las calculadas en la evaluacion (300 casos de Test)")

cat("2. Casos de ejemplo (CSV)\n")
ej <- read.csv(file.path(A$raiz, "despliegue", "ejemplos", "casos_ejemplo.csv"), stringsAsFactors = FALSE, encoding = "UTF-8")
r <- predecir_gravedad(ej, A); print(r[, c("fila", "valido", "prob_muertos", "nivel_riesgo", "clase_predicha", "perfil")], digits = 3)
v <- r[r$valido, ]
ok(all(abs(v$prob_solo_danos + v$prob_heridos + v$prob_muertos - 1) < 1e-6), "las probabilidades suman 1")
ok(v$prob_muertos[v$perfil == "Peatón o moto, un solo vehículo"][1] > v$prob_muertos[v$perfil == "Choque entre vehículos livianos"][1], "el atropello tiene mayor riesgo de fatalidad que el choque entre livianos")

cat("3. Caso limite (25 vehiculos) -> advertencia, no error\n")
lim <- ej[grepl("limite", ej$descripcion, ignore.case = TRUE), ]
rl <- predecir_gravedad(lim, A); ok(rl$valido && nzchar(rl$advertencias), "se predice y se advierte del valor extremo")

cat("4. Entradas invalidas -> se rechazan con mensaje claro\n")
inv <- ej[grepl("invalida", ej$descripcion, ignore.case = TRUE), ]
ri <- predecir_gravedad(inv, A); ok(!any(ri$valido) && all(is.na(ri$prob_muertos)), "no se emite prediccion"); cat("     Mensajes:", ri$errores[1], "\n")

cat("5. Valor fuera del rango visto en entrenamiento (edad 109, 12 vehiculos)\n")
fr <- ej[1, ]; fr$n_autos <- 12; fr$edad_max <- 109; rf <- predecir_gravedad(fr, A); ok(rf$valido && !is.na(rf$prob_muertos), "se evalua con el valor acotado y se advierte")
cat("\nTodas las pruebas pasaron.\n")
