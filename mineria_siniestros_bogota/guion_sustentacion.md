# Guion de sustentación — 13 min de exposición + 2 min de preguntas

**Presenta:** Juan Esteban Castillo Baquero · ID 852500
**Material:** `presentacion/sustentacion.pptx` (12 diapositivas), `informe_final.pdf`, proyecto abierto en RStudio.
**Ritmo:** ≈ 130 palabras por minuto. Los tiempos entre corchetes suman 13:00.
*Lo que está en cursiva son indicaciones para ti, no se lee en voz alta. No leas el código: muéstralo y explica la decisión.*

---

## Diapositiva 1 — Apertura de impacto [0:00 – 1:00]

> De cada mil siniestros viales que ocurren en Bogotá, quince terminan con víctimas fatales. Y si en el siniestro hay un peatón, esa cifra no es quince: es sesenta y ocho. Sin ningún actor vulnerable, es poco más de uno.
>
> Ese contraste es el punto de partida de mi proyecto. Trabajé con 195.946 siniestros registrados entre 2015 y 2020 por la Secretaría de Movilidad. El evento más grave es, a la vez, el más raro: solo el 1,5 % de los casos. Eso significa que cualquier error al preparar los datos se paga caro, porque el modelo tiene muy pocos ejemplos de lo que más importa.
>
> Soy Juan Esteban Castillo Baquero y hoy les muestro cómo preparé estos datos, hasta la transformación, y por qué tomé cada decisión.

*Señala las tres cifras. No leas el subtítulo.*

## Diapositiva 2 — Problema, relevancia e hipótesis [1:00 – 2:00]

> El Plan Distrital de Seguridad Vial 2023–2032 busca reducir a la mitad las víctimas fatales. Las medidas disponibles, como control de velocidad, rediseño de intersecciones o campañas, son costosas, así que hay que focalizarlas. Hoy el análisis es descriptivo: dice dónde y cuántos, pero ningún modelo anticipa qué tan grave será un siniestro.
>
> Mi pregunta de investigación es: ¿qué combinación de condiciones se asocia con los desenlaces más graves? Planteo tres hipótesis. La primera: peatones y motociclistas se asocian con mayor gravedad. La segunda: la noche y los fines de semana aumentan la probabilidad de un desenlace fatal. La tercera: existen perfiles de riesgo diferenciables por localidad, franja horaria y tipo de actor.
>
> El gráfico ya da una pista, pero con una salvedad que voy a retomar: parte de la fuerza del peatón es mecánica, porque un atropello casi siempre lesiona.

## Diapositiva 3 — Objetivos y ruta [2:00 – 2:45]

> El objetivo general es construir y evaluar un modelo que clasifique la gravedad en tres clases: solo daños, con heridos y con muertos, e identificar perfiles de riesgo para focalizar intervenciones.
>
> Tengo cinco objetivos específicos, cada uno ligado a una fase. Los tres primeros, integrar las tres tablas, caracterizar la siniestralidad y construir variables derivadas, corresponden a esta entrega: selección, limpieza y transformación. Entrenar y comparar al menos tres clasificadores y el agrupamiento vienen en la siguiente. Hoy cubro hasta la transformación.

## Diapositiva 4 — Datos y variables clave [2:45 – 3:40]

> La fuente es el consolidado oficial de siniestros viales de la Secretaría Distrital de Movilidad: 196.152 siniestros, 422.416 personas involucradas y 371.605 vehículos, más el diccionario oficial de datos.
>
> En la tabla están las variables clave con su tipo. La variable objetivo, GRAVEDAD, es categórica ordinal de tres niveles. De fecha y hora derivo franja, día y festivo. Tengo localidad, clase de siniestro, la condición del actor, su edad y sexo, y del vehículo su clase, servicio y si huyó.
>
> El reto de integración es que las tres tablas tienen granularidades distintas: siniestro, persona y vehículo. Las llevé a una sola fila por siniestro. Tras la limpieza quedan 195.946 siniestros y 50 columnas.

## Diapositiva 5 — Selección: qué se descarta y por qué [3:40 – 5:00]

> Cada variable que descarté tiene una razón. `HIPOTESIS`, la causa probable, se asigna después de investigar el siniestro: es información posterior al hecho. `OBJETO_FIJO` tiene 96,6 % de vacíos, pero estructurales, porque solo se diligencia en choques contra objeto fijo, y ya está cubierta por el tipo de choque. `MODALIDAD` tiene 61 % de vacíos estructurales, solo aplica a transporte público, y esa información ya está en `SERVICIO`. `DIRECCION` es texto libre de cardinalidad altísima; solo conservo un indicador de si es avenida. Y `ESTADO` define la gravedad, así que jamás puede ser predictor.
>
> Lo más importante es lo de los pasajeros. Al auditar los datos vi que de 27.365 pasajeros registrados, solo 2 están ilesos. Es decir, la base solo registra pasajeros cuando resultaron lesionados. Si los usara, el modelo leería la respuesta. Por eso excluyo a los pasajeros de todas las variables, y esta línea de código lo hace. Dejo al peatón porque la hipótesis 1 lo exige, con la salvedad de que su relación con la gravedad es en parte mecánica.

*Muestra la línea `filter(!str_starts(condicion, "PASAJERO"))` y explica el porqué, no el cómo.*

## Diapositiva 6 — Limpieza 1: valores faltantes [5:00 – 6:15]

> Primero diagnostiqué los vacíos por variable. La mayoría no son datos perdidos sino estructurales: `CHOQUE` solo se diligencia cuando la clase es choque. Imputarlos habría inventado información, así que se recodifican como «No aplica» o se descartan.
>
> El único faltante real es la edad: 1,9 % por actor y 0,35 % por siniestro. Una prueba chi-cuadrado muestra que la ausencia depende de la condición del actor, es decir, no es completamente al azar.
>
> Y aquí está el hallazgo: esa ausencia es informativa. Los siniestros sin edad registrada tienen 6,3 % de fatales, contra 1,5 % del resto, y en el 64 % de ellos hay un vehículo que huyó, o sea, conductores no identificados. Por eso no los elimino: eliminarlos sacaría del entrenamiento justo los casos más graves. Imputo con la mediana, calculada solo en Train, porque es robusta al sesgo de la edad, y conservo un indicador `edad_imputada` para no borrar la señal.

*Muestra el fragmento de la mediana: el parámetro se aprende solo en Train.*

## Diapositiva 7 — Limpieza 2: inconsistencias y duplicados [6:15 – 7:30]

> Segundo, errores e inconsistencias. La edad 118 aparece 282 veces, mientras que las edades vecinas casi no aparecen: es un valor por defecto, no personas de 118 años. En el gráfico se ve cómo desaparece el pico. Anulé también todo lo que es 110 años o más y a 297 conductores o motociclistas menores de 10 años, que es físicamente imposible.
>
> También audité la variable objetivo: 175 siniestros tenían una gravedad que contradecía el estado de sus víctimas. Prevalece la evidencia a nivel de víctima, y guardo la gravedad original para trazabilidad. Eliminé 148 siniestros sin actores ni vehículos, ninguno fatal, y 58 duplicados semánticos. Un código de CHOQUE que no existe en el diccionario lo recodifiqué como «Otro» en lugar de inventarle un significado. No encontré duplicados exactos ni registros huérfanos.
>
> Todas estas son reglas de dominio que no aprenden nada de los datos, por eso van antes de la partición y no generan fuga.

## Diapositiva 8 — Limpieza 3: valores atípicos [7:30 – 8:30]

> Para los atípicos comparé tres reglas explícitas. El IQR marca 22,5 % de los siniestros, pero no porque sean errores: como casi todos los siniestros tienen dos vehículos, el rango intercuartílico es cero y cualquier otro valor queda marcado. El Z-score y el percentil 99,5 marcan menos de 1 %.
>
> Por eso tomé una decisión diferenciada. En los conteos acoto, es decir, winsorizo, al percentil 99,5 calculado en Train: el tope es 4 vehículos y afecta 0,1 % de las filas. Se conserva el siniestro, pero se limita la influencia de colisiones masivas de hasta 23 vehículos. Los boxplots muestran el antes y el después. En las edades conservo los valores altos plausibles, hasta 107 años, porque son adultos mayores, exactamente el perfil vulnerable que me interesa.

## Diapositiva 9 — Transformación 1: derivadas y codificación [8:30 – 9:45]

> Pasamos a la transformación. Construí variables derivadas en tres grupos. Temporales: franja horaria de cinco tramos, festivos de Colombia calculados con la ley Emiliani y Semana Santa, y la hora como seno y coseno para que las 23 y las 0 horas queden cerca. De los involucrados: presencia de peatón, proporción de vulnerables y edades mínima y máxima. De los vehículos: un índice de heterogeneidad de Gini-Simpson, presencia de vehículo pesado y la interacción de vulnerable con pesado. Cada una responde a las hipótesis uno, dos y tres.
>
> Para las categóricas usé one-hot con k menos uno columnas: la categoría de referencia es la moda de Train y los niveles de menos de 0,5 % se agrupan en «Otros». Elegí one-hot sobre label encoding porque este último impondría un orden falso entre localidades. En la tabla, tres siniestros reales antes y después: la franja pasa a una columna binaria y los números quedan estandarizados. En total son 41 columnas dummy y 77 columnas listas para modelar.

## Diapositiva 10 — Transformación 2: normalización [9:45 – 10:50]

> Estandaricé las 12 variables numéricas con Z-score: resto la media de Train y divido por el desvío de Train. Lo elegí porque los métodos que usaré después, la regresión regularizada, k-medias y PCA, son sensibles a la escala. Frente al min-max, el Z-score es menos vulnerable a los extremos, y además ya había acotado los conteos.
>
> Los histogramas muestran que cambia la escala pero no la forma de la distribución. Y hay una prueba de que no hubo fuga: en el Test la media no da exactamente cero, da aproximadamente cero, porque Test no participó en el cálculo.

*Muestra el fragmento del Z-score: usa `P$media` y `P$desvio`, los parámetros de Train.*

## Diapositiva 11 — Transformación 3: PCA y control de fuga [10:50 – 12:00]

> Apliqué PCA sobre las 12 variables numéricas estandarizadas de Train. El criterio fue retener al menos el 95 % de la varianza, lo que se logra con 7 componentes, que acumulan 98,3 %. Lo guardo como un conjunto alterno que usaré para el agrupamiento, no como reemplazo de las variables originales.
>
> Lo más importante metodológicamente es la regla contra la fuga de datos. Primero parto 70/30, estratificado por gravedad y con semilla fija. Luego ajusto todos los parámetros solo con Train: medianas, topes, medias, desvíos, niveles de las categorías y la rotación del PCA. Y después aplico la misma función a Train, a Test y la usaré en el despliegue. Son tres líneas de código. El informe ejecuta cuatro pruebas automáticas cada vez que se compila, y las cuatro pasan: re-aplicar reproduce exactamente el resultado, Train y Test tienen las mismas columnas, no hay solape entre ellos, y los parámetros no usan Test.

## Diapositiva 12 — Cierre y puente [12:00 – 13:00]

> Para cerrar: el preprocesamiento dejó 195.946 siniestros limpios, particionados en 137.162 para entrenamiento y 58.784 para prueba, con 77 columnas listas para modelar, los parámetros guardados en archivos .rds y un flujo reproducible sin fuga de datos.
>
> La técnica que sigue es clasificación multiclase, porque mi pregunta es predecir la gravedad en tres clases. Compararé regresión logística regularizada, bosque aleatorio y gradient boosting, evaluados con recall por clase, F1 macro y AUC, nunca solo con accuracy, porque la clase fatal es 43 veces menor que la mayoritaria; el desbalance se tratará solo dentro de Train. Además aplicaré k-medias sobre el espacio PCA para identificar los perfiles de riesgo de la hipótesis 3. Muchas gracias; quedo atento a sus preguntas.

---

## Preguntas del docente [13:00 – 15:00]

**¿Por qué imputaron en lugar de eliminar esos registros?**
Porque el faltante es de solo 0,35 % por siniestro, pero es informativo: esos siniestros tienen 6,3 % de fatales contra 1,5 %. Eliminarlos sacaría del entrenamiento justamente casos graves y sesgaría el modelo contra la clase de interés. Dejo además el indicador `edad_imputada`.

**¿Por qué la mediana y no la media o KNN?**
La edad tiene sesgo a la derecha, y la mediana es robusta. KNN agrega complejidad y costo para un faltante menor a 1 % y exigiría definir una distancia sobre variables mixtas. Y se calcula solo en Train.

**¿Cómo decidieron qué atípicos conservar?**
Comparé IQR, Z-score y percentil 99,5. El IQR marca 22,5 % por la forma de los conteos, así que no sirve a ciegas. Conteos: acoto al P99,5 de Train. Edades altas plausibles: conservo. Valores imposibles (edad 118, conductores de menos de 10 años): los anulo porque son errores de captura.

**¿Cómo verificaron que la limpieza no distorsionó la distribución?**
Con los gráficos de antes y después (edad, boxplots, histogramas). Winsorizar afecta solo 0,1 % de las filas; la normalización cambia la escala pero no la forma; y la partición estratificada mantiene la proporción de clases (1,53 %) idéntica en Train y Test.

**¿Qué diferencia habría con otro escalado o codificación?**
Min-max sería muy sensible a los extremos. Label encoding impondría un orden falso entre localidades o franjas. Los árboles no necesitan escalado, pero no se perjudican.

**¿Qué variables nuevas crearon y por qué ayudan?**
Franja horaria, festivo, hora cíclica (H2); presencia de peatón, ciclista, motociclista y proporción de vulnerables (H1); índice de heterogeneidad y vulnerable con pesado (H3).

**¿Qué técnica aplicarán y cómo se relaciona con su pregunta?**
Clasificación multiclase para predecir la gravedad, y k-medias sobre el PCA para los perfiles de riesgo de H3.

**¿Cómo evitaron la fuga de datos?**
Las reglas deterministas van antes de la partición. Todo lo aprendido se calcula solo en Train y se guarda en `modelos/parametros_transformacion.rds`. La función de aplicación es idempotente y hay cuatro pruebas automáticas.

**Si piden código en vivo:** abre `scripts/funciones.R` (`ajustar_transformacion()` y `aplicar_transformacion()`) o ejecuta `rmarkdown::render("informe_final.Rmd")`. Si el tiempo de compilación preocupa, muestra los datos ya procesados en `datos/clean/`.

---

## Lista de chequeo (según los lineamientos)

- [x] Problema contextualizado y relevante (diap. 1–2) · hipótesis claras (diap. 2)
- [x] Objetivo general y 5 específicos mapeados a fases (diap. 3)
- [x] Fuente, variables y tipos (diap. 4) · variables eliminadas con motivo (diap. 5)
- [x] Faltantes con porcentaje y estrategia justificada (diap. 6)
- [x] Inconsistencias, duplicados y errores documentados (diap. 7)
- [x] Atípicos con método explícito y decisión (diap. 8)
- [x] Evidencia antes y después (diap. 6–8, 9, 10)
- [x] Normalización, codificación, derivadas y PCA con varianza explicada (diap. 9–11)
- [x] Fragmentos de código en R (diap. 5, 6, 8, 10, 11)
- [x] Cierre y puente a la minería de datos (diap. 12)
- [ ] **Cronometrar el ensayo (debe cerrar en 13:00)**
- [ ] **Probar que el `.Rmd` compila en tu computador antes de presentar**
- [ ] **Abrir RStudio con el proyecto y los datos antes de empezar**
- [ ] **Revisar la legibilidad de los gráficos en el proyector**

*Errores frecuentes que señalan los lineamientos: gastar demasiado tiempo en el contexto (las diap. 1–4 deben cerrar antes de 3:40) y quedarse sin espacio para la transformación (diap. 9–11 tienen 3,5 min).*
