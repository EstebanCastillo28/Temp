// Genera presentacion/sustentacion.pptx (12 diapositivas, 13 min) con pptxgenjs.
// Uso (desde la raíz del proyecto):  NODE_PATH=<ruta a node_modules> node presentacion/build_deck.js
// Requiere haber ejecutado antes: Rscript scripts/03_figuras_sustentacion.R
const pptxgen = require("pptxgenjs");
const path = require("path");
const FIG = (f) => path.join(__dirname, "figuras", f);

const THEME = {
  name: "Siniestros Bogota", headFontFace: "Cambria", bodyFontFace: "Calibri",
  colors: { dk1: "14213D", lt1: "FFFFFF", dk2: "2B3A67", lt2: "F2F4F8", accent1: "FCA311", accent2: "C0392B", accent3: "8D99AE",
            accent4: "2A9D8F", accent5: "BFD0EA", accent6: "6C757D", hlink: "3A86FF", folHlink: "8D99AE" },
};
const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE"; // 13.33 x 7.5
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = "Sustentación — Gravedad de los siniestros viales en Bogotá D.C.";
pres.author = "Juan Esteban Castillo Baquero";
const C = pres.SchemeColor;
const FOOT = "Castillo Baquero · ID 852500 · Minería de Datos — UNIMINUTO";

pres.defineSlideMaster({
  title: "CONTENIDO", background: { color: "FFFFFF" },
  objects: [
    { text: { text: FOOT, options: { x: 0.6, y: 7.0, w: 8, h: 0.3, fontSize: 10, color: C.accent6, margin: 0 } } },
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.35, w: 12.1, h: 0.85, fontSize: 32, bold: true, color: C.text1, valign: "middle", margin: 0 }, text: "" } },
  ],
  slideNumber: { x: 12.2, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: C.accent6, align: "right" },
});
pres.defineSlideMaster({
  title: "OSCURO", background: { color: THEME.colors.dk1 },
  objects: [
    { placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.6, w: 12.1, h: 1.2, fontSize: 40, bold: true, color: C.background1, valign: "top", margin: 0 }, text: "" } },
  ],
  slideNumber: { x: 12.2, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: C.accent3, align: "right" },
});

// ---------- helpers ----------
const card = (s, name, x, y, w, h, fill = C.background2) =>
  s.addShape(pres.shapes.RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { color: fill, width: 0 }, objectName: name });
const txt = (s, name, t, o) => s.addText(t, Object.assign({ isTextBox: true, objectName: name, margin: 0, valign: "top", fontSize: 16, color: C.text1 }, o));
const code = (s, name, lines, x, y, w, h) => {
  card(s, name + "-fondo", x, y, w, h, C.text1);
  txt(s, name, lines.join("\n"), { x: x + 0.15, y: y + 0.1, w: w - 0.3, h: h - 0.2, fontFace: "Courier New", fontSize: 12, color: C.accent5, valign: "middle" });
};
const cap = (s, name, t, x, y, w) => txt(s, name, t, { x, y, w, h: 0.3, fontSize: 12, color: C.accent6, italic: true });
const hdr = (t) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: THEME.colors.dk1 }, fontSize: 13 } });
const cell = (t, o = {}) => ({ text: t, options: Object.assign({ fontSize: 13, color: C.text1 }, o) });
const table = (s, name, rows, o) =>
  s.addTable(rows, Object.assign({ objectName: name, border: { type: "solid", pt: 0.5, color: "D5DAE5" }, valign: "middle", margin: [0.04, 0.08, 0.04, 0.08] }, o));
const notes = (s, t) => s.addNotes(t);
const newSlide = (master, section, title) => { const s = pres.addSlide({ masterName: master, sectionTitle: section }); s.addText(title, { placeholder: "title" }); return s; };

// ====================== 1. APERTURA ======================
pres.addSection({ title: "Apertura" });
let s = newSlide("OSCURO", "Apertura", "Gravedad de los siniestros viales en Bogotá D.C.");
txt(s, "subtitulo", "Preprocesamiento y transformación de datos (ciclo KDD) · Juan Esteban Castillo Baquero · ID 852500", { x: 0.6, y: 1.75, w: 12.1, h: 0.5, fontSize: 18, color: C.accent5 });
const stats = [["195.946", "siniestros viales\nregistrados 2015–2020", C.accent1], ["1,5 %", "terminan con\nvíctimas fatales", C.accent1], ["68 ‰ vs 1,2 ‰", "fatales con peatón\nvs sin actor vulnerable", C.accent2]];
stats.forEach(([n, l, col], i) => {
  const x = 0.6 + i * 4.1;
  card(s, "dato-fondo-" + (i + 1), x, 3.0, 3.9, 3.3, C.accent2 === col ? "3A1F2B" : THEME.colors.dk2);
  txt(s, "dato-cifra-" + (i + 1), n, { x: x + 0.25, y: 3.3, w: 3.4, h: 1.2, fontSize: i === 2 ? 34 : 54, bold: true, color: col, valign: "middle" });
  txt(s, "dato-etiqueta-" + (i + 1), l, { x: x + 0.25, y: 4.7, w: 3.4, h: 1.3, fontSize: 20, color: C.background1 });
});
notes(s, "[1 min — apertura de impacto] Abrir con el dato, sin presentarse largo. De cada mil siniestros viales en Bogotá, 15 terminan con víctimas fatales; si en el siniestro hay un peatón, la cifra sube a 68. Ese contraste es el problema: el evento más grave es el más raro, y por eso los datos hay que prepararlos con mucho cuidado antes de modelar. Presentarse: Juan Esteban Castillo Baquero.");

// ====================== 2. PROBLEMA ======================
s = newSlide("CONTENIDO", "Apertura", "Problema, relevancia e hipótesis");
txt(s, "contexto", [
  { text: "Plan Distrital de Seguridad Vial 2023–2032: reducir 50 % las víctimas fatales (línea base 2022)", options: { bullet: true, breakLine: true } },
  { text: "Intervenciones costosas y limitadas: hay que focalizarlas", options: { bullet: true, breakLine: true } },
  { text: "Hoy el análisis es descriptivo; ningún modelo anticipa la gravedad", options: { bullet: true } },
], { x: 0.6, y: 1.5, w: 5.9, h: 3.0, fontSize: 18, paraSpaceAfter: 10 });
s.addImage({ path: FIG("f1_perfil_actor.png"), x: 6.8, y: 1.4, w: 5.9, h: 3.034, altText: "Tasa de siniestros fatales por mil según el actor vulnerable involucrado" });
cap(s, "fuente-1", "Fatales por 1.000 siniestros, conjunto Train (n = 137.162)", 6.8, 4.45, 5.9);
const hips = [["H1", "Peatones y motociclistas se asocian con mayor gravedad, más que la clase de siniestro o la localidad."],
              ["H2", "Noche y fines de semana tienen mayor probabilidad de desenlace fatal que el día hábil."],
              ["H3", "Hay perfiles de riesgo diferenciables por localidad, franja y tipo de actor."]];
hips.forEach(([h, t], i) => {
  const x = 0.6 + i * 4.1;
  card(s, "hipotesis-fondo-" + h, x, 4.95, 3.9, 1.85);
  txt(s, "hipotesis-id-" + h, h, { x: x + 0.2, y: 5.05, w: 1, h: 0.45, fontSize: 22, bold: true, color: C.accent2 });
  txt(s, "hipotesis-texto-" + h, t, { x: x + 0.2, y: 5.55, w: 3.5, h: 1.2, fontSize: 15 });
});
notes(s, "[1 min] Contexto: la meta del Plan Distrital es reducir 50 % las víctimas fatales; los recursos son limitados, así que se necesita focalizar. El gráfico ya muestra por qué: con peatón la tasa es 68 por mil, con ciclista 42, con motociclista 25 y sin actor vulnerable 1,2. Pregunta de investigación: ¿qué combinación de condiciones se asocia con los desenlaces más graves? Tres hipótesis: H1 actores vulnerables, H2 noche y fin de semana, H3 perfiles de riesgo. Nota de honestidad: parte de la fuerza del peatón es mecánica (un atropello casi siempre lesiona).");

// ====================== 3. OBJETIVOS ======================
s = newSlide("CONTENIDO", "Apertura", "Objetivos y ruta de trabajo");
card(s, "objetivo-general-fondo", 0.6, 1.4, 12.1, 1.25);
txt(s, "objetivo-general", [{ text: "Objetivo general. ", options: { bold: true } },
  { text: "Construir y evaluar un modelo que clasifique la gravedad de un siniestro (solo daños, con heridos, con muertos) e identifique perfiles de riesgo para focalizar intervenciones." }],
  { x: 0.85, y: 1.5, w: 11.6, h: 1.05, fontSize: 17, valign: "middle" });
const filaObj = (o, f, a, activo) => [cell(o, { fontSize: 14 }), cell(f, { fontSize: 14 }), cell(a, { fontSize: 14, bold: activo, color: activo ? C.accent2 : C.accent6 })];
table(s, "tabla-objetivos", [
  [hdr("Objetivo específico"), hdr("Fase del proceso"), hdr("Alcance")],
  filaObj("1. Integrar Siniestros, Vehículos y Actor Vial en una tabla a nivel de siniestro", "Selección · limpieza", "Esta entrega", true),
  filaObj("2. Caracterizar la siniestralidad y cuantificar el desbalance de la clase", "Dominio · exploración", "Esta entrega", true),
  filaObj("3. Construir variables derivadas temporales y de perfil de involucrados", "Transformación", "Esta entrega", true),
  filaObj("4. Entrenar y comparar ≥ 3 clasificadores con métricas para clases desbalanceadas", "Minería de datos", "Siguiente", false),
  filaObj("5. Agrupamiento para perfiles de alto riesgo y recomendaciones", "Minería · interpretación", "Siguiente", false),
], { x: 0.6, y: 2.95, w: 12.1, colW: [7.4, 2.9, 1.8], rowH: [0.45, 0.62, 0.62, 0.62, 0.62, 0.62] });
notes(s, "[1 min] Objetivo general en una frase. Los cinco objetivos específicos están mapeados a fases: los tres primeros se cubren en esta entrega (selección, limpieza, transformación); entrenar tres clasificadores y el agrupamiento vienen en la siguiente. Hoy cubro hasta la transformación.");

// ====================== 4. DATOS ======================
pres.addSection({ title: "Datos y selección" });
s = newSlide("CONTENIDO", "Datos y selección", "Datos: fuente y variables clave");
[["196.152", "siniestros", "SINIESTROS"], ["422.416", "personas", "ACTOR_VIAL"], ["371.605", "vehículos", "VEHICULOS"]].forEach(([n, l, h], i) => {
  const x = 0.6 + i * 4.1;
  card(s, "fuente-fondo-" + (i + 1), x, 1.4, 3.9, 1.15);
  txt(s, "fuente-cifra-" + (i + 1), n, { x: x + 0.2, y: 1.48, w: 2.2, h: 0.65, fontSize: 30, bold: true, color: C.accent2, valign: "middle" });
  txt(s, "fuente-etiqueta-" + (i + 1), l, { x: x + 2.4, y: 1.5, w: 1.4, h: 0.6, fontSize: 15, valign: "middle" });
  txt(s, "fuente-hoja-" + (i + 1), h + " · Secretaría de Movilidad (SIGAT/IPAT)", { x: x + 0.2, y: 2.12, w: 3.6, h: 0.35, fontSize: 12, color: C.accent6 });
});
table(s, "tabla-variables", [
  [hdr("Variable"), hdr("Tipo"), hdr("Rol")],
  [cell("GRAVEDAD", { bold: true }), cell("Categórica ordinal (3)"), cell("Objetivo")],
  [cell("FECHA, HORA"), cell("Fecha / hora"), cell("Franja, día, festivo, mes")],
  [cell("CODIGO_LOCALIDAD"), cell("Categórica (20)"), cell("Predictor")],
  [cell("CLASE · CHOQUE · DISENO_LUGAR"), cell("Categóricas"), cell("Predictores")],
  [cell("CONDICION (actor)"), cell("Categórica (5)"), cell("Actor vulnerable")],
  [cell("EDAD · SEXO"), cell("Numérica · categórica"), cell("Perfil etario y de género")],
  [cell("CLASE · SERVICIO · ENFUGA (vehículo)"), cell("Cat. · cat. · binaria"), cell("Heterogeneidad, fuga")],
], { x: 0.6, y: 2.85, w: 8.2, colW: [3.5, 2.3, 2.4], rowH: 0.5 });
card(s, "integracion-fondo", 9.1, 2.85, 3.6, 3.85, THEME.colors.dk1);
txt(s, "integracion-titulo", "Integración", { x: 9.3, y: 3.0, w: 3.2, h: 0.4, fontSize: 18, bold: true, color: C.accent1 });
txt(s, "integracion-texto", "3 granularidades (siniestro, persona, vehículo) → 1 fila por siniestro", { x: 9.3, y: 3.5, w: 3.2, h: 1.3, fontSize: 16, color: C.background1 });
txt(s, "integracion-cifra", "195.946 × 50", { x: 9.3, y: 5.0, w: 3.2, h: 0.7, fontSize: 28, bold: true, color: C.background1 });
txt(s, "integracion-nota", "tras limpieza", { x: 9.3, y: 5.7, w: 3.2, h: 0.35, fontSize: 13, color: C.accent3 });
notes(s, "[1 min] Fuente: consolidado oficial de la Secretaría Distrital de Movilidad, 2015–2020, con tres tablas: siniestros, personas y vehículos, más el diccionario oficial. Variables clave y su tipo en la tabla. La integración pasa de tres granularidades a una fila por siniestro: quedan 195.946 siniestros y 50 columnas tras la limpieza.");

// ====================== 5. SELECCION ======================
s = newSlide("CONTENIDO", "Datos y selección", "Selección: qué se descarta y por qué");
table(s, "tabla-descartadas", [
  [hdr("Variable"), hdr("Motivo de descarte o exclusión")],
  [cell("HIPOTESIS (causa)", { bold: true, fontSize: 14 }), cell("Se asigna después de investigar: información posterior al hecho", { fontSize: 14 })],
  [cell("OBJETO_FIJO", { bold: true, fontSize: 14 }), cell("96,6 % vacío estructural; redundante con tipo de choque", { fontSize: 14 })],
  [cell("MODALIDAD", { bold: true, fontSize: 14 }), cell("61,3 % vacío estructural; ya está en SERVICIO", { fontSize: 14 })],
  [cell("DIRECCION", { bold: true, fontSize: 14 }), cell("Texto libre de cardinalidad altísima; solo se deriva via_avenida", { fontSize: 14 })],
  [cell("ESTADO (ileso/herido/muerto)", { bold: true, fontSize: 14 }), cell("Define la gravedad: solo se usa para auditar el objetivo", { fontSize: 14 })],
  [cell("Pasajeros", { bold: true, fontSize: 14 }), cell("Solo se registran si hay lesión: fuga del objetivo", { fontSize: 14 })],
], { x: 0.6, y: 1.4, w: 7.6, colW: [2.7, 4.9], rowH: [0.45, 0.78, 0.7, 0.7, 0.78, 0.78, 0.7] });
card(s, "fuga-fondo", 8.5, 1.4, 4.2, 2.55);
txt(s, "fuga-etiqueta", "Hallazgo: fuga del objetivo", { x: 8.7, y: 1.5, w: 3.8, h: 0.4, fontSize: 16, bold: true, color: C.accent2 });
txt(s, "fuga-cifra", "2 de 27.365", { x: 8.7, y: 1.95, w: 3.8, h: 0.8, fontSize: 36, bold: true, valign: "middle" });
txt(s, "fuga-texto", "pasajeros registrados están ilesos: solo aparecen si resultaron lesionados", { x: 8.7, y: 2.8, w: 3.8, h: 1.0, fontSize: 15 });
code(s, "codigo-pasajeros", ["# solo conductores, motociclistas,", "# ciclistas y peatones", 'ai <- a %>%', '  filter(!str_starts(condicion, "PASAJERO"))'], 8.5, 4.15, 4.2, 1.7);
cap(s, "nota-peaton", "El peatón se conserva (exige H1), con la salvedad de su relación mecánica con la gravedad.", 0.6, 6.55, 7.6);
notes(s, "[1 min] Cada descarte tiene una razón: redundancia, exceso de vacíos estructurales, información posterior al hecho o fuga del objetivo. Lo más importante es el hallazgo de los pasajeros: de 27.365 solo 2 están ilesos, porque la base solo los registra cuando resultan lesionados. Si los usara, el modelo leería la respuesta. Por eso todas las variables de perfil se calculan sin pasajeros. Muestro la línea de código que lo hace y explico el porqué, no la leo.");

// ====================== 6. LIMPIEZA: FALTANTES ======================
pres.addSection({ title: "Limpieza" });
s = newSlide("CONTENIDO", "Limpieza", "Limpieza 1: valores faltantes");
table(s, "tabla-faltantes", [
  [hdr("Variable"), hdr("% vacío"), hdr("Naturaleza"), hdr("Tratamiento")],
  [cell("CHOQUE"), cell("14,4 %"), cell("Estructural"), cell("«No aplica»")],
  [cell("OBJETO_FIJO"), cell("96,6 %"), cell("Estructural"), cell("Descartada")],
  [cell("MODALIDAD"), cell("61,3 %"), cell("Estructural"), cell("Descartada")],
  [cell("EDAD (actor)"), cell("1,9 %"), cell("MAR: según condición"), cell("Mediana Train")],
  [cell("EDAD (siniestro)", { bold: true }), cell("0,35 %", { bold: true }), cell("Informativa", { bold: true, color: C.accent2 }), cell("Mediana + indicador", { bold: true })],
], { x: 0.6, y: 1.4, w: 6.6, colW: [1.8, 1.0, 2.0, 1.8], rowH: 0.55 });
s.addImage({ path: FIG("f3_faltante_informativo.png"), x: 7.5, y: 1.35, w: 5.2, h: 2.73, altText: "Gravedad según si el siniestro tiene edad registrada" });
cap(s, "fuente-faltante", "Gravedad según edad registrada (Train)", 7.5, 4.1, 5.2);
card(s, "decision-faltantes-fondo", 0.6, 4.7, 7.6, 2.1);
txt(s, "decision-faltantes", [
  { text: "Imputar, no eliminar. ", options: { bold: true } },
  { text: "Faltan 0,35 % de siniestros, pero esa ausencia es informativa: 6,3 % son fatales (vs 1,5 %) y en 64 % hay un vehículo en fuga. Se imputa con la mediana de Train (robusta al sesgo) y se conserva el indicador edad_imputada." }],
  { x: 0.85, y: 4.8, w: 7.1, h: 1.9, fontSize: 16, valign: "middle" });
code(s, "codigo-mediana", ["# parámetro aprendido SOLO en Train", "P$mediana_edad <-", "  sapply(train[VARS_NUM_EDAD],", "         median, na.rm = TRUE)"], 8.5, 4.7, 4.2, 2.1);
notes(s, "[1,25 min] Diagnóstico: la mayoría de los vacíos son estructurales (CHOQUE solo se diligencia si la clase es choque; OBJETO_FIJO y MODALIDAD igual), así que no se imputan: se recodifican o se descartan. El único faltante real es la edad: 1,9 % por actor, 0,35 % por siniestro. Una prueba chi-cuadrado muestra que depende de la condición del actor (MAR). Importante: la ausencia es informativa. Los siniestros sin edad tienen 6,3 % de fatales contra 1,5 %, y en 64 % hay un vehículo que huyó. Por eso no los elimino: imputo con la mediana de Train y dejo el indicador edad_imputada. Respuesta a '¿por qué mediana y no KNN?': faltante menor a 1 %, distribución sesgada, y KNN añade complejidad sin beneficio. Sesgo: la mediana se calcula solo en Train y el indicador evita borrar la señal.");

// ====================== 7. LIMPIEZA: INCONSISTENCIAS ======================
s = newSlide("CONTENIDO", "Limpieza", "Limpieza 2: inconsistencias y duplicados");
s.addImage({ path: FIG("f2_edad_antes_despues.png"), x: 0.6, y: 1.4, w: 6.6, h: 3.135, altText: "Cola de la distribución de edad antes y después de anular el código 118" });
cap(s, "fuente-edad", "Edades ≥ 85 años: el pico en 118 desaparece (código centinela)", 0.6, 4.55, 6.6);
table(s, "tabla-correcciones", [
  [hdr("Problema detectado"), hdr("Registros"), hdr("Acción")],
  [cell("Edad 118 (centinela)"), cell("282"), cell("→ NA")],
  [cell("Edad ≥ 110 años"), cell("303"), cell("→ NA")],
  [cell("Conductor/motociclista < 10 años"), cell("297"), cell("→ NA")],
  [cell("Gravedad ≠ estado de víctimas"), cell("175"), cell("Se reconcilia")],
  [cell("Siniestros sin actores ni vehículos"), cell("148"), cell("Se eliminan")],
  [cell("Duplicados semánticos"), cell("58"), cell("Se eliminan")],
  [cell("CHOQUE = 5 (no documentado)"), cell("290"), cell("«Otro»")],
], { x: 7.5, y: 1.4, w: 5.2, colW: [2.9, 1.0, 1.3], rowH: 0.52 });
card(s, "decision-gravedad-fondo", 0.6, 5.0, 6.6, 1.8);
txt(s, "decision-gravedad", [
  { text: "El objetivo también se audita. ", options: { bold: true } },
  { text: "175 siniestros (0,09 %) contradecían a sus víctimas; prevalece la evidencia a nivel de víctima y se guarda gravedad_original para trazabilidad." }],
  { x: 0.85, y: 5.1, w: 6.1, h: 1.6, fontSize: 16, valign: "middle" });
card(s, "nota-reglas-fondo", 7.5, 5.7, 5.2, 1.1, THEME.colors.dk1);
txt(s, "nota-reglas", "Reglas deterministas de dominio: no aprenden nada de los datos, por eso van antes de la partición.", { x: 7.7, y: 5.75, w: 4.8, h: 1.0, fontSize: 14, color: C.background1, valign: "middle" });
notes(s, "[1,25 min] Errores y su corrección. La edad 118 aparece 282 veces y las vecinas casi no aparecen: es un valor por defecto, no una persona. Se anula junto con todo ≥ 110 y con conductores o motociclistas menores de 10 años (297), físicamente imposible. El gráfico muestra la cola antes y después. Además: 175 siniestros con gravedad contradictoria con las víctimas, reconciliados; 148 sin actores ni vehículos, eliminados (ninguno fatal); 58 duplicados semánticos; y un código de CHOQUE que no está en el diccionario, que recodifico como 'Otro' en vez de inventar un significado. No hubo duplicados exactos ni registros huérfanos. Estas son reglas de dominio que no aprenden de los datos, por eso van antes de la partición y no hay fuga.");

// ====================== 8. LIMPIEZA: OUTLIERS ======================
s = newSlide("CONTENIDO", "Limpieza", "Limpieza 3: valores atípicos");
s.addImage({ path: FIG("f7_reglas_iqr.png"), x: 0.6, y: 1.4, w: 4.1, h: 2.996, altText: "Porcentaje de siniestros marcados atípicos por regla" });
cap(s, "fuente-reglas", "n_vehiculos: % marcado por cada regla", 0.6, 4.4, 4.1);
s.addImage({ path: FIG("f4_outliers_box.png"), x: 5.0, y: 1.4, w: 7.7, h: 3.337, altText: "Boxplots antes y después de winsorizar" });
cap(s, "fuente-box", "Antes / después de acotar al percentil 99,5 de Train", 5.0, 4.75, 7.7);
card(s, "decision-outliers-fondo", 0.6, 5.2, 7.6, 1.6);
txt(s, "decision-outliers", [
  { text: "Criterio, no regla ciega. ", options: { bold: true } },
  { text: "El IQR marca 22,5 % de siniestros legítimos (dos vehículos es lo normal). Conteos: se acotan al P99,5 de Train (tope de 4 vehículos, 0,1 % de filas). Edades altas plausibles (≤ 107): se conservan." }],
  { x: 0.85, y: 5.28, w: 7.1, h: 1.45, fontSize: 15, valign: "middle" });
code(s, "codigo-winsor", ["# tope aprendido en Train", "winsorizar(x, 0, P$tope_sup[[v]])"], 8.5, 5.2, 4.2, 1.6);
notes(s, "[1 min] Detección con tres reglas explícitas: IQR 1,5, Z-score mayor a 3 y percentil 99,5. El IQR no sirve en conteos: como casi todos los siniestros tienen dos vehículos, el IQR es cero y marca 22,5 % de eventos perfectamente legítimos. Decisión diferenciada: en los conteos acoto (winsorizo) al percentil 99,5 calculado en Train, así se conserva el siniestro pero se limita la influencia de colisiones masivas de hasta 23 vehículos; en las edades conservo los valores altos plausibles porque son adultos mayores, justo el perfil vulnerable. Evidencia: los boxplots antes y después. ¿Cómo sé que no distorsioné? Afecta solo 0,1 % de las filas.");

// ====================== 9. TRANSFORMACION: DERIVADAS ======================
pres.addSection({ title: "Transformación" });
s = newSlide("CONTENIDO", "Transformación", "Transformación 1: variables derivadas y codificación");
const grupos = [["Temporales", "franja_horaria (5), es_festivo, dia_no_habil, hora_sin/cos"],
                ["Involucrados", "hay_peaton, ratio_vulnerables, hay_menor, edad_min/max"],
                ["Vehículos", "indice_heterogeneidad (Gini-Simpson), hay_pesado, mezcla_vulnerable_pesado"]];
grupos.forEach(([g, d], i) => {
  const y = 1.4 + i * 1.6;
  card(s, "grupo-fondo-" + (i + 1), 0.6, y, 5.6, 1.45);
  txt(s, "grupo-titulo-" + (i + 1), g, { x: 0.8, y: y + 0.1, w: 5.2, h: 0.4, fontSize: 18, bold: true, color: C.accent2 });
  txt(s, "grupo-detalle-" + (i + 1), d, { x: 0.8, y: y + 0.55, w: 5.2, h: 0.85, fontSize: 15 });
});
txt(s, "antes-etiqueta", "Antes", { x: 6.6, y: 1.35, w: 3, h: 0.35, fontSize: 15, bold: true, color: C.accent6 });
table(s, "tabla-antes", [
  [hdr("franja_horaria"), hdr("n_vehiculos"), hdr("edad_media")],
  [cell("Madrugada (00-05h)"), cell("1"), cell("30,5")],
  [cell("Noche (20-23h)"), cell("2"), cell("52,0")],
  [cell("Pico PM (16-19h)"), cell("3"), cell("27,0")],
], { x: 6.6, y: 1.75, w: 6.1, colW: [2.9, 1.6, 1.6], rowH: 0.42 });
txt(s, "despues-etiqueta", "Después (one-hot + Z-score)", { x: 6.6, y: 3.7, w: 5, h: 0.35, fontSize: 15, bold: true, color: C.accent2 });
table(s, "tabla-despues", [
  [hdr("franja_Noche"), hdr("n_vehiculos_z"), hdr("edad_media_z")],
  [cell("0"), cell("−1,86"), cell("−0,76")],
  [cell("1"), cell("0,22"), cell("1,43")],
  [cell("0"), cell("2,29"), cell("−1,12")],
], { x: 6.6, y: 4.1, w: 6.1, colW: [2.1, 2.0, 2.0], rowH: 0.42 });
txt(s, "nota-onehot", [
  { text: "One-hot (k−1): ", options: { bold: true } },
  { text: "referencia = moda de Train; niveles < 0,5 % → «Otros». 41 columnas dummy, 77 en total." }],
  { x: 6.6, y: 6.0, w: 6.1, h: 0.85, fontSize: 14 });
notes(s, "[1,25 min] Variables derivadas, agrupadas en tres bloques. Temporales: franja horaria de cinco tramos, festivos de Colombia calculados con la ley Emiliani y Semana Santa, hora cíclica con seno y coseno para que las 23h y las 0h queden cerca. Involucrados: presencia de peatón, proporción de vulnerables, edades mínima y máxima. Vehículos: índice de heterogeneidad de Gini-Simpson, vehículo pesado y la interacción vulnerable con pesado. Aportan al modelo exactamente lo que pregunta H1, H2 y H3. Codificación: one-hot con k menos uno columnas porque los modelos lineales y el clustering no manejan factores; la categoría de referencia es la moda de Train y los niveles raros bajo 0,5 % se agrupan en Otros. Otra opción, label encoding, impondría un orden falso entre localidades. Aquí el antes y después en tres siniestros reales.");

// ====================== 10. TRANSFORMACION: NORMALIZACION ======================
s = newSlide("CONTENIDO", "Transformación", "Transformación 2: normalización");
s.addImage({ path: FIG("f5_normalizacion.png"), x: 0.6, y: 1.4, w: 7.4, h: 4.255, altText: "Histogramas antes y después de estandarizar" });
cap(s, "fuente-norm", "Antes (arriba) y después (abajo) de acotar y estandarizar con parámetros de Train", 0.6, 5.7, 7.4);
txt(s, "razones-z", [
  { text: "Z-score: regresión regularizada, k-medias y PCA son sensibles a la escala", options: { bullet: true, breakLine: true } },
  { text: "Media y desvío calculados solo en Train", options: { bullet: true, breakLine: true } },
  { text: "Test queda con media ≈ 0 pero no exacta: prueba de que no participó", options: { bullet: true, breakLine: true } },
  { text: "Cambia la escala, no la forma de la distribución", options: { bullet: true } },
], { x: 8.4, y: 1.45, w: 4.3, h: 3.2, fontSize: 16, paraSpaceAfter: 8 });
code(s, "codigo-z", ["# parámetros de Train aplicados", "# a Train, Test y despliegue", 'Z[[paste0(v, "_z")]] <-', "  (df_w[[v]] - P$media[[v]]) /", "  P$desvio[[v]]"], 8.4, 4.8, 4.3, 1.95);
notes(s, "[1,1 min] Normalización con Z-score: resto la media de Train y divido por el desvío de Train. Elegí Z-score porque los algoritmos que usaré después, regresión regularizada, k-medias y PCA, son sensibles a la escala; los árboles no lo necesitan pero no se perjudican. Alternativa, min-max: es muy sensible a los valores extremos, y por eso primero acoto los conteos. El orden es imputar, acotar y luego estandarizar. Evidencia: histogramas antes y después; la forma no cambia, solo la escala. En Test la media da cerca de cero pero no exacta: eso demuestra que no usé Test para calcular nada.");

// ====================== 11. TRANSFORMACION: PCA + ANTIFUGA ======================
s = newSlide("CONTENIDO", "Transformación", "Transformación 3: PCA y control de fuga");
s.addImage({ path: FIG("f6_pca.png"), x: 0.6, y: 1.4, w: 6.0, h: 3.429, altText: "Varianza explicada por componente principal" });
cap(s, "fuente-pca", "7 componentes retienen 98,3 % de la varianza (criterio ≥ 95 %)", 0.6, 4.85, 6.0);
card(s, "pca-nota-fondo", 0.6, 5.35, 6.0, 1.45);
txt(s, "pca-nota", "PCA ajustado solo con Train sobre las 12 variables numéricas; se guarda como conjunto alterno para el agrupamiento, no como reemplazo.", { x: 0.8, y: 5.4, w: 5.6, h: 1.35, fontSize: 15, valign: "middle" });
const pasos = [["1", "Partición 70/30 estratificada (semilla 2025)"], ["2", "ajustar_transformacion(train)"], ["3", "aplicar_transformacion(train y test)"]];
pasos.forEach(([n, t], i) => {
  const y = 1.4 + i * 0.85;
  s.addShape(pres.shapes.OVAL, { x: 7.0, y: y + 0.05, w: 0.55, h: 0.55, fill: { color: THEME.colors.dk1 }, line: { color: THEME.colors.dk1, width: 0 }, objectName: "paso-circulo-" + n });
  txt(s, "paso-numero-" + n, n, { x: 7.0, y: y + 0.05, w: 0.55, h: 0.55, fontSize: 16, bold: true, color: C.background1, align: "center", valign: "middle" });
  txt(s, "paso-texto-" + n, t, { x: 7.75, y, w: 4.95, h: 0.65, fontSize: 16, valign: "middle" });
});
card(s, "pruebas-fondo", 7.0, 4.05, 5.7, 1.2, C.background2);
txt(s, "pruebas", [{ text: "4 pruebas automáticas: APROBADAS", options: { bold: true, color: C.accent4, breakLine: true } },
  { text: "idempotencia · mismas columnas · sin solape Train/Test · parámetros sin Test", options: { fontSize: 14 } }], { x: 7.2, y: 4.1, w: 5.3, h: 1.1, fontSize: 16, valign: "middle" });
code(s, "codigo-fuga", ["P  <- ajustar_transformacion(train)", "tr <- aplicar_transformacion(train, P)", "te <- aplicar_transformacion(test,  P)"], 7.0, 5.4, 5.7, 1.4);
notes(s, "[1,15 min] PCA: lo ajusto con Train sobre las 12 variables numéricas estandarizadas. Criterio: retener al menos 95 % de la varianza, lo que se logra con 7 componentes (98,3 %). Es un conjunto alterno que usaré para el agrupamiento. Y la regla contra la fuga de datos, que es lo más importante metodológicamente: primero parto 70/30 estratificado con semilla; luego ajusto todos los parámetros solo con Train (medianas, topes, medias, desvíos, niveles, rotación PCA) y los guardo en un .rds; después aplico la misma función, de forma idempotente, a Train, Test y al futuro despliegue. El informe ejecuta cuatro pruebas automáticas en cada compilación: reaplicar reproduce exactamente el resultado, mismas columnas, sin solape entre Train y Test, y parámetros sin Test.");

// ====================== 12. CIERRE ======================
pres.addSection({ title: "Cierre" });
s = newSlide("OSCURO", "Cierre", "Cierre y puente hacia la minería de datos");
card(s, "listo-fondo", 0.6, 1.9, 5.9, 4.6, THEME.colors.dk2);
txt(s, "listo-titulo", "Qué quedó listo", { x: 0.85, y: 2.05, w: 5.4, h: 0.5, fontSize: 22, bold: true, color: C.accent1 });
txt(s, "listo-lista", [
  { text: "195.946 siniestros limpios, 50 columnas", options: { bullet: true, breakLine: true } },
  { text: "Train 137.162 · Test 58.784 (estratificado)", options: { bullet: true, breakLine: true } },
  { text: "77 columnas listas para modelar", options: { bullet: true, breakLine: true } },
  { text: "Parámetros guardados en modelos/*.rds", options: { bullet: true, breakLine: true } },
  { text: "Flujo reproducible sin fuga de datos", options: { bullet: true } },
], { x: 0.85, y: 2.75, w: 5.4, h: 3.6, fontSize: 20, color: C.background1, paraSpaceAfter: 14 });
card(s, "siguiente-fondo", 6.8, 1.9, 5.9, 4.6, THEME.colors.dk2);
txt(s, "siguiente-titulo", "Qué sigue", { x: 7.05, y: 2.05, w: 5.4, h: 0.5, fontSize: 22, bold: true, color: C.accent1 });
txt(s, "siguiente-lista", [
  { text: "Clasificación multiclase: regresión logística regularizada, bosque aleatorio, gradient boosting", options: { bullet: true, breakLine: true } },
  { text: "Métricas para desbalance (43:1): recall por clase, F1 macro, AUC", options: { bullet: true, breakLine: true } },
  { text: "Agrupamiento k-medias sobre PCA para los perfiles de H3", options: { bullet: true, breakLine: true } },
  { text: "Despliegue en Plumber o Shiny", options: { bullet: true } },
], { x: 7.05, y: 2.75, w: 5.4, h: 3.6, fontSize: 20, color: C.background1, paraSpaceAfter: 14 });
notes(s, "[1 min] Qué dejó consolidado el preprocesamiento: 195.946 siniestros limpios, partición estratificada en 137.162 y 58.784, 77 columnas listas, parámetros guardados y un flujo reproducible sin fuga. La técnica que sigue es clasificación multiclase porque la pregunta es predecir la gravedad en tres clases: comparo regresión logística regularizada, bosque aleatorio y gradient boosting, evaluados con recall por clase, F1 macro y AUC, nunca solo accuracy, porque la clase fatal es 43 veces menor. El desbalance se tratará solo dentro de Train. Y agrupamiento k-medias sobre el espacio PCA para responder H3. Después, un despliegue en Plumber o Shiny que reutiliza los mismos parámetros. Quedo atento a las preguntas.");

pres.writeFile({ fileName: path.join(__dirname, "sustentacion.pptx") }).then(async (f) => {
  const { applyTheme } = require(process.env.SKILL_DIR + "/scripts/apply_theme.js");
  await applyTheme(f, THEME);
  console.log("OK", f);
});
