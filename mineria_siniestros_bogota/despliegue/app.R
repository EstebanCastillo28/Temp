# ------------------------------------------------------------------
# app.R — Aplicación Shiny: estimación de la gravedad de un siniestro vial en Bogotá D.C.
# Carga el modelo YA ENTRENADO (no se reentrena). Ejecutar desde RStudio con "Run App"
# o con:  shiny::runApp("despliegue")
# ------------------------------------------------------------------
suppressPackageStartupMessages({library(shiny); library(bslib); library(ggplot2); library(dplyr)})
source(file.path(if (file.exists("funciones_despliegue.R")) "." else "despliegue", "funciones_despliegue.R"), encoding = "UTF-8")
A <- cargar_artefactos()
MT <- A$final$metricas_test
pct <- function(x, d = 1) paste0(formatC(100 * x, format = "f", digits = d, decimal.mark = ","), " %")
COL <- c("Solo daños" = "#8D99AE", "Con heridos" = "#FCA311", "Con muertos" = "#C0392B")
COL_NIVEL <- c(Bajo = "#2A9D8F", Medio = "#FCA311", Alto = "#C0392B")

EJEMPLOS <- list(
  "— elegir un ejemplo —" = NULL,
  "Atropello nocturno (Kennedy)" = list(fecha = "2019-11-15", hora = 22, localidad = "Kennedy", clase_siniestro = "Atropello", tipo_choque = "No aplica (no es choque)", diseno_lugar = "Tramo de Via", via_avenida = TRUE, n_autos = 1, n_motos = 0, n_bicicletas = 0, n_buses = 0, n_carga_pesada = 0, n_otros = 0, n_peatones = 1, edad_min = 58, edad_max = 58),
  "Choque entre dos autos (día hábil)" = list(fecha = "2019-03-12", hora = 10, localidad = "Usaquén", clase_siniestro = "Choque", tipo_choque = "Vehiculo", diseno_lugar = "Interseccion", via_avenida = FALSE, n_autos = 2, n_motos = 0, n_bicicletas = 0, n_buses = 0, n_carga_pesada = 0, n_otros = 0, n_peatones = 0, edad_min = 30, edad_max = 45),
  "Moto y bus (sábado de madrugada)" = list(fecha = "2018-09-08", hora = 3, localidad = "Engativá", clase_siniestro = "Choque", tipo_choque = "Vehiculo", diseno_lugar = "Tramo de Via", via_avenida = TRUE, n_autos = 0, n_motos = 1, n_bicicletas = 0, n_buses = 1, n_carga_pesada = 0, n_otros = 0, n_peatones = 0, edad_min = 24, edad_max = 41),
  "Caso límite: 25 vehículos" = list(fecha = "2019-06-20", hora = 14, localidad = "Suba", clase_siniestro = "Choque", tipo_choque = "Vehiculo", diseno_lugar = "Tramo de Via", via_avenida = TRUE, n_autos = 20, n_motos = 3, n_bicicletas = 0, n_buses = 2, n_carga_pesada = 0, n_otros = 0, n_peatones = 0, edad_min = 22, edad_max = 60),
  "Entrada inválida (hora 30, edad -5)" = list(fecha = "2019-06-20", hora = 30, localidad = "Suba", clase_siniestro = "Choque", tipo_choque = "Vehiculo", diseno_lugar = "Tramo de Via", via_avenida = FALSE, n_autos = 2, n_motos = 0, n_bicicletas = 0, n_buses = 0, n_carga_pesada = 0, n_otros = 0, n_peatones = 0, edad_min = -5, edad_max = 40))

ui <- page_navbar(
  title = "Gravedad de siniestros viales · Bogotá D.C.", theme = bs_theme(version = 5, primary = "#14213D", secondary = "#FCA311"),
  nav_panel("Estimar un siniestro",
    layout_sidebar(sidebar = sidebar(width = 380,
      selectInput("ejemplo", "Cargar un ejemplo", names(EJEMPLOS)),
      accordion(open = c("cuando", "que", "quien"),
        accordion_panel("¿Cuándo y dónde?", value = "cuando",
          dateInput("fecha", "Fecha del siniestro", value = as.Date("2019-06-15"), min = "2000-01-01", max = "2100-12-31", language = "es"),
          sliderInput("hora", "Hora (0 a 23)", min = 0, max = 23.5, value = 15, step = 0.5),
          selectInput("localidad", "Localidad", LOCALIDADES, selected = "Kennedy"),
          selectInput("diseno_lugar", "Lugar del hecho", DISENOS), checkboxInput("via_avenida", "Ocurrió sobre una avenida", FALSE)),
        accordion_panel("¿Qué pasó?", value = "que",
          selectInput("clase_siniestro", "Clase de siniestro", CLASES_SIN), selectInput("tipo_choque", "Tipo de choque", TIPOS_CHOQUE)),
        accordion_panel("¿Quiénes participan?", value = "quien",
          p(class = "text-muted small", "Cantidad de vehículos por tipo y de peatones."),
          layout_columns(col_widths = c(6, 6),
            numericInput("n_autos", "Autos, camionetas", 1, min = 0, step = 1), numericInput("n_motos", "Motocicletas", 0, min = 0, step = 1),
            numericInput("n_bicicletas", "Bicicletas", 0, min = 0, step = 1), numericInput("n_buses", "Buses, busetas", 0, min = 0, step = 1),
            numericInput("n_carga_pesada", "Camiones, tractocamiones", 0, min = 0, step = 1), numericInput("n_otros", "Otros vehículos", 0, min = 0, step = 1),
            numericInput("n_peatones", "Peatones", 0, min = 0, step = 1)),
          checkboxInput("hay_fuga", "Algún vehículo huyó del lugar", FALSE),
          checkboxInput("sin_edad", "No se conocen las edades", FALSE),
          conditionalPanel("!input.sin_edad", layout_columns(col_widths = c(6, 6),
            numericInput("edad_min", "Edad del más joven", 30, min = 0, max = 109), numericInput("edad_max", "Edad del mayor", 40, min = 0, max = 109))))),
      actionButton("go", "Estimar gravedad", class = "btn-primary w-100 mt-2")),
      uiOutput("resultado")),
  ),
  nav_panel("Cómo interpretarlo",
    card(card_header("En palabras sencillas"), tags$ul(
      tags$li("Usted describe lo que se sabe de un siniestro: cuándo, dónde, qué pasó y quiénes participan."),
      tags$li("El modelo compara esa descripción con ", format(A$final$n_train, big.mark = ".", decimal.mark = ","), " siniestros reales de Bogotá (2015–2020) y estima la probabilidad de cada desenlace: solo daños, heridos o víctimas fatales."),
      tags$li("Una probabilidad de 6 % de víctimas fatales significa que, de 100 siniestros parecidos, unos 6 terminaron con muertos."),
      tags$li("El 'nivel de riesgo' (Bajo, Medio, Alto) ordena los casos: 'Alto' agrupa al 5 % de siniestros con mayor probabilidad estimada."),
      tags$li("Es una herramienta de apoyo para priorizar; no reemplaza el criterio de la autoridad ni sirve para decidir sobre personas concretas.")),
      card_footer("Limitaciones: datos 2015–2020, sin información de velocidad, clima ni flujo vehicular.")),
    card(card_header("Qué tan bien funciona (conjunto de prueba, datos que el modelo no vio)"),
      tableOutput("metricas"),
      p(class = "small text-muted", "Recall: de cada 100 siniestros fatales reales, cuántos detecta. Precisión: de cada 100 alertas de 'fatal', cuántas lo eran. Con una clase tan rara (1,5 % de los casos) la precisión es baja por naturaleza: el modelo sirve para ordenar y priorizar, no para afirmar con certeza."))),
  nav_panel("Lote de casos (CSV)",
    layout_sidebar(sidebar = sidebar(width = 340, fileInput("csv", "Suba un CSV con casos", accept = ".csv"),
      downloadButton("plantilla", "Descargar plantilla", class = "btn-outline-primary w-100 mb-2"), uiOutput("btn_desc")),
      uiOutput("lote_info"), tableOutput("lote_tabla"))),
  nav_panel("Monitoreo",
    layout_sidebar(sidebar = sidebar(width = 340, p("Compare un lote nuevo con los datos de entrenamiento: si las variables cambian mucho (PSI alto), el modelo puede perder desempeño."),
      fileInput("csv_mon", "CSV con el esquema integrado (RDS/CSV)", accept = c(".csv"))), uiOutput("mon_info"), tableOutput("mon_tabla")))
)

server <- function(input, output, session) {
  observeEvent(input$ejemplo, {
    e <- EJEMPLOS[[input$ejemplo]]; req(e)
    updateDateInput(session, "fecha", value = as.Date(e$fecha)); updateSliderInput(session, "hora", value = min(e$hora, 23.5)); updateSelectInput(session, "localidad", selected = e$localidad)
    updateSelectInput(session, "clase_siniestro", selected = e$clase_siniestro); updateSelectInput(session, "tipo_choque", selected = e$tipo_choque); updateSelectInput(session, "diseno_lugar", selected = e$diseno_lugar)
    updateCheckboxInput(session, "via_avenida", value = e$via_avenida)
    for (v in c("n_autos", "n_motos", "n_bicicletas", "n_buses", "n_carga_pesada", "n_otros", "n_peatones", "edad_min", "edad_max")) updateNumericInput(session, v, value = e[[v]])
  })
  # La hora 30 del ejemplo inválido no cabe en el control deslizante: se envía tal cual al validador
  caso <- eventReactive(input$go, {
    e <- EJEMPLOS[[input$ejemplo]]; hora <- input$hora
    if (!is.null(e) && identical(input$ejemplo, "Entrada inválida (hora 30, edad -5)")) hora <- e$hora
    data.frame(fecha = as.character(input$fecha), hora = hora, localidad = input$localidad, clase_siniestro = input$clase_siniestro, tipo_choque = input$tipo_choque,
               diseno_lugar = input$diseno_lugar, via_avenida = as.integer(input$via_avenida), n_autos = input$n_autos, n_motos = input$n_motos, n_bicicletas = input$n_bicicletas,
               n_buses = input$n_buses, n_carga_pesada = input$n_carga_pesada, n_otros_vehiculos = input$n_otros, n_peatones = input$n_peatones, hay_transporte_publico = 0,
               hay_fuga = as.integer(input$hay_fuga), edad_min = if (input$sin_edad) NA else input$edad_min, edad_max = if (input$sin_edad) NA else input$edad_max,
               edad_media = NA, prop_mujeres = NA)
  })
  pred <- reactive(predecir_gravedad(caso(), A))
  output$resultado <- renderUI({
    if (input$go == 0) return(card(card_body(p("Complete los datos del siniestro y pulse «Estimar gravedad». También puede cargar un ejemplo.", class = "lead text-muted"))))
    r <- pred()[1, ]
    if (!r$valido) return(card(class = "border-danger", card_header("No se pudo estimar: revise la entrada", class = "bg-danger text-white"),
                               card_body(tags$ul(lapply(strsplit(r$errores, " \\| ")[[1]], tags$li)))))
    tagList(
      layout_columns(col_widths = c(4, 4, 4),
        value_box("Probabilidad de víctimas fatales", pct(r$prob_muertos, ifelse(r$prob_muertos < 0.1, 1, 0)), theme = if (r$nivel_riesgo == "Alto") "danger" else if (r$nivel_riesgo == "Medio") "warning" else "success"),
        value_box("Nivel de riesgo", r$nivel_riesgo, theme = if (r$nivel_riesgo == "Alto") "danger" else if (r$nivel_riesgo == "Medio") "warning" else "success"),
        value_box("Desenlace más probable", r$clase_predicha, theme = "primary")),
      if (nzchar(r$advertencias)) div(class = "alert alert-warning", tags$b("Atención: "), r$advertencias),
      card(card_header("Probabilidad de cada desenlace"), plotOutput("grafico", height = 220)),
      card(card_header("¿Qué significa?"), p(r$mensaje), p(tags$b("Perfil del siniestro: "), r$perfil), p(tags$b("Recomendación orientativa: "), r$recomendacion)))
  })
  output$grafico <- renderPlot({
    r <- pred()[1, ]; req(r$valido)
    d <- data.frame(clase = factor(c("Solo daños", "Con heridos", "Con muertos"), c("Solo daños", "Con heridos", "Con muertos")), p = c(r$prob_solo_danos, r$prob_heridos, r$prob_muertos))
    ggplot(d, aes(clase, p, fill = clase)) + geom_col(width = .6, show.legend = FALSE) + geom_text(aes(label = ifelse(p < 0.1, pct(p, 1), pct(p, 0))), vjust = -.4, size = 5) +
      scale_fill_manual(values = COL) + scale_y_continuous(limits = c(0, 1.05), labels = scales::percent) + labs(x = NULL, y = NULL) + theme_minimal(base_size = 15)
  })
  output$metricas <- renderTable(data.frame(Medida = c("Recall de la clase fatal", "Precisión de la clase fatal", "F1 macro (3 clases)", "AUC clase fatal", "Exactitud global (referencia)"),
    Valor = c(pct(MT$recall_fatal), pct(MT$precision_fatal), formatC(MT$f1_macro, format = "f", digits = 2, decimal.mark = ","), formatC(MT$auc[3], format = "f", digits = 3, decimal.mark = ","), pct(MT$accuracy))))
  # Lote
  lote <- reactive({ req(input$csv); d <- read.csv(input$csv$datapath, stringsAsFactors = FALSE, encoding = "UTF-8", check.names = FALSE); cbind(d[intersect(names(d), COLS_ENTRADA)], predecir_gravedad(d, A)[, -1]) })
  output$lote_info <- renderUI({ if (is.null(input$csv)) return(p("Suba un CSV con las columnas de la plantilla.", class = "text-muted")); l <- lote(); p(sprintf("%d casos: %d válidos, %d con errores.", nrow(l), sum(l$valido), sum(!l$valido))) })
  output$lote_tabla <- renderTable({ l <- lote(); l[, intersect(c("fecha", "localidad", "clase_siniestro", "valido", "prob_muertos", "nivel_riesgo", "clase_predicha", "perfil", "errores"), names(l))] %>% mutate(prob_muertos = round(prob_muertos, 4)) })
  output$btn_desc <- renderUI({ req(input$csv); downloadButton("descarga", "Descargar resultados", class = "btn-primary w-100") })
  output$descarga <- downloadHandler(filename = function() "predicciones_gravedad.csv", content = function(file) write.csv(lote(), file, row.names = FALSE, fileEncoding = "UTF-8"))
  output$plantilla <- downloadHandler(filename = function() "plantilla_casos.csv", content = function(file) file.copy(file.path(A$raiz, "despliegue", "ejemplos", "plantilla_casos.csv"), file))
  # Monitoreo
  mon <- reactive({ req(input$csv_mon); d <- read.csv(input$csv_mon$datapath, stringsAsFactors = FALSE, encoding = "UTF-8"); monitorear_lote(d, A$ref) })
  output$mon_info <- renderUI({ if (is.null(input$csv_mon)) return(p("Suba un lote para calcular el PSI por variable.", class = "text-muted")); h4(mon()$semaforo) })
  output$mon_tabla <- renderTable(mon()$psi %>% mutate(psi = round(psi, 4)))
}
shinyApp(ui, server)
