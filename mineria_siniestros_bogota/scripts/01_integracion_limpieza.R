# ------------------------------------------------------------------
# 01_integracion_limpieza.R   (KDD fases 2-3: seleccion, integracion, limpieza)
# Lee datos/raw/*.csv, aplica limpieza DETERMINISTA (reglas de dominio que no
# aprenden nada de los datos), integra Siniestros + Actor Vial + Vehiculos a
# nivel de siniestro y guarda datos/clean/siniestros_integrado.rds.
# Todo contador de auditoria se guarda en resultados/auditoria_limpieza.rds.
# Las estadisticas aprendidas (imputacion, topes, escalas) se calculan en
# 02_particion_transformacion.R, DESPUES de separar Train/Test.
# Ejecutar desde la raiz: Rscript scripts/01_integracion_limpieza.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(readr); library(dplyr); library(tidyr); library(stringr); library(lubridate)})
source("scripts/funciones.R")
if (!l10n_info()[["UTF-8"]]) warning("Se recomienda ejecutar R con locale UTF-8 (p. ej. LC_ALL=C.UTF-8)")
dir.create("datos/clean", showWarnings = FALSE, recursive = TRUE); dir.create("resultados", showWarnings = FALSE)

rd <- function(f) read_csv(file.path("datos/raw", f), col_types = cols(.default = col_character()),
                           na = c("", "NA"), progress = FALSE)
sin <- rd("SINIESTROS.csv"); act <- rd("ACTOR_VIAL.csv"); veh <- rd("VEHICULOS.csv"); dic <- rd("DICCIONARIO.csv")
aud <- list(filas_raw = c(siniestros = nrow(sin), actores = nrow(act), vehiculos = nrow(veh)))

# ---- Diccionario oficial -> etiquetas ------------------------------
etq <- function(hoja, campo, codigos) {
  d <- dic %>% filter(HOJA == hoja, CAMPO == campo)
  unname(setNames(d$DESCRIPCION, d$CODIGO)[as.character(codigos)])
}

# ---- Duplicados exactos y llaves ------------------------------------
aud$duplicados_exactos <- c(siniestros = sum(duplicated(sin)), actores = sum(duplicated(act)), vehiculos = sum(duplicated(veh)))
aud$llaves_duplicadas  <- c(siniestros = sum(duplicated(sin$CODIGO_ACCIDENTE)), actores = sum(duplicated(act$CODIGO_ACCIDENTADO)),
                            vehiculos = sum(duplicated(veh$VEHICULO)))
aud$huerfanos <- c(actores = sum(!act$CODIGO_ACCIDENTE %in% sin$CODIGO_ACCIDENTE),
                   vehiculos = sum(!veh$CODIGO_ACCIDENTE %in% sin$CODIGO_ACCIDENTE))

# ======================================================================
# SINIESTROS
# ======================================================================
s <- sin %>% transmute(
  codigo_accidente = CODIGO_ACCIDENTE,
  fecha = dmy(FECHA), hora_txt = HORA,
  gravedad_original = as.integer(GRAVEDAD),
  clase_cod = as.integer(CLASE), choque_cod = as.integer(CHOQUE), objeto_cod = as.integer(OBJETO_FIJO),
  direccion = str_squish(str_to_upper(DIRECCION)),
  localidad_cod = as.integer(CODIGO_LOCALIDAD), diseno_cod = as.integer(DISENO_LUGAR))
aud$direcciones_espacios <- sum(str_detect(sin$DIRECCION, "\\s{2,}") | sin$DIRECCION != str_trim(sin$DIRECCION))
aud$fechas_invalidas <- sum(is.na(s$fecha))
h <- hms(s$hora_txt); aud$horas_invalidas <- sum(is.na(h))
s$hora <- hour(h) + minute(h) / 60

# codigos fuera del diccionario (categorias ambiguas)
fuera <- function(hoja, campo, x) sum(!is.na(x) & is.na(etq(hoja, campo, x)))
aud$codigos_no_documentados <- c(choque = fuera("SINIESTROS", "CHOQUE", s$choque_cod),
                                 objeto_fijo = fuera("SINIESTROS", "OBJETO_FIJO", s$objeto_cod),
                                 clase = fuera("SINIESTROS", "CLASE", s$clase_cod),
                                 localidad = fuera("SINIESTROS", "CODIGO_LOCALIDAD", s$localidad_cod),
                                 diseno = fuera("SINIESTROS", "DISENO_LUGAR", s$diseno_cod))
aud$nulos_siniestros <- colSums(is.na(sin)) / nrow(sin)
aud$choque_nulo_por_clase <- table(clase = etq("SINIESTROS", "CLASE", s$clase_cod), choque_nulo = is.na(s$choque_cod))

s <- s %>% mutate(
  clase_siniestro = etq("SINIESTROS", "CLASE", clase_cod),
  # NA estructural: CHOQUE solo se diligencia cuando la clase es "Choque"
  tipo_choque = case_when(
    !is.na(choque_cod) & is.na(etq("SINIESTROS", "CHOQUE", choque_cod)) ~ "Otro (codigo no documentado)",
    !is.na(choque_cod) ~ etq("SINIESTROS", "CHOQUE", choque_cod),
    clase_cod == 1 ~ "Sin informacion",
    TRUE ~ "No aplica (no es choque)"),
  diseno_lugar = etq("SINIESTROS", "DISENO_LUGAR", diseno_cod),
  localidad = etq("SINIESTROS", "CODIGO_LOCALIDAD", localidad_cod),
  via_avenida = as.integer(str_detect(direccion, "^(AV|AK|AC|AU) ")),
  anio = year(fecha), mes = month(fecha),
  dia_semana = factor(c("Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo")[wday(fecha, week_start = 1)],
                      levels = c("Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo")),
  fin_semana = as.integer(wday(fecha, week_start = 1) >= 6),
  es_festivo = as.integer(fecha %in% do.call(c, lapply(2015:2020, festivos_colombia))),
  dia_no_habil = as.integer(fin_semana == 1 | es_festivo == 1),
  franja_horaria = factor(case_when(
      hora < 6  ~ "Madrugada (00-05h)", hora < 9 ~ "Pico AM (06-08h)", hora < 16 ~ "Valle diurno (09-15h)",
      hora < 20 ~ "Pico PM (16-19h)", TRUE ~ "Noche (20-23h)"),
      levels = c("Madrugada (00-05h)", "Pico AM (06-08h)", "Valle diurno (09-15h)", "Pico PM (16-19h)", "Noche (20-23h)")),
  nocturno = as.integer(hora >= 20 | hora < 6),
  hora_sin = sin(2 * pi * hora / 24), hora_cos = cos(2 * pi * hora / 24),
  mes_sin = sin(2 * pi * mes / 12), mes_cos = cos(2 * pi * mes / 12))
aud$festivos_detectados <- sum(s$es_festivo)

# ======================================================================
# ACTOR VIAL (limpieza a nivel de actor y agregacion)
# ======================================================================
a <- act %>% transmute(codigo_accidente = CODIGO_ACCIDENTE, condicion = CONDICION, estado = ESTADO,
                       edad_raw = EDAD, sexo = SEXO)
a <- a %>% mutate(
  edad = suppressWarnings(as.numeric(edad_raw)),
  motor = condicion %in% c("CONDUCTOR", "MOTOCICLISTA"))
aud$edad_sin_info <- sum(is.na(a$edad) & a$edad_raw == "SIN INFORMACION", na.rm = TRUE)
aud$edad_centinela_118 <- sum(a$edad == 118, na.rm = TRUE)
aud$edad_ge110 <- sum(a$edad >= 110, na.rm = TRUE)
aud$edad_motor_lt10 <- sum(a$motor & a$edad < 10, na.rm = TRUE)
aud$edad_distribucion_antes <- a$edad
# Reglas de dominio: >=110 anios es codigo centinela/imposible; conducir o pilotar con <10 anios es imposible
a <- a %>% mutate(edad = ifelse(edad >= 110 | (motor & edad < 10), NA, edad),
                  sexo = ifelse(sexo == "SIN INFORMACION", NA, sexo))
aud$edad_distribucion_despues <- a$edad
aud$nulos_edad_por_condicion <- a %>% group_by(condicion) %>% summarise(n = n(), pct_nulo = mean(is.na(edad)), .groups = "drop")
aud$nulos_edad_por_anio <- a %>% left_join(s %>% select(codigo_accidente, anio), by = "codigo_accidente") %>%
  group_by(anio) %>% summarise(pct_nulo = mean(is.na(edad)), .groups = "drop")
aud$pasajeros_por_estado <- table(condicion = a$condicion, estado = a$estado)
stopifnot(any(str_starts(a$condicion, "PASAJERO")))   # verificacion: la categoria existe y se excluye mas abajo

# Estado del actor -> gravedad "verificada" (SOLO para auditar la variable objetivo; NO es predictor)
estado_sin <- a %>% group_by(codigo_accidente) %>%
  summarise(n_muertos = sum(estado == "MUERTO"), n_heridos = sum(estado == "HERIDO"), n_actores_reg = n(), .groups = "drop") %>%
  mutate(gravedad_actores = case_when(n_muertos > 0 ~ 1L, n_heridos > 0 ~ 2L, TRUE ~ 3L))

# Predictores de actores: se excluyen pasajeros (solo se registran si resultan lesionados -> fuga de objetivo)
ai <- a %>% filter(!str_starts(condicion, "PASAJERO"))   # sin literales no-ASCII: independiente del locale
feat_act <- ai %>% group_by(codigo_accidente) %>% summarise(
  n_conductores = sum(condicion == "CONDUCTOR"), n_peatones = sum(condicion == "PEATON"),
  n_ciclistas = sum(condicion == "CICLISTA"), n_motociclistas = sum(condicion == "MOTOCICLISTA"),
  n_involucrados = n(),
  edad_media = ifelse(all(is.na(edad)), NA_real_, mean(edad, na.rm = TRUE)),
  edad_min = ifelse(all(is.na(edad)), NA_real_, min(edad, na.rm = TRUE)),
  edad_max = ifelse(all(is.na(edad)), NA_real_, max(edad, na.rm = TRUE)),
  prop_mujeres = ifelse(all(is.na(sexo)), NA_real_, mean(sexo[!is.na(sexo)] == "FEMENINO")),
  hay_menor = as.integer(any(edad < 18, na.rm = TRUE)),
  hay_adulto_mayor = as.integer(any(edad >= 65, na.rm = TRUE)), .groups = "drop") %>%
  mutate(n_vulnerables = n_peatones + n_ciclistas + n_motociclistas,
         hay_peaton = as.integer(n_peatones > 0), hay_ciclista = as.integer(n_ciclistas > 0),
         hay_motociclista = as.integer(n_motociclistas > 0), hay_vulnerable = as.integer(n_vulnerables > 0),
         ratio_vulnerables = n_vulnerables / n_involucrados)

# ======================================================================
# VEHICULOS
# ======================================================================
grupo_veh <- function(cod) case_when(
  cod %in% c(10, 17) ~ "moto", cod %in% c(13, 28) ~ "bicicleta",
  cod %in% c(1, 5, 6, 22) ~ "liviano", cod %in% c(2, 3, 7, 19, 20, 27) ~ "bus",
  cod %in% c(4, 8, 9, 11, 12, 25, 26) ~ "carga_pesada", TRUE ~ "otro")
v <- veh %>% transmute(codigo_accidente = CODIGO_ACCIDENTE, clase_cod = as.integer(CLASE),
                       servicio = as.integer(SERVICIO), modalidad = MODALIDAD, enfuga = ENFUGA)
aud$nulos_vehiculos <- colSums(is.na(veh)) / nrow(veh)
aud$modalidad_nula_por_servicio <- table(servicio = etq("VEHICULOS", "SERVICIO", v$servicio) %>% replace_na("NA"),
                                         modalidad_nula = is.na(v$modalidad))
v <- v %>% mutate(grupo = grupo_veh(clase_cod), clase_cod = ifelse(is.na(clase_cod), 18L, clase_cod))  # 18 = "No identificado" en el diccionario
feat_veh <- v %>% group_by(codigo_accidente) %>% summarise(
  n_vehiculos = n(), n_clases_veh = n_distinct(clase_cod),
  indice_heterogeneidad = 1 - sum((table(clase_cod) / n())^2),          # Gini-Simpson
  n_vehiculos_pesados = sum(grupo %in% c("carga_pesada", "bus")),
  hay_pesado = as.integer(any(grupo %in% c("carga_pesada", "bus"))),
  hay_moto_vehiculo = as.integer(any(grupo == "moto")),
  hay_transporte_publico = as.integer(any(servicio == 2, na.rm = TRUE)),
  hay_fuga = as.integer(any(enfuga == "S")), .groups = "drop")

# ======================================================================
# INTEGRACION a nivel de siniestro
# ======================================================================
int <- s %>%
  left_join(feat_act, by = "codigo_accidente") %>%
  left_join(feat_veh, by = "codigo_accidente") %>%
  left_join(estado_sin, by = "codigo_accidente")
aud$siniestros_sin_detalle <- c(total = sum(is.na(int$n_vehiculos) | is.na(int$n_involucrados)))
aud$sin_detalle_por_gravedad <- table(int$gravedad_original[is.na(int$n_vehiculos) | is.na(int$n_involucrados)])
int <- int %>% filter(!is.na(n_vehiculos), !is.na(n_involucrados))   # sin actores ni vehiculos: sin atributos que modelar

# Consistencia de la variable objetivo con el detalle de victimas
aud$consistencia_gravedad <- table(registrada = int$gravedad_original, segun_actores = int$gravedad_actores)
aud$gravedad_reclasificada <- sum(int$gravedad_original != int$gravedad_actores)
int <- int %>% mutate(gravedad = gravedad_actores)   # prevalece la evidencia a nivel de victima

# Duplicados semanticos: mismo instante, direccion, clase, localidad, gravedad y mismo numero de vehiculos/actores
llave <- c("fecha", "hora", "direccion", "clase_cod", "localidad_cod", "gravedad", "n_vehiculos", "n_involucrados")
aud$duplicados_semanticos <- sum(duplicated(int[llave]))
aud$duplicados_misma_fecha_hora_dir <- sum(duplicated(int[c("fecha", "hora", "direccion")]))
int <- int %>% distinct(across(all_of(llave)), .keep_all = TRUE)

# Tipos finales
int <- int %>% mutate(
  gravedad = factor(gravedad, levels = c(3, 2, 1), labels = c("Solo danos", "Con heridos", "Con muertos")),
  across(c(clase_siniestro, tipo_choque, diseno_lugar, localidad), as.character)) %>%
  select(codigo_accidente, fecha, anio, mes, hora, dia_semana, franja_horaria, fin_semana, es_festivo, dia_no_habil, nocturno,
         hora_sin, hora_cos, mes_sin, mes_cos, localidad, clase_siniestro, tipo_choque, diseno_lugar, via_avenida,
         n_vehiculos, n_clases_veh, indice_heterogeneidad, n_vehiculos_pesados, hay_pesado, hay_moto_vehiculo,
         hay_transporte_publico, hay_fuga, n_conductores, n_peatones, n_ciclistas, n_motociclistas, n_involucrados,
         n_vulnerables, ratio_vulnerables, hay_peaton, hay_ciclista, hay_motociclista, hay_vulnerable,
         hay_menor, hay_adulto_mayor, edad_media, edad_min, edad_max, prop_mujeres, direccion,
         gravedad_original, gravedad) %>%
  mutate(mezcla_vulnerable_pesado = as.integer(hay_vulnerable == 1 & hay_pesado == 1),
         multi_vehiculo = as.integer(n_vehiculos > 1))
aud$filas_finales <- nrow(int)
aud$nulos_integrado <- colSums(is.na(int)) / nrow(int)

saveRDS(int, "datos/clean/siniestros_integrado.rds")
saveRDS(aud, "resultados/auditoria_limpieza.rds")
message("Siniestros integrados: ", nrow(int), " x ", ncol(int))
