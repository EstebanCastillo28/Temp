# ------------------------------------------------------------------
# instalar_dependencias.R
# Instala los paquetes de R y TinyTeX (LaTeX) necesarios para compilar informe_final.Rmd
# y para ejecutar el despliegue (app Shiny y API). Ejecutar UNA vez desde RStudio:
#   source("instalar_dependencias.R")
# ------------------------------------------------------------------
paquetes <- c(
  # preparacion de datos e informe
  "dplyr", "tidyr", "readr", "stringr", "stringi", "lubridate", "ggplot2", "scales", "gridExtra", "knitr", "kableExtra", "rmarkdown", "readxl", "tinytex",
  # modelado e interpretacion
  "glmnet", "ranger", "xgboost", "cluster", "MASS",
  # despliegue
  "shiny", "bslib", "plumber", "jsonlite", "httr")
faltan <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltan)) install.packages(faltan, repos = "https://cloud.r-project.org")

# LaTeX ligero para generar el PDF (solo si no hay xelatex disponible)
if (!nzchar(Sys.which("xelatex"))) tinytex::install_tinytex()

cat("\nListo. Compile con: rmarkdown::render('informe_final.Rmd')\n")
