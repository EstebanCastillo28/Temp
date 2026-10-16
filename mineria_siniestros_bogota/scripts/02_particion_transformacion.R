# ------------------------------------------------------------------
# 02_particion_transformacion.R   (KDD fases 3-4: preprocesamiento y transformacion)
# 1) Particion ESTRATIFICADA 70/30 (semilla fija) por gravedad.
# 2) ajustar_transformacion(): estadisticas aprendidas SOLO en Train.
# 3) aplicar_transformacion(): se aplica identicamente a Train y Test.
# Salidas: datos/clean/*.rds|csv  y  modelos/parametros_transformacion.rds
# Ejecutar desde la raiz: Rscript scripts/02_particion_transformacion.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(readr)})
source("scripts/funciones.R")

SEMILLA <- 2025
int <- readRDS("datos/clean/siniestros_integrado.rds")

# ---- 1) Particion estratificada y reproducible ----------------------
set.seed(SEMILLA)
idx_train <- unlist(lapply(split(seq_len(nrow(int)), int$gravedad), function(i) sample(i, size = round(0.70 * length(i)))))
train <- int[sort(idx_train), ]
test  <- int[-idx_train, ]

# ---- 2) Ajuste de parametros SOLO con Train -------------------------
P <- ajustar_transformacion(train)
P$semilla <- SEMILLA
P$ids_train <- train$codigo_accidente

# ---- 3) Aplicacion a Train y Test -----------------------------------
tr <- aplicar_transformacion(train, P)
te <- aplicar_transformacion(test, P)
stopifnot(identical(names(tr$ml), names(te$ml)))

dir.create("modelos", showWarnings = FALSE)
saveRDS(P, "modelos/parametros_transformacion.rds")
saveRDS(tr$legible, "datos/clean/train_legible.rds"); saveRDS(te$legible, "datos/clean/test_legible.rds")
saveRDS(tr$ml, "datos/clean/train_ml.rds");           saveRDS(te$ml, "datos/clean/test_ml.rds")
saveRDS(tr$pca, "datos/clean/train_pca.rds");         saveRDS(te$pca, "datos/clean/test_pca.rds")
write_csv(tr$ml, "datos/clean/train_ml.csv.gz");      write_csv(te$ml, "datos/clean/test_ml.csv.gz")
write_csv(tr$legible %>% select(-direccion), "datos/clean/train_legible.csv.gz")
write_csv(te$legible %>% select(-direccion), "datos/clean/test_legible.csv.gz")
message("Train: ", nrow(train), " | Test: ", nrow(test), " | columnas ML: ", ncol(tr$ml))
