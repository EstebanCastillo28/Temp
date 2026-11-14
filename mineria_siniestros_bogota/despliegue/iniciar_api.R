# Inicia la API en el puerto 8000. Ejecutar desde la raiz del proyecto: Rscript despliegue/iniciar_api.R
plumber::pr("despliegue/api.R") |> plumber::pr_run(host = "127.0.0.1", port = 8000)
