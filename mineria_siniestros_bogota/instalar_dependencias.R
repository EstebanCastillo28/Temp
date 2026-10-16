# ------------------------------------------------------------------
# instalar_dependencias.R
# Instala los paquetes de R y TinyTeX (LaTeX) necesarios para compilar
# informe_final.Rmd. Ejecutar UNA vez desde RStudio:
#   source("instalar_dependencias.R")
# ------------------------------------------------------------------
paquetes <- c("dplyr", "tidyr", "readr", "stringr", "stringi", "lubridate",
              "ggplot2", "scales", "gridExtra", "knitr", "kableExtra",
              "rmarkdown", "readxl", "tinytex")
faltan <- setdiff(paquetes, rownames(installed.packages()))
if (length(faltan)) install.packages(faltan, repos = "https://cloud.r-project.org")

# LaTeX ligero para generar el PDF (solo si no hay xelatex disponible)
if (!nzchar(Sys.which("xelatex"))) tinytex::install_tinytex()

cat("\nListo. Compile con: rmarkdown::render('informe_final.Rmd')\n")
