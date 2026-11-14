# ------------------------------------------------------------------
# 07_cifras_sustentacion_final.R
# Exporta a JSON las cifras de la sustentacion final (las diapositivas leen este archivo,
# asi ninguna cifra se escribe a mano). Salida: sustentacion_final/cifras.json
# Ejecutar desde la raiz: Rscript scripts/07_cifras_sustentacion_final.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(jsonlite)})
source("despliegue/funciones_despliegue.R", encoding = "UTF-8"); A <- cargar_artefactos()
mo <- readRDS("resultados/modelado.rds"); ev <- readRDS("resultados/evaluacion.rds"); cl <- readRDS("resultados/clusters.rds")
nm <- c(glmnet = "Regresión logística regularizada", ranger = "Bosque aleatorio", xgboost = "Gradient boosting (XGBoost)")
camp <- mo$campeon; niv <- ev$niveles; g <- function(x) as.numeric(x)
mods <- lapply(names(mo$modelos), function(n) { m <- mo$modelos[[n]]
  list(id = n, nombre = unname(nm[n]), f1_cv = m$cv_ajustado$f1_macro, f1_test = m$test_ajustado$f1_macro, recall_fatal = m$test_ajustado$por_clase$Recall[3],
       precision_fatal = m$test_ajustado$por_clase$Precision[3], auc_fatal = m$test_ajustado$auc[3], pr_auc = m$test_ajustado$pr_auc_fatal, logloss = m$test_ajustado$logloss) })
orf <- function(t) { r <- ev$or[ev$or$termino == t, ]; list(or = r$OR, li = r$li, ls = r$ls, p = r$p) }
ej <- read.csv("despliegue/ejemplos/casos_ejemplo.csv", stringsAsFactors = FALSE, encoding = "UTF-8"); pr <- predecir_gravedad(ej, A)
casos <- lapply(seq_len(nrow(ej)), function(i) list(caso = ej$descripcion[i], valido = pr$valido[i], p_fatal = pr$prob_muertos[i], p_heridos = pr$prob_heridos[i], nivel = pr$nivel_riesgo[i], perfil = pr$perfil[i],
                                                 errores = pr$errores[i], advertencias = pr$advertencias[i]))
out <- list(campeon = camp, campeon_nombre = unname(nm[camp]), modelos = mods, n_train = mo$n_train, n_test = mo$n_test, razon = as.numeric(max(table(mo$y_train)) / min(table(mo$y_train))),
  accuracy_base = mo$base$accuracy, prevalencia_fatal = mean(mo$y_test == "Con muertos"),
  test = list(f1 = ev$test$f1_macro, accuracy = ev$test$accuracy, logloss = ev$test$logloss, auc = as.list(ev$test$auc), pr_auc = ev$test$pr_auc_fatal,
              recall = ev$por_clase$Recall, precision = ev$por_clase$Precision, soporte = ev$por_clase$Soporte),
  sobreajuste = ev$sobreajuste[ev$sobreajuste$modelo == camp, ], multiplicadores = mo$modelos[[camp]]$multiplicadores,
  niveles = lapply(seq_len(nrow(niv)), function(i) as.list(niv[i, ])), umbrales = as.list(ev$umbrales),
  desbalance = lapply(names(mo$desbalance), function(k) list(id = k, f1_cv = mo$desbalance[[k]]$cv$f1_macro, f1_test = mo$desbalance[[k]]$test$f1_macro, recall_fatal = mo$desbalance[[k]]$test$por_clase$Recall[3],
                                                           precision_fatal = mo$desbalance[[k]]$test$por_clase$Precision[3], logloss = mo$desbalance[[k]]$test$logloss)),
  or = list(peaton = orf("hay_peaton"), moto = orf("hay_motociclista"), ciclista = orf("hay_ciclista"), noche = orf("nocturno1"), nohabil = orf("dia_no_habil1"), pesado = orf("hay_pesado")),
  bloques = lapply(seq_len(nrow(ev$bloques)), function(i) as.list(ev$bloques[i, ])), importancia = head(ev$importancia$etiqueta, 6),
  clusters = lapply(seq_len(nrow(cl$concentracion)), function(i) { r <- cl$concentracion[i, ]; list(nombre = r$nombre, pct = r$pct, fatales_x_mil = r$fatales_x_mil, pct_fatales = r$pct_fatales, peaton = r$peaton, moto = r$motociclista) }),
  k = cl$k, anio = lapply(seq_len(nrow(ev$por_anio)), function(i) as.list(ev$por_anio[i, ])),
  psi_2020 = lapply(seq_len(nrow(ev$psi_2020)), function(i) list(variable = ev$psi_2020$variable[i], psi = ev$psi_2020$psi[i], estado = as.character(ev$psi_2020$estado[i]))),
  psi_test_max = max(ev$psi_test$psi), casos = casos, fatales_perfil = ev$fatales_perfil)
write_json(out, "sustentacion_final/cifras.json", auto_unbox = TRUE, digits = 6, na = "null", pretty = TRUE)
message("cifras.json listo")
