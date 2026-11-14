# ------------------------------------------------------------------
# funciones_despliegue.R
# Capa comun del artefacto de despliegue (app Shiny, API Plumber, pruebas):
#   cargar_artefactos()   -> carga el modelo YA ENTRENADO y los parametros de Train (no se reentrena)
#   validar_entrada()     -> errores y advertencias de la entrada del usuario
#   construir_registros() -> convierte lo que el usuario sabe del siniestro en las variables del modelo
#   predecir_gravedad()   -> probabilidades, nivel de riesgo, perfil del grupo y mensaje en lenguaje claro
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(dplyr); library(stringr); library(lubridate)})

encontrar_raiz <- function() {
  for (d in c(".", "..", "../..", "../../..")) if (file.exists(file.path(d, "modelos", "modelo_final.rds"))) return(normalizePath(d))
  stop("No se encontro la carpeta 'modelos/'. Ejecute desde la raiz del proyecto o desde 'despliegue/'.")
}

cargar_artefactos <- function(raiz = encontrar_raiz()) {
  source(file.path(raiz, "scripts", "funciones.R"), encoding = "UTF-8"); source(file.path(raiz, "scripts", "funciones_modelado.R"), encoding = "UTF-8")
  final <- readRDS(file.path(raiz, "modelos", "modelo_final.rds"))
  A <- list(raiz = raiz, P = readRDS(file.path(raiz, "modelos", "parametros_transformacion.rds")), final = final,
            modelo = cargar_modelo(final$campeon, dir = file.path(raiz, "modelos")), clus = readRDS(file.path(raiz, "modelos", "clustering.rds")),
            ref = readRDS(file.path(raiz, "modelos", "referencia_monitoreo.rds")))
  source(file.path(raiz, "despliegue", "monitoreo.R"), encoding = "UTF-8")
  A
}

# ---- Opciones validas (coinciden con el diccionario oficial) --------------------------------------
LOCALIDADES <- c("Usaquén", "Chapinero", "Santa Fe", "San Cristóbal", "Usme", "Tunjuelito", "Bosa", "Kennedy", "Fontibón", "Engativá", "Suba", "Barrios Unidos",
                 "Teusaquillo", "Los Mártires", "Antonio Nariño", "Puente Aranda", "La Candelaria", "Rafael Uribe Uribe", "Ciudad Bolívar", "Sumapaz")
CLASES_SIN <- c("Choque", "Atropello", "Volcamiento", "Caida de ocupante", "Incendio", "Otro", "Autolesion")
TIPOS_CHOQUE <- c("Vehiculo", "Objeto Fijo", "Semoviente", "Tren", "No aplica (no es choque)", "Sin informacion")
DISENOS <- c("Tramo de Via", "Interseccion", "Glorieta", "Lote o predio", "Paso elevado", "Paso inferior", "Puente", "Cicloruta", "Paso a nivel", "Via peatonal", "Via troncal", "Tunel", "Ponton")
COLS_ENTRADA <- c("fecha", "hora", "localidad", "clase_siniestro", "tipo_choque", "diseno_lugar", "via_avenida", "n_autos", "n_motos", "n_bicicletas", "n_buses",
                  "n_carga_pesada", "n_otros_vehiculos", "n_peatones", "hay_transporte_publico", "hay_fuga", "edad_min", "edad_max", "edad_media", "prop_mujeres")

.num <- function(x) suppressWarnings(as.numeric(x))

# ---- Validacion ---------------------------------------------------------------------------------------
validar_entrada <- function(df, A = NULL) {
  out <- vector("list", nrow(df))
  for (i in seq_len(nrow(df))) {
    r <- df[i, , drop = FALSE]; e <- character(); w <- character()
    f <- suppressWarnings(as.Date(as.character(r$fecha)))
    if (is.na(f)) e <- c(e, "La fecha no es válida (use AAAA-MM-DD).") else if (f < as.Date("2000-01-01") || f > as.Date("2100-12-31")) e <- c(e, "La fecha está fuera de un rango razonable.")
    h <- .num(r$hora); if (is.na(h) || h < 0 || h >= 24) e <- c(e, "La hora debe estar entre 0 y 23,99.")
    if (!(r$localidad %in% LOCALIDADES)) e <- c(e, paste0("Localidad desconocida: '", r$localidad, "'."))
    if (!(r$clase_siniestro %in% CLASES_SIN)) e <- c(e, paste0("Clase de siniestro no válida: '", r$clase_siniestro, "'."))
    if (!(r$tipo_choque %in% TIPOS_CHOQUE)) e <- c(e, paste0("Tipo de choque no válido: '", r$tipo_choque, "'."))
    if (!(r$diseno_lugar %in% DISENOS)) e <- c(e, paste0("Diseño del lugar no válido: '", r$diseno_lugar, "'."))
    cnt <- sapply(c("n_autos", "n_motos", "n_bicicletas", "n_buses", "n_carga_pesada", "n_otros_vehiculos", "n_peatones"), function(v) .num(r[[v]]))
    if (anyNA(cnt) || any(cnt < 0) || any(cnt != round(cnt), na.rm = TRUE)) e <- c(e, "Las cantidades de vehículos y peatones deben ser números enteros no negativos.")
    else {
      nv <- sum(cnt[1:6])
      if (nv < 1) e <- c(e, "Debe haber al menos un vehículo involucrado.")
      if (nv > 30) e <- c(e, "Más de 30 vehículos no es un caso que el modelo pueda evaluar de forma confiable.")
      else if (nv > A$P$tope_sup[["n_vehiculos"]]) w <- c(w, paste0("Hay ", nv, " vehículos; el modelo trata los casos de más de ", A$P$tope_sup[["n_vehiculos"]], " como si fueran ", A$P$tope_sup[["n_vehiculos"]], " (valor extremo, poco frecuente en los datos)."))
      if (nv >= 1 && cnt["n_peatones"] > 0 && r$clase_siniestro != "Atropello") w <- c(w, "Hay peatones pero la clase no es 'Atropello': verifique la coherencia.")
      if (r$clase_siniestro == "Atropello" && cnt["n_peatones"] == 0) w <- c(w, "La clase es 'Atropello' pero no hay peatones registrados: verifique la coherencia.")
      if (r$clase_siniestro != "Choque" && !(r$tipo_choque %in% c("No aplica (no es choque)", "Sin informacion"))) w <- c(w, "Si no es un choque, el tipo de choque debería ser 'No aplica (no es choque)'.")
    }
    for (v in c("edad_min", "edad_max", "edad_media")) {
      x <- .num(r[[v]]); if (!is.na(r[[v]]) && nzchar(as.character(r[[v]])) && (is.na(x) || x < 0 || x > 109)) e <- c(e, paste0("La edad (", v, ") debe estar entre 0 y 109 años."))
    }
    emin <- .num(r$edad_min); emax <- .num(r$edad_max)
    if (!is.na(emin) && !is.na(emax) && emin > emax) e <- c(e, "La edad mínima no puede ser mayor que la máxima.")
    if (is.na(emin) && is.na(emax) && is.na(.num(r$edad_media))) w <- c(w, "No se informaron edades: el modelo usará la edad típica de los datos de entrenamiento.")
    pm <- .num(r$prop_mujeres); if (!is.na(r$prop_mujeres) && nzchar(as.character(r$prop_mujeres)) && (is.na(pm) || pm < 0 || pm > 1)) e <- c(e, "La proporción de mujeres debe estar entre 0 y 1.")
    out[[i]] <- list(errores = e, advertencias = w)
  }
  out
}

# ---- Construccion de las variables del modelo a partir de lo que el usuario conoce ----------------------------
construir_registros <- function(df, A) {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (v in setdiff(COLS_ENTRADA, names(df))) df[[v]] <- NA
  f <- as.Date(as.character(df$fecha)); h <- .num(df$hora)
  n <- function(v) { x <- .num(df[[v]]); ifelse(is.na(x), 0, x) }
  g_aut <- n("n_autos"); g_mot <- n("n_motos"); g_bic <- n("n_bicicletas"); g_bus <- n("n_buses"); g_car <- n("n_carga_pesada"); g_otr <- n("n_otros_vehiculos"); peat <- n("n_peatones")
  G <- cbind(g_aut, g_mot, g_bic, g_bus, g_car, g_otr); nveh <- rowSums(G)
  festivos <- unique(do.call(c, lapply(unique(year(f[!is.na(f)])), festivos_colombia)))
  emin <- .num(df$edad_min); emax <- .num(df$edad_max); emed <- .num(df$edad_media)
  emed <- ifelse(is.na(emed) & !is.na(emin) & !is.na(emax), (emin + emax) / 2, ifelse(is.na(emed), ifelse(!is.na(emin), emin, emax), emed))
  emin2 <- ifelse(is.na(emin), emed, emin); emax2 <- ifelse(is.na(emax), emed, emax)
  nconductores <- g_aut + g_bus + g_car + g_otr; nvuln <- peat + g_bic + g_mot; ninv <- nconductores + nvuln
  fr <- case_when(h < 6 ~ "Madrugada (00-05h)", h < 9 ~ "Pico AM (06-08h)", h < 16 ~ "Valle diurno (09-15h)", h < 20 ~ "Pico PM (16-19h)", TRUE ~ "Noche (20-23h)")
  dsem <- c("Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo")[wday(f, week_start = 1)]
  gs <- apply(G, 1, function(r) { s <- sum(r); if (s == 0) 0 else 1 - sum((r / s)^2) })
  pes <- g_bus + g_car
  tibble(
    codigo_accidente = paste0("nuevo-", seq_len(nrow(df))), fecha = f, anio = year(f), mes = month(f), hora = h, dia_semana = dsem, franja_horaria = fr,
    fin_semana = as.integer(wday(f, week_start = 1) >= 6), es_festivo = as.integer(f %in% festivos),
    dia_no_habil = as.integer(wday(f, week_start = 1) >= 6 | f %in% festivos), nocturno = as.integer(h >= 20 | h < 6),
    hora_sin = sin(2 * pi * h / 24), hora_cos = cos(2 * pi * h / 24), mes_sin = sin(2 * pi * month(f) / 12), mes_cos = cos(2 * pi * month(f) / 12),
    localidad = df$localidad, clase_siniestro = df$clase_siniestro, tipo_choque = df$tipo_choque, diseno_lugar = df$diseno_lugar, via_avenida = as.integer(.num(df$via_avenida) %in% 1),
    n_vehiculos = nveh, n_clases_veh = rowSums(G > 0), indice_heterogeneidad = gs, n_vehiculos_pesados = pes, hay_pesado = as.integer(pes > 0),
    hay_moto_vehiculo = as.integer(g_mot > 0), hay_transporte_publico = as.integer(.num(df$hay_transporte_publico) %in% 1 | g_bus > 0), hay_fuga = as.integer(.num(df$hay_fuga) %in% 1),
    n_conductores = nconductores, n_peatones = peat, n_ciclistas = g_bic, n_motociclistas = g_mot, n_involucrados = ninv, n_vulnerables = nvuln,
    ratio_vulnerables = ifelse(ninv > 0, nvuln / ninv, 0), hay_peaton = as.integer(peat > 0), hay_ciclista = as.integer(g_bic > 0), hay_motociclista = as.integer(g_mot > 0),
    hay_vulnerable = as.integer(nvuln > 0), hay_menor = as.integer(!is.na(emin2) & emin2 < 18), hay_adulto_mayor = as.integer(!is.na(emax2) & emax2 >= 65),
    edad_media = emed, edad_min = emin2, edad_max = emax2, prop_mujeres = .num(df$prop_mujeres),
    gravedad = factor(NA_character_, levels = c("Solo danos", "Con heridos", "Con muertos"))) %>%
    mutate(mezcla_vulnerable_pesado = as.integer(hay_vulnerable == 1 & hay_pesado == 1), multi_vehiculo = as.integer(n_vehiculos > 1))
}

asignar_cluster <- function(clus, X) {
  Z <- sweep(as.matrix(X[clus$features]), 2, clus$pca_center, "-") %*% clus$rot
  d <- vapply(seq_len(clus$K), function(j) rowSums(sweep(Z, 2, clus$centers[j, ], "-")^2), numeric(nrow(Z)))
  if (is.null(dim(d))) d <- matrix(d, nrow = nrow(Z))       # un solo caso
  max.col(-d)
}

RECOMENDACIONES <- c(
  "Peatón o moto, un solo vehículo" = "Priorizar cruces peatonales seguros, reducción de velocidad y señalización en el corredor; control a motocicletas y campañas dirigidas a peatones y motociclistas.",
  "Motociclista en choque con otro vehículo" = "Considerar operativos de control a motocicletas (velocidad, casco, documentos), gestión de intersecciones y campañas dirigidas a motociclistas.",
  "Ciclista involucrado" = "Revisar la infraestructura ciclista del tramo (ciclorrutas, intersecciones) y campañas de convivencia vial.",
  "Choque con vehículo pesado o bus" = "Reforzar el control de velocidad y de carga de vehículos pesados y buses en el corredor.",
  "Un solo vehículo pesado" = "Revisar el estado de la vía, la velocidad y las condiciones de operación de vehículos pesados.",
  "Un solo vehículo" = "Revisar señalización, iluminación y estado de la vía en el punto.",
  "Choque entre vehículos livianos" = "Revisar la gestión de intersecciones y el control de velocidad; es el grupo de menor letalidad."
)
base_nombre <- function(x) sub(" · .*$", "", x)

predecir_desde_integrado <- function(reg, A) {
  ml <- aplicar_transformacion(reg, A$P)$ml
  p <- predecir_probs(A$modelo, ml)
  list(p = p, ml = ml)
}

predecir_gravedad <- function(df, A) {
  df <- as.data.frame(df, stringsAsFactors = FALSE)
  for (v in setdiff(COLS_ENTRADA, names(df))) df[[v]] <- NA      # columnas opcionales ausentes (p. ej. en JSON)
  val <- validar_entrada(df, A); ok <- vapply(val, function(v) length(v$errores) == 0, logical(1))
  res <- tibble(fila = seq_len(nrow(df)), valido = ok, errores = vapply(val, function(v) paste(v$errores, collapse = " | "), ""),
                advertencias = vapply(val, function(v) paste(v$advertencias, collapse = " | "), ""),
                prob_solo_danos = NA_real_, prob_heridos = NA_real_, prob_muertos = NA_real_, clase_predicha = NA_character_, nivel_riesgo = NA_character_, perfil = NA_character_,
                recomendacion = NA_character_, mensaje = NA_character_)
  if (any(ok)) {
    reg <- construir_registros(df[ok, , drop = FALSE], A); pr <- predecir_desde_integrado(reg, A)
    p <- pr$p; clase <- as.character(predecir_clase(p, A$final$multiplicadores)); pf <- p[, 3]
    nivel <- as.character(cut(pf, c(-Inf, A$final$umbral_medio, A$final$umbral_alto, Inf), labels = c("Bajo", "Medio", "Alto")))
    perfil <- A$clus$nombres[asignar_cluster(A$clus, pr$ml)]
    etq <- c("Solo danos" = "Solo daños materiales", "Con heridos" = "Con heridos", "Con muertos" = "Con víctimas fatales")
    res$prob_solo_danos[ok] <- p[, 1]; res$prob_heridos[ok] <- p[, 2]; res$prob_muertos[ok] <- pf
    res$clase_predicha[ok] <- unname(etq[clase]); res$nivel_riesgo[ok] <- nivel; res$perfil[ok] <- perfil
    res$recomendacion[ok] <- unname(RECOMENDACIONES[base_nombre(perfil)])
    res$mensaje[ok] <- sprintf("Según los datos de 2015–2020, de cada 100 siniestros con condiciones parecidas, unos %s terminaron con heridos y %s con víctimas fatales. Nivel de riesgo de fatalidad: %s.",
                               formatC(100 * p[, 2], format = "f", digits = 0), ifelse(pf < 0.1, formatC(100 * pf, format = "f", digits = 1, decimal.mark = ","), formatC(100 * pf, format = "f", digits = 0)), toupper(nivel))
  }
  res
}
