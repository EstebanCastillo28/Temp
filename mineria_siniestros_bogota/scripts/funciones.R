# ------------------------------------------------------------------
# funciones.R
# Funciones reutilizables del proyecto. Se cargan con source() desde los
# scripts y desde informe_final.Rmd (rutas relativas a la raiz del proyecto).
#
# REGLA ANTI-FUGA: toda estadistica aprendida (medianas, topes de
# winsorizacion, medias/desviaciones, niveles de factores, rotacion PCA)
# se calcula SOLO en ajustar_transformacion(train) y se aplica de forma
# idempotente con aplicar_transformacion(datos, parametros).
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(stringr); library(lubridate)})

# ---------- Utilidades de calendario -------------------------------
pascua <- function(anio) {            # algoritmo gregoriano anonimo (Meeus/Jones/Butcher)
  a <- anio %% 19; b <- anio %/% 100; c <- anio %% 100
  d <- b %/% 4; e <- b %% 4; f <- (b + 8) %/% 25; g <- (b - f + 1) %/% 3
  h <- (19 * a + b - d - g + 15) %% 30; i <- c %/% 4; k <- c %% 4
  l <- (32 + 2 * e + 2 * i - h - k) %% 7; m <- (a + 11 * h + 22 * l) %/% 451
  mes <- (h + l - 7 * m + 114) %/% 31; dia <- ((h + l - 7 * m + 114) %% 31) + 1
  as.Date(sprintf("%d-%02d-%02d", anio, mes, dia))
}
siguiente_lunes <- function(f) f + ((8 - wday(f, week_start = 1)) %% 7)  # ley Emiliani (si ya es lunes, no se mueve)

festivos_colombia <- function(anio) {
  fijos <- as.Date(sprintf("%d-%s", anio, c("01-01", "05-01", "07-20", "08-07", "12-08", "12-25")))
  emiliani <- siguiente_lunes(as.Date(sprintf("%d-%s", anio,
                 c("01-06", "03-19", "06-29", "08-15", "10-12", "11-01", "11-11"))))
  p <- pascua(anio)
  semana_santa <- c(p - 3, p - 2)                       # jueves y viernes santo (no se trasladan)
  movibles <- c(p + 43, p + 64, p + 71)                 # Ascension, Corpus Christi, Sagrado Corazon (lunes)
  sort(unique(c(fijos, emiliani, semana_santa, movibles)))
}

# ---------- Utilidades estadisticas ---------------------------------
limpiar_nombre <- function(x) {            # nombres de columna ASCII y sin simbolos
  x <- stringi::stri_trans_general(x, "Latin-ASCII"); x <- gsub("[^A-Za-z0-9]+", "_", x); gsub("^_|_$", "", x)
}
moda <- function(x) { x <- x[!is.na(x)]; names(sort(table(x), decreasing = TRUE))[1] }
winsorizar <- function(x, lim_inf, lim_sup) pmin(pmax(x, lim_inf), lim_sup)

# Reglas de deteccion de atipicos (se evaluan sobre Train)
reglas_atipicos <- function(x) {
  x <- x[!is.na(x)]
  q <- quantile(x, c(.25, .75)); iqr <- q[2] - q[1]
  z <- (x - mean(x)) / sd(x)
  tibble(n = length(x),
         iqr_15 = mean(x < q[1] - 1.5 * iqr | x > q[2] + 1.5 * iqr),
         iqr_30 = mean(x < q[1] - 3 * iqr | x > q[2] + 3 * iqr),
         z_3 = mean(abs(z) > 3),
         p995 = mean(x > quantile(x, .995)))
}

# ---------- Ajuste de parametros (SOLO TRAIN) -----------------------
VARS_NUM_WINSOR <- c("n_vehiculos", "n_clases_veh", "n_conductores", "n_vulnerables",
                     "n_involucrados", "n_vehiculos_pesados")
VARS_NUM_EDAD   <- c("edad_media", "edad_min", "edad_max")
VARS_NUM_OTRAS  <- c("prop_mujeres", "indice_heterogeneidad", "ratio_vulnerables")
VARS_CAT        <- c("clase_siniestro", "tipo_choque", "diseno_lugar", "localidad",
                     "franja_horaria", "dia_semana")
VARS_BIN <- c("fin_semana", "es_festivo", "dia_no_habil", "nocturno", "via_avenida",
              "hay_peaton", "hay_ciclista", "hay_motociclista", "hay_vulnerable",
              "hay_menor", "hay_adulto_mayor", "hay_moto_vehiculo", "hay_pesado",
              "hay_transporte_publico", "hay_fuga", "mezcla_vulnerable_pesado", "multi_vehiculo")

ajustar_transformacion <- function(train, umbral_raras = 0.005, p_winsor = 0.995) {
  P <- list(creado = Sys.time(), n_train = nrow(train), umbral_raras = umbral_raras, p_winsor = p_winsor)

  # 1) Imputacion de edad: mediana (robusta, sesgo a la derecha) calculada en Train
  P$mediana_edad <- sapply(train[VARS_NUM_EDAD], median, na.rm = TRUE)
  P$mediana_prop_mujeres <- median(train$prop_mujeres, na.rm = TRUE)

  # 2) Topes de winsorizacion (percentiles de Train)
  P$tope_sup <- sapply(train[VARS_NUM_WINSOR], quantile, probs = p_winsor, na.rm = TRUE, names = FALSE)

  # 3) Edades: se aplican a las variables ya winsorizadas/imputadas (se recalcula en cadena)
  tmp <- .paso_numerico(train, P)
  num_vars <- c(VARS_NUM_WINSOR, VARS_NUM_EDAD, VARS_NUM_OTRAS)
  P$vars_num <- num_vars
  P$media <- sapply(tmp[num_vars], mean)
  P$desvio <- sapply(tmp[num_vars], sd)

  # 4) Categoricas: niveles frecuentes en Train (resto -> "Otros"), nivel de referencia = moda
  P$niveles <- lapply(train[VARS_CAT], function(x) {
    fr <- prop.table(table(x)); names(fr)[fr >= umbral_raras]
  })
  P$referencia <- sapply(VARS_CAT, function(v) moda(train[[v]]))
  # columnas dummy (k-1): niveles frecuentes sin la referencia, + "Otros" solo si hubo agrupacion en Train
  P$niv_dummy <- lapply(VARS_CAT, function(v) {
    hay_raras <- any(!(unique(train[[v]]) %in% P$niveles[[v]]))
    setdiff(c(P$niveles[[v]], if (hay_raras) "Otros"), P$referencia[[v]])
  }); names(P$niv_dummy) <- VARS_CAT

  # 5) PCA sobre el bloque numerico estandarizado (solo Train)
  Zt <- sweep(sweep(as.matrix(tmp[num_vars]), 2, P$media, "-"), 2, P$desvio, "/")
  P$pca <- prcomp(Zt, center = FALSE, scale. = FALSE, retx = FALSE)
  P$k_pca <- which(cumsum(P$pca$sdev^2) / sum(P$pca$sdev^2) >= 0.95)[1]   # componentes que retienen >=95% de varianza
  P
}

.paso_numerico <- function(df, P) {
  for (v in VARS_NUM_EDAD) df[[v]] <- ifelse(is.na(df[[v]]), P$mediana_edad[[v]], df[[v]])
  df$prop_mujeres <- ifelse(is.na(df$prop_mujeres), P$mediana_prop_mujeres, df$prop_mujeres)
  for (v in names(P$tope_sup)) df[[v]] <- winsorizar(df[[v]], 0, P$tope_sup[[v]])
  df
}

# ---------- Aplicacion idempotente (Train, Test y despliegue) --------
aplicar_transformacion <- function(df, P) {
  df <- df %>% mutate(edad_imputada = as.integer(is.na(edad_media)))
  df_w <- .paso_numerico(df, P)
  # estandarizacion z con media/desvio de Train
  Z <- df_w
  for (v in P$vars_num) Z[[paste0(v, "_z")]] <- (df_w[[v]] - P$media[[v]]) / P$desvio[[v]]
  # categoricas: niveles raros / no vistos -> "Otros"
  for (v in names(P$niveles)) {
    x <- as.character(df_w[[v]])
    x <- ifelse(x %in% P$niveles[[v]], x, "Otros")
    Z[[paste0(v, "_agr")]] <- x
  }
  # one-hot (k-1 columnas, se omite el nivel de referencia de Train)
  dummies <- list()
  for (v in names(P$niveles)) {
    for (n in P$niv_dummy[[v]]) {
      nm <- paste0(v, "__", limpiar_nombre(n))
      dummies[[nm]] <- as.integer(Z[[paste0(v, "_agr")]] == n)
    }
  }
  X <- bind_cols(
    Z %>% select(codigo_accidente, gravedad, all_of(paste0(P$vars_num, "_z")),
                 all_of(VARS_BIN), edad_imputada,
                 hora_sin, hora_cos, mes_sin, mes_cos),
    as_tibble(dummies))
  # PCA: se proyectan las variables estandarizadas con la rotacion de Train
  Zn <- as.matrix(Z[paste0(P$vars_num, "_z")]); colnames(Zn) <- P$vars_num
  pcs <- as_tibble(predict(P$pca, Zn)[, seq_len(P$k_pca), drop = FALSE]); names(pcs) <- paste0("PC", seq_len(P$k_pca))
  list(legible = Z, ml = X, pca = bind_cols(Z %>% select(codigo_accidente, gravedad), pcs))
}
