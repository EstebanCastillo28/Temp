# ------------------------------------------------------------------
# funciones_modelado.R
# Metricas, regla de decision y utilidades comunes a 04_modelado.R,
# 05_evaluacion_interpretacion.R y al artefacto de despliegue.
# Clases (orden ordinal): Solo danos < Con heridos < Con muertos
# ------------------------------------------------------------------
CLASES <- c("Solo danos", "Con heridos", "Con muertos")

softmax <- function(z) { z <- z - apply(z, 1, max); e <- exp(z); e / rowSums(e) }

# Regla de decision sensible al costo: la clase predicha maximiza p * multiplicador.
# Los multiplicadores se ajustan SOLO con predicciones fuera de muestra (OOF) de Train.
predecir_clase <- function(p, m = c(1, 1, 1)) {
  colnames(p) <- CLASES
  factor(CLASES[max.col(sweep(p, 2, m, "*"), ties.method = "first")], levels = CLASES)
}

f1_macro <- function(pred, y) {
  cm <- table(factor(pred, CLASES), factor(y, CLASES))
  r <- diag(cm) / colSums(cm); pr <- diag(cm) / rowSums(cm)
  f <- ifelse(is.nan(pr) | (pr + r) == 0, 0, 2 * pr * r / (pr + r))
  mean(f)
}

# Busca los multiplicadores (heridos, muertos) que maximizan F1 macro sobre OOF
ajustar_multiplicadores <- function(p, y) {
  malla <- expand.grid(a = seq(0.6, 3, by = 0.2), b = exp(seq(log(1), log(80), length.out = 45)))
  malla$f1 <- apply(malla, 1, function(r) f1_macro(predecir_clase(p, c(1, r[["a"]], r[["b"]])), y))
  mejor <- malla[which.max(malla$f1), ]
  c(1, mejor$a, mejor$b)
}

metricas_clase <- function(pred, y) {
  cm <- table(Predicho = factor(pred, CLASES), Real = factor(y, CLASES))
  rec <- diag(cm) / colSums(cm); pre <- diag(cm) / rowSums(cm)
  f1 <- ifelse(is.nan(pre) | (pre + rec) == 0, 0, 2 * pre * rec / (pre + rec))
  list(cm = cm, tabla = data.frame(Clase = CLASES, Recall = as.numeric(rec), Precision = as.numeric(pre), F1 = f1, Soporte = as.numeric(colSums(cm))))
}

logloss <- function(p, y) { idx <- cbind(seq_len(nrow(p)), as.integer(factor(y, CLASES))); -mean(log(pmax(p[idx], 1e-15))) }

auc_ovr <- function(p, y) sapply(seq_along(CLASES), function(k) {   # AUC uno-contra-el-resto (Mann-Whitney)
  pos <- factor(y, CLASES) == CLASES[k]; n1 <- as.numeric(sum(pos)); n0 <- length(pos) - n1
  (sum(rank(p[, k])[pos]) - n1 * (n1 + 1) / 2) / (n1 * n0)
})

# Curva precision-recall de una clase y su area (trapecio)
pr_curva <- function(score, pos) {
  o <- order(score, decreasing = TRUE); tp <- cumsum(pos[o]); fp <- cumsum(!pos[o])
  keep <- c(diff(score[o]) != 0, TRUE)
  d <- data.frame(umbral = score[o][keep], recall = tp[keep] / sum(pos), precision = tp[keep] / (tp[keep] + fp[keep]))
  d
}
pr_auc <- function(score, pos) { d <- pr_curva(score, pos); sum(diff(c(0, d$recall)) * d$precision) }

resumen_modelo <- function(p, y, m = c(1, 1, 1)) {
  pred <- predecir_clase(p, m); mc <- metricas_clase(pred, y)
  list(cm = mc$cm, por_clase = mc$tabla, f1_macro = mean(mc$tabla$F1), recall_macro = mean(mc$tabla$Recall),
       accuracy = mean(pred == y), logloss = logloss(p, y), auc = setNames(auc_ovr(p, y), CLASES),
       pr_auc_fatal = pr_auc(p[, 3], factor(y, CLASES) == CLASES[3]))
}

# Grupos de columnas del conjunto ML por variable original (para importancia por permutacion agrupada)
grupos_variables <- function(feat) {
  g <- sub("__.*$", "", feat)
  g[grepl("^(hora|mes)_(sin|cos)$", feat)] <- sub("_(sin|cos)$", "", feat[grepl("^(hora|mes)_(sin|cos)$", feat)])
  g <- sub("_z$", "", g)
  split(feat, g)
}

# ---- Carga y prediccion generica de los modelos guardados ------------------------------------
cargar_modelo <- function(nombre, dir = "modelos") {
  m <- readRDS(file.path(dir, paste0("modelo_", nombre, ".rds"))); m$tipo <- nombre
  if (nombre == "xgboost") m$booster <- xgboost::xgb.load.raw(m$raw)
  m
}
predecir_probs <- function(m, X) {                    # X: data.frame con las columnas ML (m$features)
  if (m$tipo == "glmnet") { p <- predict(m$fit, as.matrix(X[m$features]), s = m$s, type = "response")[, , 1] }
  else if (m$tipo == "ranger") { p <- predict(m$fit, X[m$features], num.threads = 2)$predictions }
  else { p <- predict(m$booster, xgboost::xgb.DMatrix(as.matrix(X[m$features]))); if (is.null(dim(p))) p <- matrix(p, ncol = 3, byrow = TRUE) }
  p <- as.matrix(p); colnames(p) <- CLASES; p
}
