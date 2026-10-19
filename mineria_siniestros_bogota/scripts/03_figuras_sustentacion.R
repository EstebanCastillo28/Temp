# ------------------------------------------------------------------
# 03_figuras_sustentacion.R
# Figuras (letra grande, para proyectar) y cifras clave de la sustentacion.
# Salida: presentacion/figuras/*.png  y  presentacion/cifras.rds
# Ejecutar desde la raiz: Rscript scripts/03_figuras_sustentacion.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(tidyr); library(ggplot2); library(scales); library(stringr)})
source("scripts/funciones.R")
dir.create("presentacion/figuras", recursive = TRUE, showWarnings = FALSE)
aud <- readRDS("resultados/auditoria_limpieza.rds"); int <- readRDS("datos/clean/siniestros_integrado.rds")
P <- readRDS("modelos/parametros_transformacion.rds")
trL <- readRDS("datos/clean/train_legible.rds"); trM <- readRDS("datos/clean/train_ml.rds")
tr_pre <- int %>% filter(codigo_accidente %in% P$ids_train)
AZUL <- "#14213D"; AMBAR <- "#FCA311"; ROJO <- "#C0392B"; GRIS <- "#8D99AE"; CLARO <- "#E5E9F0"
tema <- theme_minimal(base_size = 18) +
  theme(plot.title = element_text(face = "bold", size = 18, colour = AZUL), axis.title = element_text(colour = AZUL),
        panel.grid.minor = element_blank(), strip.text = element_text(face = "bold", size = 17), legend.position = "bottom")
guardar <- function(p, f, w = 7, h = 4.2) ggsave(file.path("presentacion/figuras", f), p, width = w, height = h, dpi = 200, bg = "white")
fm <- label_number(big.mark = ".", decimal.mark = ",")

# 1) Tasa de fatalidad por perfil de actor (apertura)
da <- trL %>% mutate(perfil = case_when(hay_peaton == 1 ~ "Con peatón", hay_ciclista == 1 & hay_motociclista == 0 ~ "Con ciclista",
        hay_motociclista == 1 ~ "Con motociclista", TRUE ~ "Sin actor vulnerable")) %>%
  group_by(perfil) %>% summarise(n = n(), tasa = 1000 * mean(gravedad == "Con muertos"), .groups = "drop")
guardar(ggplot(da, aes(reorder(perfil, tasa), tasa, fill = perfil == "Sin actor vulnerable")) + geom_col(width = .65, show.legend = FALSE) +
  geom_text(aes(label = format(round(tasa, 1), decimal.mark = ",")), hjust = -.15, size = 6, colour = AZUL, fontface = "bold") + coord_flip() +
  scale_fill_manual(values = c(`TRUE` = GRIS, `FALSE` = ROJO)) + scale_y_continuous(expand = expansion(mult = c(0, .2))) +
  labs(x = NULL, y = "Siniestros fatales por cada 1.000 siniestros") + tema, "f1_perfil_actor.png", 7, 3.6)

# 2) Edad antes / despues (zoom a la cola: el pico en 118 es invisible en la escala completa)
ed <- bind_rows(tibble(edad = aud$edad_distribucion_antes, m = "Antes"), tibble(edad = aud$edad_distribucion_despues, m = "Después")) %>%
  filter(!is.na(edad), edad >= 85) %>% mutate(m = factor(m, c("Antes", "Después")))
guardar(ggplot(ed, aes(edad)) + geom_histogram(binwidth = 1, boundary = 0, fill = AZUL, colour = "white", linewidth = .1) + facet_wrap(~m) +
  geom_text(data = tibble(m = factor("Antes", c("Antes", "Después")), x = 112, y = 300), aes(x = x, y = y, label = "118: 282"), colour = ROJO, size = 6, fontface = "bold", inherit.aes = FALSE, hjust = 1) +
  scale_y_continuous(labels = fm, limits = c(0, 360)) + labs(x = "Edad (años), cola ≥ 85", y = "Actores") + tema, "f2_edad_antes_despues.png", 8, 3.8)

# 3) Faltantes: gravedad segun edad faltante
tr_pre$edad_na <- ifelse(is.na(tr_pre$edad_media), "Sin edad registrada", "Con edad registrada")
dn <- tr_pre %>% count(edad_na, gravedad) %>% group_by(edad_na) %>% mutate(p = n / sum(n))
guardar(ggplot(dn, aes(edad_na, p, fill = gravedad)) + geom_col(width = .55) +
  geom_text(aes(label = ifelse(gravedad != "Con muertos", percent(p, .1, decimal.mark = ","), "")), position = position_stack(vjust = .5), colour = "white", size = 5.5, fontface = "bold") +
  geom_text(data = dn %>% filter(gravedad == "Con muertos"), aes(x = as.numeric(factor(edad_na)) + .33, y = p / 2, label = paste0(percent(p, .1, decimal.mark = ","))),
            colour = ROJO, size = 6, fontface = "bold", hjust = 0, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Solo danos" = GRIS, "Con heridos" = AMBAR, "Con muertos" = ROJO), labels = c("Solo daños", "Con heridos", "Con muertos")) +
  scale_x_discrete(expand = expansion(add = c(.5, 1.1))) +
  scale_y_continuous(labels = percent) + labs(x = NULL, y = NULL, fill = NULL) + tema, "f3_faltante_informativo.png", 8, 4.2)

# 4) Outliers: boxplot antes / despues
vv <- c("n_vehiculos", "n_involucrados", "n_vulnerables")
bx <- bind_rows(tr_pre %>% select(all_of(vv)) %>% mutate(m = "Antes"), trL %>% select(all_of(vv)) %>% mutate(m = "Después")) %>%
  pivot_longer(-m) %>% mutate(m = factor(m, c("Antes", "Después")))
guardar(ggplot(bx, aes(m, value)) + geom_boxplot(fill = "#BFD0EA", colour = AZUL, outlier.size = .7, outlier.colour = ROJO) +
  facet_wrap(~name, scales = "free_y") + labs(x = NULL, y = NULL) + tema, "f4_outliers_box.png", 9, 3.9)

# 5) Normalizacion antes / despues
v2 <- c("edad_media", "ratio_vulnerables")
a <- tr_pre %>% select(all_of(v2)) %>% pivot_longer(everything()) %>% mutate(m = "Antes")
d <- trL %>% select(all_of(paste0(v2, "_z"))) %>% rename_with(~ str_remove(.x, "_z")) %>% pivot_longer(everything()) %>% mutate(m = "Después (Z)")
guardar(ggplot(bind_rows(a, d) %>% filter(!is.na(value)) %>% mutate(m = factor(m, c("Antes", "Después (Z)"))), aes(value)) +
  geom_histogram(bins = 30, fill = AZUL, colour = "white", linewidth = .1) + facet_wrap(vars(m, name), ncol = 2, scales = "free") +
  scale_y_continuous(labels = fm) + labs(x = NULL, y = "Siniestros") + tema + theme(axis.text = element_text(size = 13)), "f5_normalizacion.png", 8, 4.6)

# 6) PCA varianza
ve <- P$pca$sdev^2 / sum(P$pca$sdev^2)
guardar(ggplot(tibble(PC = seq_along(ve), v = ve, a = cumsum(ve)), aes(PC)) + geom_col(aes(y = v), fill = "#BFD0EA") +
  geom_line(aes(y = a), colour = ROJO, linewidth = 1.2) + geom_point(aes(y = a), colour = ROJO, size = 3) + geom_hline(yintercept = .95, linetype = 2, colour = GRIS) +
  annotate("text", x = 10.5, y = .90, label = "95 %", colour = GRIS, size = 5.5) +
  scale_x_continuous(breaks = seq_along(ve)) + scale_y_continuous(labels = percent) + labs(x = "Componente principal", y = "Varianza") + tema, "f6_pca.png", 7, 4)

# 7) Comparacion de reglas de outliers (n_vehiculos)
ro <- reglas_atipicos(tr_pre$n_vehiculos)
guardar(ggplot(tibble(r = factor(c("IQR 1,5", "Z > 3", "P99,5"), c("IQR 1,5", "Z > 3", "P99,5")), p = 100 * c(ro$iqr_15, ro$z_3, ro$p995)),
  aes(r, p, fill = r == "P99,5")) + geom_col(width = .6, show.legend = FALSE) +
  geom_text(aes(label = paste0(format(round(p, 1), decimal.mark = ","), " %")), vjust = -.4, size = 6, colour = AZUL, fontface = "bold") +
  scale_fill_manual(values = c(`TRUE` = AMBAR, `FALSE` = GRIS)) + scale_y_continuous(expand = expansion(mult = c(0, .15))) +
  labs(x = NULL, y = "% de Train atípico") + tema, "f7_reglas_iqr.png", 5.2, 3.8)

# Cifras clave y ejemplo antes/despues (head)
ej <- tr_pre %>% filter(codigo_accidente %in% trM$codigo_accidente) %>% slice(c(5, 40, 90)) %>%
  select(codigo_accidente, localidad, franja_horaria, n_vehiculos, edad_media, hay_peaton) %>%
  left_join(trM %>% select(codigo_accidente, matches("^localidad__Bosa$|^franja_horaria__Noche|^n_vehiculos_z$|^edad_media_z$")), by = "codigo_accidente")
saveRDS(list(ejemplo = ej, ve = ve, k = P$k_pca, n_ml = ncol(trM), n_train = nrow(tr_pre), tope = P$tope_sup, med = P$mediana_edad,
             fatal_na = mean(tr_pre$gravedad[is.na(tr_pre$edad_media)] == "Con muertos"), fatal_ok = mean(tr_pre$gravedad[!is.na(tr_pre$edad_media)] == "Con muertos"),
             fuga_na = mean(tr_pre$hay_fuga[is.na(tr_pre$edad_media)]), fuga_ok = mean(tr_pre$hay_fuga[!is.na(tr_pre$edad_media)]),
             n_na = sum(is.na(tr_pre$edad_media)), da = da, ro = ro), "presentacion/cifras.rds")
message("Figuras listas")
