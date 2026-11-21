# Informe del proyecto final — Simulador "Finca La Esperanza"

**Curso:** Electiva CMD: Ingeniería y Desarrollo Regional · **Período:** 2026-60 · **Tercer corte** · **Trabajo individual**
**Autor:** _(nombre y código del estudiante)_

## 1. Investigación
### 1.1 Problema
La **ganadería extensiva** (pastoreo continuo, sobrecarga animal, potreros sin árboles, quemas y expansión sobre bosque) es una de las principales presiones sobre los ecosistemas rurales de Colombia. El país destina a pasturas un área mucho mayor a la de vocación ganadera, y la ganadería está asociada a la deforestación en la Amazonía, el piedemonte y el Caribe.

> Cifras aproximadas usadas como contexto (verificar y citar la edición exacta antes de entregar): ~34 M ha en pasturas vs. ~15 M ha con vocación ganadera (IGAC / Fedegán); hato nacional cercano a 29 M de cabezas (ICA); deforestación anual reportada por el IDEAM entre ~80 000 y ~174 000 ha según el año (2021–2023).

### 1.2 Causas, impactos y soluciones
| Causas | Impactos | Soluciones de manejo |
|---|---|---|
| Praderización del bosque, acaparamiento de tierras | Pérdida de hábitat y biodiversidad | Restauración y regeneración natural, corredores |
| Sobrepastoreo, pastoreo continuo | Compactación, erosión, baja productividad | Pastoreo rotacional con descanso |
| Quemas y agroquímicos | Pérdida de suelo, contaminación de agua, emisiones | Abonos orgánicos, no quemar |
| Potreros sin árboles, ganadería en rondas hídricas | Menor infiltración, quebradas secas, estrés calórico | Sistemas silvopastoriles, cercas y reforestación de rondas |
| Baja rentabilidad por hectárea | Endeudamiento, abandono | Bancos forrajeros, PSA, primas de mercado sostenible |

Referencias para ampliar (consultar directamente): proyecto *Ganadería Colombiana Sostenible* (Fedegán, CIPAV, FAO, TNC, Fondo Acción), publicaciones del CIPAV sobre sistemas silvopastoriles intensivos, boletines de deforestación del IDEAM, estadísticas de inventario bovino del ICA, Estrategia Integral de Control a la Deforestación (EICDGB) y el esquema de Pago por Servicios Ambientales (Decreto 870 de 2017).

## 2. Diseño
### 2.1 Elementos del ecosistema simulado
- **Territorio:** malla 8×6 de potreros de 1 ha (38 ha útiles + quebrada). Columna 1 = ronda hídrica.
- **Coberturas/especies:** pasto (kikuyo/braquiaria), silvopastoril (leucaena, botón de oro, árboles), banco forrajero, regeneración, bosque.
- **Animales:** hato bovino con condición corporal, natalidad y mortalidad.
- **Clima:** régimen bimodal de lluvias + **El Niño** (meses 30–39) y **La Niña** (meses 78–86), idénticos en cada partida para comparar estrategias.
- **Recursos:** suelo, caudal de la quebrada, calidad del agua, biodiversidad, carbono, capital.

### 2.2 Requerimientos
**Funcionales:** RF1 mapa interactivo por potrero con capas; RF2 acciones de manejo con costo (silvopastoril, forraje, regeneración, abono, fertilizante, quema, tala); RF3 manejo del hato (compra/venta, pastoreo continuo/rotacional, suplemento); RF4 avance mensual/anual/automático; RF5 indicadores y gráfica histórica; RF6 bitácora de eventos; RF7 evaluación final con puntaje; RF8 sección educativa; RF9 formulario de retroalimentación con exportación.
**No funcionales:** RNF1 web sin instalación ni servidor (HTML/JS), RNF2 responsive, RNF3 resultados reproducibles (semilla fija), RNF4 motor separado de la interfaz y con pruebas automáticas, RNF5 español.

### 2.3 Interfaz
Tres pestañas (Simulador / Aprende / Retroalimentación). El simulador tiene: mapa (izquierda), controles + indicadores + gráfica (derecha) y bitácora (abajo). Semáforo verde/amarillo/rojo en indicadores. Al finalizar se muestra un resumen con puntaje.

## 3. Desarrollo
- **Herramientas:** HTML5, CSS3, JavaScript (ES2015+), Canvas 2D; Node.js solo para pruebas.
- **Arquitectura:** `js/sim.js` (motor puro), `js/app.js` (interfaz), `js/content.js` (contenido educativo).
- **Reglas principales (paso mensual):**
  1. *Pasto:* crecimiento logístico `r·humedad·fertilidad·B·(1−B/K) + rebrote`; mayor con descanso; la sombra amortigua la sequía.
  2. *Pastoreo:* demanda del hato (14 u/animal/mes) menos forraje de árboles, bancos y suplemento; el resto se toma del pasto (utilización 40 % continuo, 55 % rotacional sobre ⅓ de potreros con más pasto).
  3. *Hato:* condición corporal según oferta/demanda; natalidad 1 %/mes·condición; mortalidad si condición < 25.
  4. *Suelo:* erosión si pasto < 35 y lluvia; ganancia por sombra, cobertura, silvopastoril; pérdida por sobrepastoreo, fertilizante químico y quemas.
  5. *Agua:* caudal = lluvia × infiltración (suelo + árboles) con amortiguación; calidad según ronda arbolada, acceso del ganado, químicos y sedimentos.
  6. *Biodiversidad:* objetivo por tipo de cobertura + conectividad con bosque, con respuesta lenta (6 %/mes).
  7. *Carbono:* almacén (árboles + suelo) − emisiones acumuladas (ganado, quemas, tala).
  8. *Economía:* ingreso por animal × condición, PSA por bosque/regeneración/silvopastoril, prima de 12 % si ≥ 35 % de la finca tiene árboles; costos fijos y por animal. Quiebra si capital < −25 M.
- **Puntaje:** 40 % económico + 60 % sostenibilidad (suelo, caudal, calidad del agua, biodiversidad, carbono).
- **Limitaciones:** parámetros calibrados cualitativamente (no con datos de campo); sin precios variables, sin enfermedades ni plagas; no sustituye una evaluación agronómica real.

## 4. Pruebas y retroalimentación
### 4.1 Pruebas automáticas (`node tests/sim.test.js`) — 11 pruebas aprobadas
Estado inicial, reproducibilidad, rangos de indicadores durante 120 meses, colapso del manejo tradicional, superioridad de la estrategia sostenible (puntaje, suelo, agua, capital), costos de acciones, restricción por falta de dinero, costo ambiental de talar, consolidación de bosque, efecto de El Niño, compra/venta.

### 4.2 Resultados de estrategias (semilla 2026)
| Estrategia | Resultado |
|---|---|
| Sin intervención (continuo, sin árboles) | Quiebra hacia el mes ~70; suelo ~13/100; puntaje ≈ 12 |
| Rotacional | ≈ 76/100 |
| Rotacional + 5 potreros silvopastoriles | ≈ 80/100, mayor capital, biodiversidad y caudal |

### 4.3 Prueba de interfaz
Verificada con navegador automatizado (Chromium): carga sin errores, selección de potrero, acciones, avance de años, diálogo final y guardado del formulario.

### 4.4 Retroalimentación de usuarios — **por completar**
El formulario de la pestaña *Retroalimentación* guarda respuestas en el navegador y permite exportarlas (JSON). Pasos: (1) pide a 5–10 compañeros/familiares que jueguen una partida; (2) que diligencien el formulario; (3) exporta y pega aquí el resumen; (4) lista las mejoras que hiciste.

| Criterio | Promedio (1-5) |
|---|---|
| Facilidad de uso | _por completar_ |
| Interfaz | _por completar_ |
| Realismo | _por completar_ |
| Aprendizaje | _por completar_ |

## 5. Conclusiones
- La ganadería extensiva sin gestión es económica y ambientalmente frágil: el sobrepastoreo degrada suelo y agua y termina afectando el ingreso.
- Rotación + árboles en potrero + protección del agua mejoran a la vez productividad, resiliencia a sequías y sostenibilidad: producción y conservación **no son excluyentes**.
- Las prácticas de beneficio inmediato (quemar, talar, agroquímicos) dan ganancias de corto plazo pero reducen el puntaje a largo plazo.
- Los incentivos (PSA, primas de mercado) ayudan a cerrar la brecha de rentabilidad durante la transición.
- El simulador cumple el objetivo educativo: permite experimentar estrategias y ver sus consecuencias en 10 años.
