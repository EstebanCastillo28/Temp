# ------------------------------------------------------------------
# 06_agrupamiento.R   (H3: perfiles de riesgo)
# k-medias sobre el espacio PCA del conjunto ML de Train. El numero de grupos se
# elige con silueta y codo (muestra de Train); el perfil se describe con las
# variables originales (train_legible) y se verifica la estabilidad en Test.
# Salidas: modelos/clustering.rds, resultados/clusters.rds
# Ejecutar desde la raiz: Rscript scripts/06_agrupamiento.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(cluster)})
P <- readRDS("modelos/parametros_transformacion.rds"); SEMILLA <- P$semilla; set.seed(SEMILLA)
trM <- readRDS("datos/clean/train_ml.rds"); teM <- readRDS("datos/clean/test_ml.rds")
trL <- readRDS("datos/clean/train_legible.rds"); teL <- readRDS("datos/clean/test_legible.rds")
stopifnot(identical(trM$codigo_accidente, trL$codigo_accidente), identical(teM$codigo_accidente, teL$codigo_accidente))
feat <- setdiff(names(trM), c("codigo_accidente", "gravedad"))
X <- as.matrix(trM[feat]); Xt <- as.matrix(teM[feat])

# --- PCA (centrado, sin reescalar: las dummies conservan su peso 0/1) -------------
pca <- prcomp(X, center = TRUE, scale. = FALSE, retx = TRUE)
ve <- pca$sdev^2 / sum(pca$sdev^2); npc <- which(cumsum(ve) >= 0.80)[1]
Z <- pca$x[, 1:npc]; Zt <- predict(pca, Xt)[, 1:npc]

# --- Eleccion de k ------------------------------------------------------------------
ks <- 3:9; ms <- sample(nrow(Z), 20000); ss <- sample(ms, 4000)
sel <- lapply(ks, function(k) {
  km <- kmeans(Z[ms, ], centers = k, nstart = 5, iter.max = 50)
  sil <- mean(silhouette(km$cluster[match(ss, ms)], dist(Z[ss, ]))[, 3])
  data.frame(k = k, wss = km$tot.withinss, silueta = sil)
}) %>% bind_rows()
print(sel)

# --- Ajuste final ------------------------------------------------------------------
K <- sel$k[which.max(sel$silueta)]   # mayor silueta
km <- kmeans(Z, centers = K, nstart = 10, iter.max = 100)
asignar <- function(Zn) max.col(-sapply(seq_len(K), function(j) rowSums(sweep(Zn, 2, km$centers[j, ], "-")^2)))   # centroide mas cercano
cl_tr <- km$cluster; cl_te <- asignar(Zt)

# --- Perfil por grupo (variables originales) ----------------------------------------------
perfil <- function(L, cl) L %>% mutate(cluster = cl) %>% group_by(cluster) %>% summarise(
  n = n(), pct = 100 * n() / nrow(L),
  fatales_x_mil = 1000 * mean(gravedad == "Con muertos"), heridos_pct = 100 * mean(gravedad == "Con heridos"),
  peaton = 100 * mean(hay_peaton), motociclista = 100 * mean(hay_motociclista), ciclista = 100 * mean(hay_ciclista),
  pesado = 100 * mean(hay_pesado), multi_veh = 100 * mean(multi_vehiculo), nocturno = 100 * mean(nocturno),
  no_habil = 100 * mean(dia_no_habil), avenida = 100 * mean(via_avenida), edad_media = mean(edad_media), n_veh = mean(n_vehiculos),
  localidad_top = names(sort(table(localidad), decreasing = TRUE))[1], franja_top = names(sort(table(franja_horaria), decreasing = TRUE))[1],
  clase_top = names(sort(table(clase_siniestro), decreasing = TRUE))[1], .groups = "drop")
prof_tr <- perfil(trL, cl_tr); prof_te <- perfil(teL, cl_te)
print(as.data.frame(prof_tr %>% mutate(across(where(is.numeric), ~ round(.x, 1)))))

# --- Nombres interpretables (regla sobre el perfil) -----------------------------------------
nombre <- function(r) {
  base <- if (r$multi_veh < 50) {                       # eventos con un solo vehiculo
    if (r$pesado > 40) "Un solo vehículo pesado" else if (r$peaton > 40 | r$motociclista > 40) "Peatón o moto, un solo vehículo" else "Un solo vehículo"
  } else if (r$motociclista > 50) "Motociclista en choque con otro vehículo" else if (r$ciclista > 40) "Ciclista involucrado" else
    if (r$pesado > 40) "Choque con vehículo pesado o bus" else "Choque entre vehículos livianos"
  extra <- if (r$nocturno > 45) " · noche" else if (r$no_habil > 50) " · fin de semana" else ""
  paste0(base, extra)
}
nom <- vapply(seq_len(K), function(i) nombre(prof_tr[i, ]), character(1))
prof_tr$nombre <- nom; prof_te$nombre <- nom[prof_te$cluster]
cat("\nNombres:\n"); print(nom)

# Orden de riesgo y concentracion de fatales
ord <- order(-prof_tr$fatales_x_mil)
conc <- prof_tr %>% mutate(fatales = round(n * fatales_x_mil / 1000)) %>% arrange(desc(fatales_x_mil)) %>%
  mutate(pct_fatales = 100 * fatales / sum(fatales), acum_fatales = cumsum(pct_fatales), acum_siniestros = cumsum(pct))

saveRDS(list(pca_center = pca$center, rot = pca$rotation[, 1:npc], npc = npc, centers = km$centers, K = K, nombres = nom,
             perfil = prof_tr, features = feat), "modelos/clustering.rds")
saveRDS(list(seleccion = sel, k = K, npc = npc, var_acum = cumsum(ve)[npc], perfil_train = prof_tr, perfil_test = prof_te, concentracion = conc,
             Z = Z[sample(nrow(Z), 8000), 1:2], cl_muestra = NULL, silueta_final = NA, nombres = nom,
             gravedad_tr = trL$gravedad, cl_tr = cl_tr, cl_te = cl_te, gravedad_te = teL$gravedad), "resultados/clusters.rds")
message("Agrupamiento listo: k = ", K, ", ", npc, " componentes (", round(100 * cumsum(ve)[npc]), " % de varianza)")
