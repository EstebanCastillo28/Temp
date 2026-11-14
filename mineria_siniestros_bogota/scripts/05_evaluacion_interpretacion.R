# ------------------------------------------------------------------
# 05_evaluacion_interpretacion.R   (KDD fases 5-6: evaluacion e interpretacion)
# Evalua el modelo campeon sobre Test (una sola vez), analiza errores, sobreajuste,
# sesgos, importancia de variables y contrasta las hipotesis H1 y H2 con un modelo
# estadistico clasico. Genera las figuras del informe y la referencia de monitoreo.
# Salidas: resultados/evaluacion.rds, resultados/figuras/*.png, modelos/referencia_monitoreo.rds,
#          modelos/modelo_final.rds
# Ejecutar desde la raiz: Rscript scripts/05_evaluacion_interpretacion.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(ggplot2); library(scales); library(stringr); library(MASS)})
select <- dplyr::select
source("scripts/funciones.R"); source("scripts/funciones_modelado.R")
dir.create("resultados/figuras", recursive = TRUE, showWarnings = FALSE)
res <- readRDS("resultados/modelado.rds"); cl <- readRDS("resultados/clusters.rds"); P <- readRDS("modelos/parametros_transformacion.rds")
set.seed(P$semilla)
trM <- readRDS("datos/clean/train_ml.rds"); teM <- readRDS("datos/clean/test_ml.rds")
trL <- readRDS("datos/clean/train_legible.rds"); teL <- readRDS("datos/clean/test_legible.rds")
feat <- res$features; camp <- res$campeon; mod <- res$modelos[[camp]]
ytr <- res$y_train; yte <- res$y_test; p_te <- res$p_test[[camp]]; m_dec <- mod$multiplicadores
AZUL <- "#14213D"; AMBAR <- "#FCA311"; ROJO <- "#C0392B"; GRIS <- "#8D99AE"
COL_CL <- c("Solo danos" = GRIS, "Con heridos" = AMBAR, "Con muertos" = ROJO)
tema <- theme_minimal(base_size = 14) + theme(plot.title = element_text(face = "bold", colour = AZUL), legend.position = "bottom", panel.grid.minor = element_blank())
guardar <- function(p, f, w = 7, h = 4.2) ggsave(file.path("resultados/figuras", f), p, width = w, height = h, dpi = 200, bg = "white")
EV <- list(campeon = camp)

# ---------------- 1. Comparacion de modelos (CV vs Test) ----------------------------------------
comp <- bind_rows(lapply(names(res$modelos), function(n) {
  m <- res$modelos[[n]]
  data.frame(modelo = n, conjunto = c("Validación cruzada (Train)", "Prueba (Test)"),
             f1_macro = c(m$cv_ajustado$f1_macro, m$test_ajustado$f1_macro),
             recall_fatal = c(m$cv_ajustado$por_clase$Recall[3], m$test_ajustado$por_clase$Recall[3]),
             precision_fatal = c(m$cv_ajustado$por_clase$Precision[3], m$test_ajustado$por_clase$Precision[3]),
             auc_fatal = c(m$cv_ajustado$auc[3], m$test_ajustado$auc[3]), pr_auc_fatal = c(m$cv_ajustado$pr_auc_fatal, m$test_ajustado$pr_auc_fatal),
             logloss = c(m$cv_ajustado$logloss, m$test_ajustado$logloss), accuracy = c(m$cv_ajustado$accuracy, m$test_ajustado$accuracy))
}))
EV$comparacion <- comp
EV$sobreajuste <- bind_rows(lapply(names(res$modelos), function(n) data.frame(modelo = n,
  f1_train = res$resub[[n]]$f1_macro, f1_cv = res$modelos[[n]]$cv_ajustado$f1_macro, f1_test = res$modelos[[n]]$test_ajustado$f1_macro,
  ll_train = res$resub[[n]]$logloss, ll_cv = res$modelos[[n]]$cv_ajustado$logloss, ll_test = res$modelos[[n]]$test_ajustado$logloss)))
EV$argmax_vs_ajustado <- bind_rows(lapply(names(res$modelos), function(n) data.frame(modelo = n,
  f1_argmax = res$modelos[[n]]$test_argmax$f1_macro, recall_fatal_argmax = res$modelos[[n]]$test_argmax$por_clase$Recall[3], precision_fatal_argmax = res$modelos[[n]]$test_argmax$por_clase$Precision[3],
  f1_ajustado = res$modelos[[n]]$test_ajustado$f1_macro, recall_fatal_ajustado = res$modelos[[n]]$test_ajustado$por_clase$Recall[3], precision_fatal_ajustado = res$modelos[[n]]$test_ajustado$por_clase$Precision[3])))
nom_mod <- c(glmnet = "Regresión logística\nregularizada", ranger = "Bosque aleatorio", xgboost = "Gradient boosting")
guardar(comp %>% select(modelo, conjunto, `F1 macro` = f1_macro, `Recall clase fatal` = recall_fatal) %>% pivot_longer(c(`F1 macro`, `Recall clase fatal`)) %>%
  mutate(modelo = factor(nom_mod[modelo], nom_mod)) %>%
  ggplot(aes(modelo, value, fill = conjunto)) + geom_col(position = position_dodge(.75), width = .7) +
  geom_text(aes(label = format(round(value, 2), decimal.mark = ",")), position = position_dodge(.75), vjust = -.4, size = 3.8, colour = AZUL) +
  facet_wrap(~name) + scale_fill_manual(values = c(GRIS, AZUL)) + scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0, .08))) +
  labs(x = NULL, y = NULL, fill = NULL) + tema, "comparacion_modelos.png", 9, 4.2)

# ---------------- 2. Matriz de confusion, ROC y PR del campeon (Test) ----------------------------
pred_te <- predecir_clase(p_te, m_dec); mc <- metricas_clase(pred_te, yte); EV$test <- resumen_modelo(p_te, yte, m_dec)
cmd <- as.data.frame(mc$cm) %>% group_by(Real) %>% mutate(pct = Freq / sum(Freq)) %>% ungroup()
etq <- c("Solo daños", "Con heridos", "Con muertos")
guardar(ggplot(cmd, aes(Predicho, Real, fill = pct)) + geom_tile(colour = "white", linewidth = 1) +
  geom_text(aes(label = paste0(format(Freq, big.mark = ".", decimal.mark = ","), "\n(", percent(pct, 1), ")"), colour = pct > .5), size = 4.4) +
  scale_colour_manual(values = c(`TRUE` = "white", `FALSE` = AZUL), guide = "none") + scale_fill_gradient(low = "#E8EDF6", high = AZUL, labels = percent, name = "% de la clase real") +
  scale_x_discrete(labels = etq) + scale_y_discrete(labels = etq, limits = rev) + labs(x = "Clase predicha", y = "Clase real") + tema, "matriz_confusion.png", 7, 4.6)

roc_df <- bind_rows(lapply(seq_along(CLASES), function(k) {
  o <- order(p_te[, k], decreasing = TRUE); pos <- (yte == CLASES[k])[o]
  data.frame(clase = etq[k], fpr = c(0, cumsum(!pos) / sum(!pos)), tpr = c(0, cumsum(pos) / sum(pos)))
}))
auc_t <- EV$test$auc
guardar(ggplot(roc_df, aes(fpr, tpr, colour = clase)) + geom_abline(linetype = 2, colour = GRIS) + geom_line(linewidth = 1.1) +
  scale_colour_manual(values = c(GRIS, AMBAR, ROJO), labels = paste0(etq, " (AUC ", format(round(auc_t, 3), decimal.mark = ","), ")")) +
  labs(x = "Tasa de falsos positivos", y = "Recall (sensibilidad)", colour = NULL) + coord_equal() + tema + guides(colour = guide_legend(nrow = 3)), "roc.png", 6, 5.6)

pos_f <- yte == CLASES[3]
pr_df <- bind_rows(lapply(names(res$p_test), function(n) { d <- pr_curva(res$p_test[[n]][, 3], pos_f); d$modelo <- nom_mod[n]; d[seq(1, nrow(d), length.out = min(nrow(d), 800)), ] }))
guardar(ggplot(pr_df, aes(recall, precision, colour = modelo)) + geom_hline(yintercept = mean(pos_f), linetype = 2, colour = GRIS) +
  geom_line(linewidth = 1) + scale_colour_manual(values = c(GRIS, AMBAR, AZUL)) + scale_y_continuous(labels = percent, limits = c(0, 1)) + scale_x_continuous(labels = percent) +
  annotate("text", x = .8, y = mean(pos_f) + .04, label = "azar (prevalencia)", colour = GRIS, size = 4) +
  labs(x = "Recall de siniestros fatales", y = "Precisión", colour = NULL) + tema, "pr_fatal.png", 7, 4.4)

# ---------------- 3. Calibracion y niveles de riesgo ----------------------------------------------
pf <- p_te[, 3]; br <- unique(quantile(pf, c(0, .5, .75, .9, .95, .98, .99, 1))); br[1] <- 0; br[length(br)] <- 1
cal <- data.frame(pf = pf, y = pos_f) %>% mutate(bin = cut(pf, br, include.lowest = TRUE)) %>% group_by(bin) %>% summarise(pred = mean(pf), obs = mean(y), n = n(), .groups = "drop")
EV$calibracion <- cal
guardar(ggplot(cal, aes(pred, obs)) + geom_abline(linetype = 2, colour = GRIS) + geom_line(colour = AZUL) + geom_point(aes(size = n), colour = ROJO) +
  scale_x_log10(labels = percent) + scale_y_log10(labels = percent) + scale_size_continuous(labels = label_number(big.mark = "."), range = c(2, 7)) +
  labs(x = "Probabilidad predicha de muerte (escala log)", y = "Frecuencia observada (escala log)", size = "Siniestros") + tema, "calibracion.png", 6.5, 4.4)

# Niveles de riesgo (umbrales definidos con las predicciones OOF de Train)
pf_oof <- res$oof[[camp]][, 3]
t_alto <- unname(quantile(pf_oof, .95)); t_medio <- unname(quantile(pf_oof, .80))
nivel <- function(p) cut(p, c(-Inf, t_medio, t_alto, Inf), labels = c("Bajo", "Medio", "Alto"))
niv <- data.frame(nivel = nivel(pf), fatal = pos_f) %>% group_by(nivel) %>% summarise(siniestros = n(), fatales = sum(fatal), .groups = "drop") %>%
  mutate(pct_siniestros = siniestros / sum(siniestros), pct_fatales = fatales / sum(fatales), fatales_x_mil = 1000 * fatales / siniestros)
EV$niveles <- niv; EV$umbrales <- c(medio = t_medio, alto = t_alto)
guardar(ggplot(niv, aes(nivel, fatales_x_mil, fill = nivel)) + geom_col(width = .6, show.legend = FALSE) +
  geom_text(aes(label = paste0(format(round(fatales_x_mil, 1), decimal.mark = ","), " ‰\n", percent(pct_fatales, 1), " de los fatales")), vjust = -.3, size = 4, colour = AZUL) +
  scale_fill_manual(values = c(Bajo = GRIS, Medio = AMBAR, Alto = ROJO)) + scale_y_continuous(expand = expansion(mult = c(0, .3))) +
  labs(x = "Nivel de riesgo asignado por el modelo", y = "Fatales por mil siniestros (Test)") + tema, "niveles_riesgo.png", 6.5, 4.2)

# ---------------- 4. Analisis de errores y sesgos -------------------------------------------------------
ev <- teL %>% mutate(pred = pred_te, real = yte, anio = as.integer(format(fecha, "%Y")), pf = pf)
fat <- ev %>% filter(real == "Con muertos") %>% mutate(grupo = ifelse(pred == "Con muertos", "Fatal detectado", "Fatal no detectado"))
EV$fatales_perfil <- bind_rows(
  fat %>% group_by(grupo) %>% summarise(n = n(), peaton = mean(hay_peaton), motociclista = mean(hay_motociclista), ciclista = mean(hay_ciclista), nocturno = mean(nocturno),
                                          no_habil = mean(dia_no_habil), pesado = mean(hay_pesado), multi_veh = mean(multi_vehiculo), .groups = "drop"),
  ev %>% filter(pred == "Con muertos", real != "Con muertos") %>% summarise(grupo = "Falsa alarma", n = n(), peaton = mean(hay_peaton), motociclista = mean(hay_motociclista), ciclista = mean(hay_ciclista), nocturno = mean(nocturno),
                                          no_habil = mean(dia_no_habil), pesado = mean(hay_pesado), multi_veh = mean(multi_vehiculo)))
EV$confusion <- mc$cm; EV$por_clase <- mc$tabla
EV$por_anio <- ev %>% group_by(anio) %>% summarise(n = n(), fatales = sum(real == "Con muertos"), f1_macro = f1_macro(pred, real), recall_fatal = mean(pred[real == "Con muertos"] == "Con muertos"),
                                                    accuracy = mean(pred == real), .groups = "drop")
EV$por_localidad <- ev %>% group_by(localidad) %>% summarise(n = n(), fatales = sum(real == "Con muertos"), recall_fatal = ifelse(fatales > 0, mean(pred[real == "Con muertos"] == "Con muertos"), NA_real_),
                                                              alarmas = mean(pred == "Con muertos"), .groups = "drop") %>% arrange(desc(fatales))
EV$por_actor <- ev %>% mutate(perfil = case_when(hay_peaton == 1 ~ "Con peatón", hay_motociclista == 1 ~ "Con motociclista", hay_ciclista == 1 ~ "Con ciclista", TRUE ~ "Sin actor vulnerable")) %>%
  group_by(perfil) %>% summarise(n = n(), fatales = sum(real == "Con muertos"), recall_fatal = ifelse(fatales > 0, mean(pred[real == "Con muertos"] == "Con muertos"), NA_real_),
                                  precision_fatal = ifelse(sum(pred == "Con muertos") > 0, mean(real[pred == "Con muertos"] == "Con muertos"), NA_real_), .groups = "drop")
guardar(EV$por_anio %>% select(anio, `F1 macro` = f1_macro, `Recall fatal` = recall_fatal) %>% pivot_longer(-anio) %>%
  ggplot(aes(factor(anio), value, fill = name)) + geom_col(position = position_dodge(.7), width = .65) +
  geom_text(aes(label = format(round(value, 2), decimal.mark = ",")), position = position_dodge(.7), vjust = -.4, size = 3.6, colour = AZUL) +
  scale_fill_manual(values = c(AZUL, ROJO)) + scale_y_continuous(limits = c(0, 1), expand = expansion(mult = c(0, .08))) + labs(x = "Año del siniestro (Test)", y = NULL, fill = NULL) + tema, "desempeno_anio.png", 7, 3.8)

# ---------------- 5. Importancia por permutacion agrupada ---------------------------------------------------------
m_obj <- cargar_modelo(camp); grp <- grupos_variables(feat)
set.seed(P$semilla); sub <- sample(nrow(teM), 15000); Xs <- teM[sub, feat]; ys <- yte[sub]
pb <- predecir_probs(m_obj, Xs); base_ll <- logloss(pb, ys); base_f1 <- f1_macro(predecir_clase(pb, m_dec), ys)
imp <- bind_rows(lapply(names(grp), function(g) {
  r <- lapply(1:3, function(rep) { Xp <- Xs; ip <- sample(nrow(Xp)); Xp[grp[[g]]] <- Xs[ip, grp[[g]], drop = FALSE]
    pp <- predecir_probs(m_obj, Xp); c(logloss(pp, ys) - base_ll, base_f1 - f1_macro(predecir_clase(pp, m_dec), ys)) })
  r <- do.call(rbind, r); data.frame(variable = g, d_logloss = mean(r[, 1]), d_f1 = mean(r[, 2]))
})) %>% arrange(desc(d_logloss))
nom_var <- c(hay_peaton = "Peatón involucrado", clase_siniestro = "Clase de siniestro", n_vulnerables = "N.º de actores vulnerables", ratio_vulnerables = "Proporción de vulnerables",
             hay_motociclista = "Motociclista involucrado", hay_moto_vehiculo = "Moto entre los vehículos", n_vehiculos = "N.º de vehículos", multi_vehiculo = "Más de un vehículo",
             edad_media = "Edad media", edad_min = "Edad mínima", edad_max = "Edad máxima", localidad = "Localidad", franja_horaria = "Franja horaria", hora = "Hora (cíclica)",
             nocturno = "Horario nocturno", dia_semana = "Día de la semana", mes = "Mes", dia_no_habil = "Día no hábil", es_festivo = "Festivo", fin_semana = "Fin de semana",
             hay_ciclista = "Ciclista involucrado", diseno_lugar = "Diseño del lugar", tipo_choque = "Tipo de choque", via_avenida = "Vía tipo avenida", hay_pesado = "Vehículo pesado/bus",
             n_vehiculos_pesados = "N.º vehículos pesados", hay_fuga = "Vehículo en fuga", hay_transporte_publico = "Transporte público", n_conductores = "N.º de conductores",
             n_involucrados = "N.º de involucrados", n_clases_veh = "N.º de clases de vehículo", indice_heterogeneidad = "Heterogeneidad de vehículos", prop_mujeres = "Proporción de mujeres",
             hay_menor = "Menor involucrado", hay_adulto_mayor = "Adulto mayor involucrado", mezcla_vulnerable_pesado = "Vulnerable + vehículo pesado", edad_imputada = "Edad no registrada")
imp$etiqueta <- ifelse(imp$variable %in% names(nom_var), nom_var[imp$variable], imp$variable)
EV$importancia <- imp
guardar(imp %>% slice_head(n = 12) %>% ggplot(aes(reorder(etiqueta, d_logloss), d_logloss)) + geom_col(fill = AZUL, width = .7) + coord_flip() +
  geom_text(aes(label = format(round(d_logloss, 4), decimal.mark = ",")), hjust = -.1, size = 3.8, colour = AZUL) +
  scale_y_continuous(expand = expansion(mult = c(0, .2))) + labs(x = NULL, y = "Aumento del log-loss al permutar la variable (Test)") + tema, "importancia.png", 7.5, 4.8)

# ---------------- 6. Contraste de hipotesis H1 y H2: regresion logistica ordinal (Train) -------------------
d <- trL %>% mutate(gravedad = factor(as.character(gravedad), CLASES, ordered = TRUE), nocturno = factor(nocturno), dia_no_habil = factor(dia_no_habil),
                    clase_siniestro = relevel(factor(clase_siniestro), ref = "Choque"), localidad = relevel(factor(localidad), ref = "Kennedy"),
                    diseno_lugar = relevel(factor(diseno_lugar), ref = "Tramo de Via"), n_veh = pmin(n_vehiculos, 4))
fm_full <- gravedad ~ hay_peaton + hay_motociclista + hay_ciclista + nocturno + dia_no_habil + clase_siniestro + localidad + diseno_lugar + hay_pesado + n_veh
ajustar <- function(f, hess = TRUE) polr(f, data = d, Hess = hess, method = "logistic")
m_full <- ajustar(fm_full)
co <- summary(m_full)$coefficients; co <- co[!grepl("\\|", rownames(co)), ]
or <- data.frame(termino = rownames(co), OR = exp(co[, "Value"]), li = exp(co[, "Value"] - 1.96 * co[, "Std. Error"]), ls = exp(co[, "Value"] + 1.96 * co[, "Std. Error"]),
                 p = 2 * pnorm(-abs(co[, "t value"])))
EV$or <- or
bloques <- list(`Actor vulnerable` = c("hay_peaton", "hay_motociclista", "hay_ciclista"), `Clase de siniestro` = "clase_siniestro", Localidad = "localidad",
                `Momento (noche, día no hábil)` = c("nocturno", "dia_no_habil"), `Diseño del lugar` = "diseno_lugar", `Vehículo pesado y n.º de vehículos` = c("hay_pesado", "n_veh"))
vars_full <- attr(terms(fm_full), "term.labels"); ll_full <- as.numeric(logLik(m_full))
EV$bloques <- bind_rows(lapply(names(bloques), function(b) {
  f <- reformulate(setdiff(vars_full, bloques[[b]]), response = "gravedad"); mr <- ajustar(f, FALSE)
  gl <- length(coef(m_full)) - length(coef(mr))
  data.frame(bloque = b, chi2 = 2 * (ll_full - as.numeric(logLik(mr))), gl = gl) %>% mutate(p = pchisq(chi2, gl, lower.tail = FALSE))
})) %>% arrange(desc(chi2))
# Sensibilidad: el mismo modelo SIN clase de siniestro (para separar el efecto mecanico del atropello)
m_sin <- ajustar(reformulate(setdiff(vars_full, "clase_siniestro"), response = "gravedad")); cs <- summary(m_sin)$coefficients
EV$or_sin_clase <- data.frame(termino = rownames(cs), OR = exp(cs[, "Value"]))[!grepl("\\|", rownames(cs)), ]
EV$n_modelo_ordinal <- nrow(d)

# ---------------- 7. Referencia para monitoreo (distribucion de Train) y PSI -----------------------------------
source("despliegue/monitoreo.R", chdir = FALSE)
vars_mon <- c("hora", "n_vehiculos", "n_involucrados", "edad_media", "n_vulnerables", "hay_peaton", "hay_motociclista", "hay_ciclista", "nocturno", "dia_no_habil", "hay_pesado", "multi_vehiculo",
              "localidad", "clase_siniestro", "franja_horaria", "dia_semana")
ref <- crear_referencia(trL, vars_mon); saveRDS(ref, "modelos/referencia_monitoreo.rds")
todo <- bind_rows(trL, teL) %>% mutate(anio = as.integer(format(fecha, "%Y")))
EV$psi_test <- calcular_psi(ref, teL)
EV$psi_2020 <- calcular_psi(crear_referencia(todo %>% filter(anio <= 2019), vars_mon), todo %>% filter(anio == 2020))
EV$perf_2020 <- EV$por_anio
# Escenario simulado de deriva (para demostrar que el monitoreo dispara alertas): un lote en el que
# aumentan los siniestros con motociclista y los nocturnos (remuestreo ponderado de Test)
set.seed(P$semilla); w_sim <- ifelse(teL$hay_motociclista == 1, 3, 1) * ifelse(teL$nocturno == 1, 2.5, 1)
lote_sim <- teL[sample(nrow(teL), 20000, replace = TRUE, prob = w_sim / sum(w_sim)), ]
EV$psi_simulado <- calcular_psi(ref, lote_sim); EV$monitoreo_simulado <- monitorear_lote(lote_sim, ref)$semaforo

# ---------------- 8. Modelo final para el despliegue ---------------------------------------------------------------------
rangos <- sapply(c("n_vehiculos", "n_involucrados", "n_conductores", "n_vulnerables", "edad_media", "edad_min", "edad_max", "hora"), function(v) range(trL[[v]], na.rm = TRUE))
final <- list(campeon = camp, multiplicadores = m_dec, umbral_medio = t_medio, umbral_alto = t_alto, clases = CLASES, features = feat,
              metricas_test = list(f1_macro = EV$test$f1_macro, recall_fatal = EV$test$por_clase$Recall[3], precision_fatal = EV$test$por_clase$Precision[3],
                                   auc = EV$test$auc, accuracy = EV$test$accuracy, logloss = EV$test$logloss),
              niveles = niv, rangos_entrenamiento = rangos, version = "1.0", fecha = as.character(Sys.Date()), semilla = P$semilla, n_train = nrow(trM))
saveRDS(final, "modelos/modelo_final.rds")
saveRDS(EV, "resultados/evaluacion.rds")
message("Evaluacion lista. Campeon: ", camp, " | F1 macro Test = ", round(EV$test$f1_macro, 3))
