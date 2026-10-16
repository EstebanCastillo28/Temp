# ------------------------------------------------------------------
# 00_descarga_datos.R
# Descarga el consolidado oficial de siniestros viales de Bogota D.C.
# (Secretaria Distrital de Movilidad, SIGAT/IPAT) y exporta cada hoja
# a CSV en datos/raw/. Se ejecuta UNA vez; el resto del flujo usa los CSV.
# Ejecutar desde la raiz del proyecto: Rscript scripts/00_descarga_datos.R
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(readxl); library(readr)})

url <- paste0("https://datosabiertos.bogota.gov.co/dataset/0b070626-fe5a-42dc-ae99-92601da166d9/",
              "resource/9e3add8e-3f46-42ce-9c0f-419964f6f598/download/",
              "siniestros_viales_consolidados_bogota_dc.xlsx")
dir.create("datos/raw", recursive = TRUE, showWarnings = FALSE)
xlsx <- file.path(tempdir(), "consolidado.xlsx")
if (!file.exists("datos/raw/SINIESTROS.csv")) {
  download.file(url, xlsx, mode = "wb", quiet = TRUE, method = "libcurl")
  for (h in c("SINIESTROS", "ACTOR_VIAL", "VEHICULOS", "HIPOTESIS", "DICCIONARIO")) {
    # todo como texto: la tipificacion se hace de forma explicita en 01_integracion.R
    d <- read_excel(xlsx, sheet = h, col_types = "text")
    write_csv(d, file.path("datos/raw", paste0(h, ".csv")), na = "")
    message(h, ": ", nrow(d), " filas")
  }
}
