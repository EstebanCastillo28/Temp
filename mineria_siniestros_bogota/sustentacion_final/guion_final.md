# Guion de la sustentación final — 15 min de exposición y demostración + 5 de preguntas

**Presenta:** Juan Esteban Castillo Baquero · ID 852500
**Material:** `sustentacion_final/sustentacion_final.pptx` (12 diapositivas), RStudio con el proyecto abierto, `despliegue/app.R` corriendo.
*Lo que va en cursiva son indicaciones para ti, no se lee. No leas el código: muéstralo y explica la decisión.*

---

## Diapositiva 1 — Apertura y puente [0:00 – 1:00]
> En la entrega anterior dejé 195.946 siniestros viales de Bogotá limpios y transformados: 137.162 para entrenar y 58.784 para probar, con 77 variables listas y sin fuga de datos. Hoy les muestro lo que sigue: modelar, interpretar y, sobre todo, usar el modelo.
>
> La pregunta de investigación es qué combinación de condiciones se asocia con los desenlaces más graves. La dificultad es que solo el 1,5 % de los siniestros termina con víctimas fatales: por cada fatal hay 43 que no lo son.

## Diapositiva 2 — Técnicas elegidas [1:00 – 2:00]
> Es un problema de clasificación multiclase ordinal: solo daños, con heridos, con muertos, con 75 predictores mixtos. Comparé tres técnicas complementarias. La regresión logística regularizada, como línea base interpretable y con probabilidades calibradas. El bosque aleatorio, porque capta interacciones, por ejemplo peatón con noche, sin supuestos. Y XGBoost, que suele ser el mejor en datos tabulares.
>
> Descarté el árbol único por su varianza; k vecinos y SVM porque con 137 mil filas son costosos y sensibles a las dummies; y las redes neuronales porque no aportan en tabulares de este tamaño y son difíciles de explicar a quien decide.

## Diapositiva 3 — División, validación y métricas [2:00 – 3:00]
> Partí 70/30, estratificado y con semilla 2025. El Test no lo uso para elegir nada. Dentro de Train hago validación cruzada de cinco pliegues, los mismos para los tres modelos, para elegir hiperparámetros y la regla de decisión.
>
> El desbalance no lo trato remuestreando, porque eso alteraría las probabilidades que luego muestro al usuario. Lo trato en la decisión: la clase predicha maximiza la probabilidad por un multiplicador, y esos multiplicadores se ajustan solo con predicciones fuera de muestra de Train.
>
> Las métricas: el recall de la clase fatal, porque no detectar un fatal es el error más costoso; la precisión, que mide las falsas alarmas; el F1 macro y el área bajo la curva precisión–recall. No uso solo accuracy: decir siempre «solo daños» da 65 % y no detecta ningún fatal. Una limitación honesta: dentro de la validación cruzada los parámetros de transformación se calcularon con todo Train, lo que la hace levemente optimista; el Test no está afectado.

## Diapositiva 4 — Resultados [3:00 – 4:00]
> Los tres modelos rinden parecido; los de árboles superan a la logística, señal de que hay interacciones. El campeón por validación cruzada fue XGBoost. En Test: F1 macro de 0,66. Distingue bien solo daños de heridos, con recall de 91 % y 82 %. La clase fatal es la difícil: recall de 27 % con precisión de 21 %, pero con un AUC de 0,917 y un AUC de precisión–recall catorce veces mejor que el azar. Es decir, ordena bien aunque no acierte cada caso.

## Diapositiva 5 — Análisis crítico [4:00 – 5:00]
> No hay sobreajuste respecto a datos nuevos: el F1 macro es 0,659 en validación cruzada y 0,658 en Test; en Train es 0,699, una brecha esperable en árboles. La clase fatal es difícil porque faltan velocidad, estado de la vía, clima y uso del casco. Hay sesgo de registro: el IPAT subregistra los siniestros de solo daños. Y el modelo detecta casi ninguno de los fatales que ocurren sin actor vulnerable.
>
> Las probabilidades están calibradas, y por eso sirven para ordenar. Con los umbrales fijados en Train, el nivel «Alto» agrupa 5 % de los siniestros y captura 49 % de los fatales: 148 por mil, frente a 2,3 por mil en el nivel «Bajo».

## Diapositiva 6 — Variables e hipótesis [5:00 – 6:00]
> Lo que más información aporta es quién participa: peatón, proporción de vulnerables, número de conductores. Mucho más que la localidad o la hora. Para contrastar las hipótesis con inferencia usé una regresión logística ordinal.
>
> H1 se confirma: con peatón los momios de mayor gravedad se multiplican por 28 y con motociclista por 20; el bloque de actor vulnerable es el que más aporta, muy por encima de la clase de siniestro y de la localidad. H2 se confirma con efecto pequeño: la noche multiplica los momios por 1,6 y el fin de semana por 1,1. H3, en parte: hay cinco perfiles muy distintos en letalidad, de 0,8 a 65 fatales por mil, pero los separa el actor, no la localidad ni la hora. Matiz: peatón y atropello están muy ligados; es asociación, no causalidad.

## Diapositiva 7 — Valor para la decisión [6:00 – 7:00]
> El perfil «peatón o moto, un solo vehículo» es el 13 % de los siniestros, pero concentra el 55 % de los fatales. Para la meta del plan distrital de reducir a la mitad las muertes, eso dice dónde rinde más intervenir: cruces seguros, control de velocidad y campañas por tipo de actor, y dentro de cada perfil, focalizar por territorio. El nivel de riesgo sirve para priorizar el trabajo de análisis y de operativos; no para predecir un evento individual.

## Diapositiva 8 — Diseño del artefacto [7:00 – 8:30]
> Construí un artefacto con tres puertas de entrada sobre el mismo núcleo: una aplicación Shiny para analistas de movilidad, una API para equipos técnicos y una función en R. Carga el modelo ya entrenado y los parámetros de Train; no reentrena. El flujo es: valido la entrada, construyo las variables del modelo, transformo con los parámetros de Train, predigo y traduzco a lenguaje claro.
>
> Cómo se lee la salida: seis por ciento de víctimas fatales significa que, de cien siniestros parecidos entre 2015 y 2020, unos seis terminaron con muertos.

## Diapositiva 9 — Demostración en vivo [8:30 – 13:00]
*Pasa a la aplicación Shiny (`despliegue/app.R`, Run App). Orden:*
1. **Caso normal.** Selecciona «Atropello nocturno (Kennedy)» y pulsa *Estimar gravedad*. Esperado: **20 %**, nivel **Alto**, perfil «Peatón o moto, un solo vehículo». Léelo como lo leería alguien sin formación técnica: *«De cien siniestros parecidos, unos veinte terminaron con muertos; está en el nivel más alto de riesgo»*.
2. **Conexión con las métricas.** *«Un nivel Alto corresponde en Test a 148 fatales por mil, frente a 15 en promedio; el modelo detecta 27 % de los fatales con 21 % de precisión: sirve para priorizar»*.
3. **Contraste.** «Choque entre dos autos (día hábil)»: **0,03 %**, nivel Bajo. «Moto y bus (sábado de madrugada)»: **16 %**, Alto.
4. **Caso del docente.** Pide que lo dicte y escríbelo (ver guía abajo).
5. **Caso límite.** «Caso límite: 25 vehículos»: se evalúa (0,7 %) con una advertencia de valor extremo.
6. **Entrada inválida.** «Entrada inválida»: se rechaza con mensajes claros y sin predicción.
7. **Datos nuevos en lote.** Pestaña *Lote de casos*, sube `despliegue/ejemplos/casos_ejemplo.csv` (6 válidos, 1 con error).
8. *(Opcional)* API con `Rscript despliegue/iniciar_api.R` y `Rscript despliegue/probar_api.R`.

*Si falla algo: pasa a la diapositiva 12 (capturas) o abre `sustentacion_final/plan_b/demo.mp4`. Máximo nivel Básico en ese criterio, así que intenta primero la versión local.*

## Diapositiva 10 — Monitoreo y ética [13:00 – 14:00]
> Vigilo tres cosas. La deriva de las entradas con el PSI, ya implementado: entre 2020 y 2015–2019 todas las variables son estables; y probé con un lote simulado donde aumentan las motocicletas y la noche, y el semáforo pasa a rojo. El desempeño cuando llegan las etiquetas reales, con alerta si el recall de los fatales cae más de diez puntos. Y reentrenar ante deriva, caída de desempeño o datos nuevos.
>
> Ética: el modelo describe siniestros, no personas; no debe usarse para sancionar ni perfilar individuos; hay sesgo de registro y territorial; y la probabilidad es una estimación, no una certeza.

## Diapositiva 11 — Conclusiones [14:00 – 15:00]
> Tres ideas. La preparación de los datos importó más que el algoritmo: detectar la fuga por pasajeros, la edad 118 y las gravedades inconsistentes evitó modelos engañosamente buenos. El modelo ordena bien pero no adivina fatales: su valor es priorizar. Y domina el tipo de actor y de vehículo sobre la localidad y la hora. Limitaciones: datos hasta 2020 y sin velocidad, vía, clima ni casco. Trabajo futuro: datos nuevos con más variables, validación temporal y calibración, y llevar la API a un contenedor con monitoreo automático. Muchas gracias; quedo atento a las preguntas.

---

## Cómo ingresar el caso del docente en la app (30 segundos)
| Si el docente dice… | En el formulario |
|---|---|
| Fecha y hora | *Fecha* y *Hora* (la hora acepta de 0 a 23,5) |
| Localidad | menú *Localidad* |
| «Un atropello» / «un choque» | *Clase de siniestro* (y *Tipo de choque*: «No aplica» si no es choque) |
| «Una moto y un bus» | *Motocicletas* = 1, *Buses* = 1 |
| «Un peatón» | *Peatones* = 1 y clase *Atropello* |
| «Un vehículo se fue» | marca *Algún vehículo huyó* |
| «Edades 25 y 40» | *Edad del más joven* = 25, *del mayor* = 40 (o «No se conocen las edades») |

Ejemplo para practicar: *«Un camión y una moto chocan en Bosa un viernes a las 7 pm»* → Choque, Vehículo, Bosa, Camiones = 1, Motocicletas = 1, hora 19.

## Preguntas probables (5 min)
- **¿Por qué esta técnica y no otra?** Probé tres. Los de árboles captan interacciones que la logística no (F1 0,654 y 0,658 frente a 0,641). Elegí XGBoost por mayor F1 macro en validación cruzada y menor log-loss. Descartados: árbol único, k vecinos, SVM y redes neuronales.
- **¿Cómo evitaron sobreajuste y fuga?** Test intocado hasta el final; validación cruzada de 5 pliegues solo en Train; parámetros de transformación solo con Train; early stopping; F1 de 0,659 (CV) frente a 0,658 (Test). Limitación: en la CV la transformación usó todo Train.
- **¿Qué significa la métrica principal? ¿Qué error es más costoso?** El recall de la clase fatal: de cada 100 fatales, cuántos detecta (27). Es más costoso no detectar un fatal que una falsa alarma; por eso el ajuste de la decisión con multiplicadores. La precisión (21 %) mide el costo de las falsas alarmas.
- **¿Qué pasa si el usuario ingresa un valor fuera de rango?** Valores imposibles (hora 30, edad negativa) se rechazan con mensaje. Valores extremos pero posibles (25 vehículos) se evalúan con advertencia y se acotan al tope aprendido en Train (4 vehículos).
- **¿Qué harían si el desempeño empeora?** PSI trimestral; con etiquetas reales, recall fatal y F1 del lote; alerta si el recall cae más de 10 puntos o PSI > 0,25; reentrenar con datos nuevos y publicar una versión nueva (`modelo_final.rds` guarda versión y fecha).
- **¿Cómo lo explicarían a una persona sin formación técnica?** «El sistema compara su caso con 137 mil siniestros reales de Bogotá y dice qué tan frecuente fue que casos parecidos terminaran con muertos. Seis por ciento significa seis de cada cien. Sirve para decidir dónde mirar primero, no para predecir un accidente concreto».
- **¿Qué sesgos o riesgos éticos tiene?** Subregistro en el IPAT; sesgo territorial; riesgo de usarlo para sancionar personas (no corresponde); la probabilidad no es certeza; no detecta fatales sin actor vulnerable (recall 2 %).

## Lista de chequeo antes de presentar
- [ ] Cronometrar: 15 min de exposición y demostración
- [ ] RStudio abierto con el proyecto, `instalar_dependencias.R` ya ejecutado y la app corriendo (Run App) antes de empezar
- [ ] Probar `Rscript despliegue/probar_despliegue.R` (debe decir «Todas las pruebas pasaron»)
- [ ] Tener a mano `sustentacion_final/plan_b/` (capturas y `demo.mp4`)
- [ ] Revisar gráficos al proyectarlos
- [ ] Computador cargado, sin conexión necesaria (todo es local)
