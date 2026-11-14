# ------------------------------------------------------------------
# 04_modelado.R   (KDD fase 5: mineria de datos)
# Compara tres clasificadores multiclase sobre el conjunto ML de Train:
#   (1) regresion logistica multinomial regularizada (glmnet)
#   (2) bosque aleatorio (ranger)
#   (3) gradient boosting (xgboost)
# Protocolo: validacion cruzada estratificada de 5 pliegues SOLO en Train para
# elegir hiperparametros y la regla de decision; Test se usa una unica vez.
# Salidas: modelos/*.rds, resultados/modelado.rds
# Ejecutar desde la raiz: Rscript scripts/04_modelado.R   (~15-25 min)
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(glmnet); library(ranger); library(xgboost)})
source("scripts/funciones_modelado.R")
P <- readRDS("modelos/parametros_transformacion.rds")
SEMILLA <- P$semilla; K_FOLDS <- 5; NT <- 4
set.seed(SEMILLA)

tr <- readRDS("datos/clean/train_ml.rds"); te <- readRDS("datos/clean/test_ml.rds")
feat <- setdiff(names(tr), c("codigo_accidente", "gravedad"))
ytr <- factor(as.character(tr$gravedad), CLASES); yte <- factor(as.character(te$gravedad), CLASES)
X <- as.matrix(tr[feat]); Xt <- as.matrix(te[feat]); y0 <- as.integer(ytr) - 1L

# Pliegues estratificados (misma particion para los tres modelos)
foldid <- integer(nrow(tr))
for (cl in CLASES) { i <- which(ytr == cl); foldid[i] <- sample(rep_len(seq_len(K_FOLDS), length(i))) }

log_msg <- function(...) message(format(Sys.time(), "%H:%M:%S"), " | ", ...)
res <- list(semilla = SEMILLA, k_folds = K_FOLDS, features = feat, n_train = nrow(tr), n_test = nrow(te))

# ======================= 0. Linea base ingenua ===================================
base_pred <- factor(rep("Solo danos", length(yte)), CLASES)
res$base <- list(accuracy = mean(base_pred == yte), por_clase = metricas_clase(base_pred, yte)$tabla)

# ======================= 1. glmnet =============================================
log_msg("glmnet: validacion cruzada")
cvs <- lapply(c(0.5, 1), function(a) {
  cv.glmnet(X, ytr, family = "multinomial", alpha = a, foldid = foldid, type.measure = "deviance",
            type.multinomial = "grouped", nlambda = 20, lambda.min.ratio = 1e-4, thresh = 1e-4, keep = TRUE)
})
best <- which.min(sapply(cvs, function(f) min(f$cvm))); cvg <- cvs[[best]]
alpha_g <- c(0.5, 1)[best]; lam_g <- cvg$lambda.min; li <- which(cvg$lambda == lam_g)
oof_glmnet <- softmax(cvg$fit.preval[, , li])
colnames(oof_glmnet) <- CLASES
fit_glmnet <- glmnet(X, ytr, family = "multinomial", alpha = alpha_g, lambda = cvg$lambda, type.multinomial = "grouped", thresh = 1e-4)
p_te_glmnet <- predict(fit_glmnet, Xt, s = lam_g, type = "response")[, , 1]; colnames(p_te_glmnet) <- CLASES
p_tr_glmnet <- predict(fit_glmnet, X, s = lam_g, type = "response")[, , 1]; colnames(p_tr_glmnet) <- CLASES
res$glmnet_cv <- data.frame(alpha = c(0.5, 1), deviance_cv = sapply(cvs, function(f) min(f$cvm)))
res$glmnet_param <- list(alpha = alpha_g, lambda = lam_g)
saveRDS(list(fit = fit_glmnet, s = lam_g, alpha = alpha_g, features = feat), "modelos/modelo_glmnet.rds")

# ======================= 2. ranger =============================================
log_msg("ranger: validacion cruzada")
grid_rf <- data.frame(mtry = c(10, 20, 10), min.node.size = c(50, 50, 200))
oof_rf_all <- vector("list", nrow(grid_rf))
for (g in seq_len(nrow(grid_rf))) {
  oof <- matrix(NA_real_, nrow(tr), 3, dimnames = list(NULL, CLASES))
  for (k in seq_len(K_FOLDS)) {
    i <- foldid == k
    m <- ranger(x = tr[!i, feat], y = ytr[!i], num.trees = 250, mtry = grid_rf$mtry[g], min.node.size = grid_rf$min.node.size[g],
                probability = TRUE, num.threads = NT, seed = SEMILLA)
    oof[i, ] <- predict(m, tr[i, feat], num.threads = NT)$predictions[, CLASES]
  }
  oof_rf_all[[g]] <- oof; log_msg("  ranger config ", g, " logloss OOF = ", round(logloss(oof, ytr), 4))
}
grid_rf$logloss_cv <- sapply(oof_rf_all, logloss, y = ytr)
g_best <- which.min(grid_rf$logloss_cv); oof_rf <- oof_rf_all[[g_best]]
fit_rf <- ranger(x = tr[feat], y = ytr, num.trees = 500, mtry = grid_rf$mtry[g_best], min.node.size = grid_rf$min.node.size[g_best],
                 probability = TRUE, num.threads = NT, seed = SEMILLA)
p_te_rf <- predict(fit_rf, te[feat], num.threads = NT)$predictions[, CLASES]


res$ranger_cv <- grid_rf
saveRDS(list(fit = fit_rf, features = feat), "modelos/modelo_ranger.rds")

# ======================= 3. xgboost ============================================
log_msg("xgboost: validacion cruzada")
pred_xgb <- function(m, dm) { p <- predict(m, dm); if (is.null(dim(p))) p <- matrix(p, ncol = 3, byrow = TRUE); colnames(p) <- CLASES; p }
dtr <- xgb.DMatrix(X, label = y0); dte <- xgb.DMatrix(Xt)
grid_xgb <- data.frame(max_depth = c(3, 5, 7), min_child_weight = c(10, 10, 20))
oof_xgb_all <- list(); nr <- integer(nrow(grid_xgb))
for (g in seq_len(nrow(grid_xgb))) {
  prm <- list(objective = "multi:softprob", num_class = 3, eval_metric = "mlogloss", eta = 0.08, max_depth = grid_xgb$max_depth[g],
              min_child_weight = grid_xgb$min_child_weight[g], subsample = 0.8, colsample_bytree = 0.8, nthread = NT)
  cv <- xgb.cv(params = prm, data = dtr, nrounds = 600, folds = lapply(seq_len(K_FOLDS), function(k) which(foldid == k)),
               early_stopping_rounds = 30, verbose = 0, stratified = TRUE)
  el <- as.data.frame(cv$evaluation_log); nr[g] <- el$iter[which.min(el$test_mlogloss_mean)]
  oof <- matrix(NA_real_, nrow(tr), 3, dimnames = list(NULL, CLASES))
  for (k in seq_len(K_FOLDS)) {
    i <- foldid == k
    m <- xgb.train(params = prm, data = xgb.DMatrix(X[!i, ], label = y0[!i]), nrounds = nr[g], verbose = 0)
    oof[i, ] <- pred_xgb(m, xgb.DMatrix(X[i, ]))
  }
  oof_xgb_all[[g]] <- oof; log_msg("  xgboost config ", g, " (", nr[g], " rondas) logloss OOF = ", round(logloss(oof, ytr), 4))
}
grid_xgb$nrounds <- nr; grid_xgb$logloss_cv <- sapply(oof_xgb_all, logloss, y = ytr)
gx <- which.min(grid_xgb$logloss_cv); oof_xgb <- oof_xgb_all[[gx]]
prm_final <- list(objective = "multi:softprob", num_class = 3, eval_metric = "mlogloss", eta = 0.08, max_depth = grid_xgb$max_depth[gx],
                  min_child_weight = grid_xgb$min_child_weight[gx], subsample = 0.8, colsample_bytree = 0.8, nthread = NT)
fit_xgb <- xgb.train(params = prm_final, data = dtr, nrounds = nr[gx], verbose = 0)
p_te_xgb <- pred_xgb(fit_xgb, dte)
p_tr_xgb <- pred_xgb(fit_xgb, xgb.DMatrix(X)); res$xgb_cv <- grid_xgb
saveRDS(list(raw = xgb.save.raw(fit_xgb), features = feat, params = prm_final, nrounds = nr[gx]), "modelos/modelo_xgboost.rds")

# ======================= 3b. Experimento de desbalance: ponderacion de clases ======================
# Se compara con el mismo xgboost (hiperparametros elegidos) entrenado con pesos inversos a la frecuencia de clase
log_msg("Experimento: xgboost con pesos de clase")
w_cls <- as.numeric((length(ytr) / (3 * table(ytr)))[as.character(ytr)])
oof_w <- matrix(NA_real_, nrow(tr), 3, dimnames = list(NULL, CLASES))
for (k in seq_len(K_FOLDS)) {
  i <- foldid == k
  m <- xgb.train(params = prm_final, data = xgb.DMatrix(X[!i, ], label = y0[!i], weight = w_cls[!i]), nrounds = nr[gx], verbose = 0)
  oof_w[i, ] <- pred_xgb(m, xgb.DMatrix(X[i, ]))
}
fit_w <- xgb.train(params = prm_final, data = xgb.DMatrix(X, label = y0, weight = w_cls), nrounds = nr[gx], verbose = 0)
p_te_w <- pred_xgb(fit_w, dte); mult_w <- ajustar_multiplicadores(oof_w, ytr)
res$desbalance <- list(
  sin_tratamiento_argmax = list(cv = resumen_modelo(oof_xgb, ytr), test = resumen_modelo(p_te_xgb, yte)),
  sin_tratamiento_regla = list(cv = resumen_modelo(oof_xgb, ytr, ajustar_multiplicadores(oof_xgb, ytr)), test = resumen_modelo(p_te_xgb, yte, ajustar_multiplicadores(oof_xgb, ytr))),
  pesos_argmax = list(cv = resumen_modelo(oof_w, ytr), test = resumen_modelo(p_te_w, yte)),
  pesos_regla = list(cv = resumen_modelo(oof_w, ytr, mult_w), test = resumen_modelo(p_te_w, yte, mult_w)))

# ======================= Regla de decision (solo OOF de Train) ===================
log_msg("Ajuste de la regla de decision con OOF")
oofs <- list(glmnet = oof_glmnet, ranger = oof_rf, xgboost = oof_xgb)
p_te <- list(glmnet = p_te_glmnet, ranger = p_te_rf, xgboost = p_te_xgb)
mult <- lapply(oofs, ajustar_multiplicadores, y = ytr)

res$modelos <- lapply(names(oofs), function(n) {
  list(nombre = n, multiplicadores = mult[[n]],
       cv_argmax = resumen_modelo(oofs[[n]], ytr), cv_ajustado = resumen_modelo(oofs[[n]], ytr, mult[[n]]),
       test_argmax = resumen_modelo(p_te[[n]], yte), test_ajustado = resumen_modelo(p_te[[n]], yte, mult[[n]]))
}); names(res$modelos) <- names(oofs)
res$oof <- oofs; res$p_test <- p_te; res$y_train <- ytr; res$y_test <- yte
# Resustitucion en Train (para evidenciar sobreajuste); ranger usa una muestra
res$resub <- list(glmnet = resumen_modelo(p_tr_glmnet, ytr, mult$glmnet), xgboost = resumen_modelo(p_tr_xgb, ytr, mult$xgboost))
set.seed(SEMILLA); ii <- sample(nrow(tr), 30000)
res$resub$ranger <- resumen_modelo(predict(fit_rf, tr[ii, feat], num.threads = NT)$predictions[, CLASES], ytr[ii], mult$ranger)

# Campeon: mayor F1 macro OOF con la regla ajustada (desempate: menor logloss)
tabla <- data.frame(modelo = names(oofs), f1_cv = sapply(res$modelos, function(m) m$cv_ajustado$f1_macro),
                    ll_cv = sapply(res$modelos, function(m) m$cv_ajustado$logloss))
res$tabla_seleccion <- tabla; campeon <- tabla$modelo[order(-round(tabla$f1_cv, 3), tabla$ll_cv)][1]; res$campeon <- campeon
log_msg("Campeon por CV: ", campeon); print(tabla)
saveRDS(res, "resultados/modelado.rds")
log_msg("Listo")
