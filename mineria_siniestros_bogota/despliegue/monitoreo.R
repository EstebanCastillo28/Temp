# ------------------------------------------------------------------
# monitoreo.R
# Funciones para vigilar el modelo en produccion:
#  - PSI (Population Stability Index) por variable entre la referencia (Train) y un lote nuevo
#  - semaforo de deriva
#  - desempeno cuando llegan las etiquetas reales (recall de la clase fatal y F1 macro)
# Regla practica: PSI < 0,10 estable · 0,10-0,25 vigilar · > 0,25 deriva importante.
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr)})

crear_referencia <- function(df, vars, n_bins = 10) {
  lapply(setNames(vars, vars), function(v) {
    x <- df[[v]]
    if (is.numeric(x) && length(unique(x)) > 10) {
      br <- unique(quantile(x, seq(0, 1, length.out = n_bins + 1), na.rm = TRUE)); br[1] <- -Inf; br[length(br)] <- Inf
      list(tipo = "num", br = br, p = as.numeric(prop.table(table(cut(x, br, include.lowest = TRUE)))))
    } else {
      x <- as.character(x); tb <- prop.table(table(x)); list(tipo = "cat", niveles = names(tb), p = as.numeric(tb))
    }
  })
}

calcular_psi <- function(ref, nuevo, eps = 1e-4) {
  bind_rows(lapply(names(ref), function(v) {
    r <- ref[[v]]; x <- nuevo[[v]]
    pn <- if (r$tipo == "num") as.numeric(table(factor(cut(x, r$br, include.lowest = TRUE), levels = levels(cut(0, r$br, include.lowest = TRUE)))))
          else as.numeric(table(factor(as.character(x), levels = r$niveles)))
    pn <- pn / sum(pn); pr <- r$p
    pn <- pmax(pn, eps); pr <- pmax(pr, eps)
    data.frame(variable = v, psi = sum((pn - pr) * log(pn / pr)))
  })) %>% mutate(estado = cut(psi, c(-Inf, 0.10, 0.25, Inf), labels = c("Estable", "Vigilar", "Deriva importante")))
}

# Lote nuevo (con columnas del esquema integrado) -> tabla de PSI y semaforo global
monitorear_lote <- function(lote, ref) {
  t <- calcular_psi(ref, lote)
  list(psi = t, semaforo = ifelse(any(t$estado == "Deriva importante"), "ROJO: reentrenar o investigar",
                           ifelse(any(t$estado == "Vigilar"), "AMARILLO: vigilar de cerca", "VERDE: estable")))
}

# Cuando llegan las etiquetas reales del lote
desempeno_lote <- function(pred, real, clases = c("Solo danos", "Con heridos", "Con muertos")) {
  cm <- table(factor(pred, clases), factor(real, clases)); r <- diag(cm) / colSums(cm); p <- diag(cm) / rowSums(cm)
  f <- ifelse(is.nan(p) | (p + r) == 0, 0, 2 * p * r / (p + r))
  list(recall_fatal = unname(r[3]), precision_fatal = unname(p[3]), f1_macro = mean(f), n = length(real), fatales = unname(colSums(cm)[3]))
}
