// Genera sustentacion_final/sustentacion_final.pptx (sustentación final: 15 min + 5 de preguntas).
// Lee las cifras de sustentacion_final/cifras.json (generado por scripts/07_cifras_sustentacion_final.R).
// Uso (desde la raíz): SKILL_DIR=<pptx skill> NODE_PATH=<node_modules con pptxgenjs> node sustentacion_final/build_deck_final.js
const pptxgen = require("pptxgenjs");
const path = require("path");
const fs = require("fs");
const D = JSON.parse(fs.readFileSync(path.join(__dirname, "cifras.json"), "utf8"));
const FIG = (f) => path.join(__dirname, "..", "resultados", "figuras", f);
const CAP = (f) => path.join(__dirname, "plan_b", f);

// ---- formato en español ----
const nf = (x, d = 0) => Number(x).toLocaleString("es-CO", { minimumFractionDigits: d, maximumFractionDigits: d });
const pc = (x, d = 0) => nf(100 * x, d) + " %";
const mil = (x, d = 0) => nf(x, d) + " ‰";

const THEME = {
  name: "Siniestros Bogota", headFontFace: "Cambria", bodyFontFace: "Calibri",
  colors: { dk1: "14213D", lt1: "FFFFFF", dk2: "2B3A67", lt2: "F2F4F8", accent1: "FCA311", accent2: "C0392B", accent3: "8D99AE", accent4: "2A9D8F", accent5: "BFD0EA", accent6: "6C757D", hlink: "3A86FF", folHlink: "8D99AE" },
};
const pres = new pptxgen();
pres.layout = "LAYOUT_WIDE";
pres.theme = { headFontFace: THEME.headFontFace, bodyFontFace: THEME.bodyFontFace };
pres.title = "Sustentación final — Gravedad de los siniestros viales en Bogotá D.C.";
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
  objects: [{ placeholder: { options: { name: "title", type: "title", x: 0.6, y: 0.6, w: 12.1, h: 1.2, fontSize: 38, bold: true, color: C.background1, valign: "top", margin: 0 }, text: "" } }],
  slideNumber: { x: 12.2, y: 7.0, w: 0.6, h: 0.3, fontSize: 10, color: C.accent3, align: "right" },
});

// ---- helpers ----
const card = (s, name, x, y, w, h, fill = C.background2) => s.addShape(pres.shapes.RECTANGLE, { x, y, w, h, fill: { color: fill }, line: { color: fill, width: 0 }, objectName: name });
const txt = (s, name, t, o) => s.addText(t, Object.assign({ isTextBox: true, objectName: name, margin: 0, valign: "top", fontSize: 16, color: C.text1 }, o));
const code = (s, name, lines, x, y, w, h) => { card(s, name + "-fondo", x, y, w, h, C.text1); txt(s, name, lines.join("\n"), { x: x + 0.15, y: y + 0.1, w: w - 0.3, h: h - 0.2, fontFace: "Courier New", fontSize: 12, color: C.accent5, valign: "middle" }); };
const cap = (s, name, t, x, y, w) => txt(s, name, t, { x, y, w, h: 0.3, fontSize: 12, color: C.accent6, italic: true });
const hdr = (t) => ({ text: t, options: { bold: true, color: C.background1, fill: { color: THEME.colors.dk1 }, fontSize: 13 } });
const cell = (t, o = {}) => ({ text: String(t), options: Object.assign({ fontSize: 13, color: C.text1 }, o) });
const table = (s, name, rows, o) => s.addTable(rows, Object.assign({ objectName: name, border: { type: "solid", pt: 0.5, color: "D5DAE5" }, valign: "middle", margin: [0.04, 0.08, 0.04, 0.08] }, o));
const newSlide = (master, section, title) => { const s = pres.addSlide({ masterName: master, sectionTitle: section }); s.addText(title, { placeholder: "title" }); return s; };
const camp = D.modelos.find((m) => m.id === D.campeon);
const nivAlto = D.niveles.find((n) => n.nivel === "Alto"), nivBajo = D.niveles.find((n) => n.nivel === "Bajo");
const orp = D.or.peaton, orm = D.or.moto, orn = D.or.noche, orf = D.or.nohabil;
const orTxt = (o) => `OR ${nf(o.or, 1)} (IC 95 %: ${nf(o.li, 1)}–${nf(o.ls, 1)})`;

// =========================== 1. APERTURA Y PUENTE ===========================
pres.addSection({ title: "Apertura" });
let s = newSlide("OSCURO", "Apertura", "Del dato limpio a una herramienta de decisión");
txt(s, "subtitulo", "Minería de datos, interpretación y despliegue · Juan Esteban Castillo Baquero · ID 852500", { x: 0.6, y: 1.75, w: 12.1, h: 0.5, fontSize: 18, color: C.accent5 });
[[nf(D.n_train + D.n_test), "siniestros viales preparados\n(Train " + nf(D.n_train) + " · Test " + nf(D.n_test) + ")", C.accent1], [nf(D.razon, 0) + " a 1", "desbalance: solo " + pc(D.prevalencia_fatal, 1) + "\nterminan con víctimas fatales", C.accent1],
 ["77", "variables listas para modelar,\nsin fuga de datos", C.accent1]].forEach(([n, l, col], i) => {
  const x = 0.6 + i * 4.1; card(s, "dato-fondo-" + (i + 1), x, 2.8, 3.9, 2.4, THEME.colors.dk2);
  txt(s, "dato-cifra-" + (i + 1), n, { x: x + 0.25, y: 3.0, w: 3.4, h: 1.0, fontSize: 46, bold: true, color: col, valign: "middle" });
  txt(s, "dato-etiqueta-" + (i + 1), l, { x: x + 0.25, y: 4.1, w: 3.4, h: 1.0, fontSize: 18, color: C.background1 });
});
card(s, "pregunta-fondo", 0.6, 5.55, 12.1, 1.2, THEME.colors.dk2);
txt(s, "pregunta", [{ text: "Pregunta de investigación: ", options: { bold: true, color: C.accent1 } }, { text: "¿qué combinación de condiciones se asocia con los desenlaces más graves, y cómo usar ese conocimiento para focalizar intervenciones?" }],
  { x: 0.85, y: 5.65, w: 11.6, h: 1.0, fontSize: 18, color: C.background1, valign: "middle" });
s.addNotes("[1 min] Puente: en la entrega anterior dejé 195.946 siniestros limpios y transformados, con partición 70/30 estratificada, 77 columnas y parámetros guardados sin fuga de datos. Hoy: modelar, interpretar y mostrar el modelo funcionando. La pregunta de investigación sigue siendo qué combinación de condiciones se asocia con los desenlaces más graves; la dificultad es que solo 1,5 % son fatales (43 a 1).");

// =========================== 2-4. MINERIA DE DATOS ===========================
pres.addSection({ title: "Minería de datos" });
s = newSlide("CONTENIDO", "Minería de datos", "Técnicas elegidas y por qué");
table(s, "tabla-tecnicas", [
  [hdr("Técnica"), hdr("Por qué"), hdr("Riesgo que se controla")],
  [cell("Regresión logística regularizada", { bold: true, fontSize: 14 }), cell("Línea base interpretable; probabilidades calibradas; coeficientes para H1 y H2", { fontSize: 14 }), cell("No capta interacciones (peatón × noche)", { fontSize: 14 })],
  [cell("Bosque aleatorio", { bold: true, fontSize: 14 }), cell("Interacciones y no linealidades sin supuestos; robusto a la escala", { fontSize: 14 }), cell("Probabilidades menos calibradas → tamaño mínimo de nodo", { fontSize: 14 })],
  [cell("Gradient boosting (XGBoost)", { bold: true, fontSize: 14 }), cell("Suele ser el mejor en datos tabulares con predictores mixtos", { fontSize: 14 }), cell("Sobreajuste → validación cruzada + early stopping", { fontSize: 14 })],
], { x: 0.6, y: 1.45, w: 12.1, colW: [3.2, 5.2, 3.7], rowH: [0.45, 0.85, 0.85, 0.85] });
card(s, "alternativas-fondo", 0.6, 4.7, 7.4, 2.1);
txt(s, "alternativas", [{ text: "Alternativas descartadas. ", options: { bold: true } }, { text: "Árbol único (alta varianza); k vecinos y SVM (costosos con 137 mil filas, sensibles a las dummies); redes neuronales (sin ventaja esperada en tabulares y poco interpretables). La regresión logística ordinal se usa para contrastar hipótesis, no para predecir." }],
  { x: 0.85, y: 4.8, w: 6.9, h: 1.9, fontSize: 16, valign: "middle" });
card(s, "tipo-fondo", 8.3, 4.7, 4.4, 2.1, THEME.colors.dk1);
txt(s, "tipo-problema", [{ text: "Tipo de problema", options: { bold: true, color: C.accent1, breakLine: true } }, { text: "Clasificación multiclase ordinal, con desbalance de " + nf(D.razon, 0) + " a 1 y 75 predictores mixtos", options: { color: C.background1 } }],
  { x: 8.5, y: 4.8, w: 4.0, h: 1.9, fontSize: 16, valign: "middle" });
s.addNotes("[1 min] El problema es clasificación multiclase ordinal con desbalance fuerte. Elegí tres técnicas complementarias: la regresión logística regularizada como línea base interpretable, el bosque aleatorio para captar interacciones sin supuestos y XGBoost, que suele ser el mejor en datos tabulares. Descarté el árbol único por su varianza, k vecinos y SVM por costo y sensibilidad a las dummies, y las redes neuronales porque no aportan en tabulares de este tamaño y son difíciles de explicar a quien decide.");

s = newSlide("CONTENIDO", "Minería de datos", "División de datos, validación y métricas");
const pasos = [["1", "Partición 70/30 estratificada", "semilla 2025 · Test intocado hasta el final"], ["2", "Validación cruzada de 5 pliegues solo en Train", "elegir hiperparámetros y la regla de decisión"], ["3", "Evaluación única en Test", "datos que el modelo nunca vio"]];
pasos.forEach(([n, t, d], i) => {
  const y = 1.45 + i * 1.15;
  s.addShape(pres.shapes.OVAL, { x: 0.6, y: y + 0.1, w: 0.6, h: 0.6, fill: { color: THEME.colors.dk1 }, line: { color: THEME.colors.dk1, width: 0 }, objectName: "paso-circulo-" + n });
  txt(s, "paso-numero-" + n, n, { x: 0.6, y: y + 0.1, w: 0.6, h: 0.6, fontSize: 18, bold: true, color: C.background1, align: "center", valign: "middle" });
  txt(s, "paso-titulo-" + n, t, { x: 1.45, y, w: 5.0, h: 0.45, fontSize: 17, bold: true });
  txt(s, "paso-detalle-" + n, d, { x: 1.45, y: y + 0.45, w: 5.0, h: 0.5, fontSize: 14, color: C.accent6 });
});
card(s, "desbalance-fondo", 0.6, 4.95, 5.9, 1.85);
txt(s, "desbalance", [{ text: "Desbalance sin remuestrear: ", options: { bold: true } }, { text: "la clase predicha maximiza p × m; los multiplicadores m se ajustan solo con predicciones fuera de muestra de Train. Conserva probabilidades calibradas." }], { x: 0.85, y: 5.05, w: 5.4, h: 1.65, fontSize: 15, valign: "middle" });
table(s, "tabla-metricas", [
  [hdr("Métrica"), hdr("Qué dice")],
  [cell("Recall fatal", { bold: true, fontSize: 14 }), cell("De 100 fatales reales, cuántos detecta (error más costoso)", { fontSize: 14 })],
  [cell("Precisión fatal", { bold: true, fontSize: 14 }), cell("De 100 alertas de fatal, cuántas lo eran", { fontSize: 14 })],
  [cell("F1 macro", { bold: true, fontSize: 14 }), cell("Promedio de F1 de las 3 clases: no deja ignorar la minoritaria", { fontSize: 14 })],
  [cell("AUC-PR fatal", { bold: true, fontSize: 14 }), cell("Qué tan bien ordena por riesgo; el azar vale " + pc(D.prevalencia_fatal, 1), { fontSize: 14 })],
], { x: 6.9, y: 1.45, w: 5.8, colW: [1.7, 4.1], rowH: [0.45, 0.8, 0.8, 0.8, 0.8] });
card(s, "base-fondo", 6.9, 5.45, 5.8, 1.35, THEME.colors.dk1);
txt(s, "base", [{ text: "¿Por qué no accuracy? ", options: { bold: true, color: C.accent1 } }, { text: "Decir siempre «Solo daños» da " + pc(D.accuracy_base, 1) + " de accuracy y detecta 0 % de los fatales.", options: { color: C.background1 } }], { x: 7.1, y: 5.5, w: 5.4, h: 1.25, fontSize: 15, valign: "middle" });
s.addNotes("[1 min] División: 70/30 estratificado con semilla; el Test no se usa para elegir nada. Dentro de Train hago validación cruzada de 5 pliegues, los mismos para los tres modelos, para elegir hiperparámetros y la regla de decisión. El desbalance no lo trato remuestreando sino en la decisión, con multiplicadores ajustados solo con predicciones fuera de muestra; así conservo probabilidades calibradas, que luego muestro al usuario. Métricas: recall fatal es la que más importa porque no detectar un fatal es el error más costoso; precisión fatal mide las falsas alarmas; F1 macro y AUC-PR. No uso solo accuracy: decir siempre solo daños da 65 % y detecta cero fatales. Limitación honesta: dentro de la validación cruzada los parámetros de transformación se calcularon con todo Train, un optimismo leve; el Test no está afectado.");

s = newSlide("CONTENIDO", "Minería de datos", "Resultados: los tres modelos en Train y en Test");
s.addImage({ path: FIG("comparacion_modelos.png"), x: 0.6, y: 1.4, w: 7.4, h: 3.454, altText: "Comparación de F1 macro y recall fatal por modelo, en validación cruzada y en Test" });
cap(s, "fuente-comp", "Validación cruzada (Train) frente a prueba (Test)", 0.6, 4.85, 7.4);
s.addImage({ path: FIG("matriz_confusion.png"), x: 8.3, y: 1.4, w: 4.4, h: 2.89, altText: "Matriz de confusión del modelo campeón" });
cap(s, "fuente-cm", "Matriz de confusión del campeón (Test)", 8.3, 4.3, 4.4);
card(s, "campeon-fondo", 0.6, 5.3, 12.1, 1.5, THEME.colors.dk1);
txt(s, "campeon", [{ text: "Campeón: " + D.campeon_nombre + ". ", options: { bold: true, color: C.accent1 } },
  { text: "Test: F1 macro " + nf(D.test.f1, 2) + " · recall fatal " + pc(D.test.recall[2], 0) + " · precisión fatal " + pc(D.test.precision[2], 0) + " · AUC fatal " + nf(D.test.auc.Con_muertos || Object.values(D.test.auc)[2], 3) + " · AUC-PR " + nf(D.test.pr_auc, 2) + " (" + nf(D.test.pr_auc / D.prevalencia_fatal, 0) + " veces el azar). Los de árboles superan a la logística: hay interacciones.", options: { color: C.background1 } }],
  { x: 0.85, y: 5.4, w: 11.6, h: 1.3, fontSize: 16, valign: "middle" });
s.addNotes("[1 min] Los tres modelos rinden parecido; los de árboles superan a la regresión logística, señal de interacciones. El campeón por validación cruzada fue XGBoost. En Test: F1 macro 0,66; distingue bien solo daños y heridos, y la clase fatal es la difícil: recall 27 % con precisión 21 %, pero con un AUC de precisión-recall unas catorce veces el azar. El Test confirma la validación cruzada: no hay sobreajuste respecto a datos nuevos.");

// =========================== 5-7. INTERPRETACION ===========================
pres.addSection({ title: "Interpretación y evaluación" });
s = newSlide("CONTENIDO", "Interpretación y evaluación", "Análisis crítico: errores, sobreajuste y sesgos");
const so = D.sobreajuste[0];
txt(s, "critico", [
  { text: "Sin sobreajuste a datos nuevos: F1 macro " + nf(so.f1_cv, 3) + " en validación cruzada y " + nf(so.f1_test, 3) + " en Test (en Train: " + nf(so.f1_train, 3) + ")", options: { bullet: true, breakLine: true } },
  { text: "La clase fatal es difícil: faltan velocidad, estado de la vía, clima y casco", options: { bullet: true, breakLine: true } },
  { text: "Sesgo de registro: el IPAT subregistra siniestros de solo daños", options: { bullet: true, breakLine: true } },
  { text: "Mejor detección con peatón o motociclista que sin actor vulnerable", options: { bullet: true, breakLine: true } },
  { text: "Probabilidades calibradas: sirven para ordenar casos", options: { bullet: true } },
], { x: 0.6, y: 1.5, w: 6.0, h: 4.4, fontSize: 17, paraSpaceAfter: 10 });
s.addImage({ path: FIG("niveles_riesgo.png"), x: 6.9, y: 1.4, w: 5.8, h: 3.748, altText: "Fatales por mil siniestros según el nivel de riesgo asignado por el modelo" });
cap(s, "fuente-niveles", "Niveles de riesgo definidos con Train, evaluados en Test", 6.9, 5.15, 5.8);
card(s, "nivel-fondo", 0.6, 5.95, 12.1, 0.85, THEME.colors.dk1);
txt(s, "nivel", "El nivel «Alto» agrupa " + pc(nivAlto.pct_siniestros, 0) + " de los siniestros y captura " + pc(nivAlto.pct_fatales, 0) + " de los fatales (" + nf(nivAlto.fatales_x_mil, 0) + " por mil frente a " + nf(nivBajo.fatales_x_mil, 1) + " en «Bajo»).", { x: 0.85, y: 6.0, w: 11.6, h: 0.75, fontSize: 16, color: C.background1, valign: "middle" });
s.addNotes("[1 min] Análisis crítico. Sobreajuste: el F1 macro es casi igual en validación cruzada y en Test, así que no hay sobreajuste respecto a datos nuevos; sí hay una brecha moderada con Train, esperable en árboles. Errores: la clase fatal es difícil porque no tengo velocidad, estado de la vía, clima ni uso del casco. Sesgos: el IPAT subregistra los siniestros de solo daños; el modelo detecta mejor los fatales con peatón o motociclista; y hay que leer con cautela las diferencias por localidad por los pocos fatales. Las probabilidades están calibradas, por eso sirven para ordenar: el nivel alto agrupa 5 % de los casos y captura una parte mucho mayor de los fatales.");

s = newSlide("CONTENIDO", "Interpretación y evaluación", "Qué pesa más y qué dicen las hipótesis");
s.addImage({ path: FIG("importancia.png"), x: 0.6, y: 1.4, w: 6.0, h: 3.84, altText: "Importancia por permutación agrupada de las variables" });
cap(s, "fuente-imp", "Importancia por permutación agrupada (Test)", 0.6, 5.3, 6.0);
const hy = [["H1", "Se confirma", "Peatón: " + orTxt(orp) + ". Motociclista: " + orTxt(orm) + ". Es el bloque que más aporta, por encima de clase y localidad."],
            ["H2", "Efecto pequeño", "Noche: " + orTxt(orn) + ". Fin de semana o festivo: " + orTxt(orf) + "."],
            ["H3", "En parte", D.k + " perfiles de " + nf(Math.min(...D.clusters.map((c) => c.fatales_x_mil)), 1) + " a " + nf(Math.max(...D.clusters.map((c) => c.fatales_x_mil)), 0) + " fatales por mil; los separa el actor, no la localidad ni la hora."]];
hy.forEach(([h, v, t], i) => {
  const y = 1.4 + i * 1.75;
  card(s, "hip-fondo-" + h, 6.9, y, 5.8, 1.6);
  txt(s, "hip-id-" + h, h, { x: 7.1, y: y + 0.1, w: 0.9, h: 0.5, fontSize: 24, bold: true, color: C.accent2 });
  txt(s, "hip-veredicto-" + h, v, { x: 8.0, y: y + 0.12, w: 4.5, h: 0.45, fontSize: 18, bold: true });
  txt(s, "hip-texto-" + h, t, { x: 7.1, y: y + 0.62, w: 5.4, h: 0.95, fontSize: 13 });
});
txt(s, "nota-peaton", "Matiz: peatón y atropello están muy ligados; el contraste es asociación, no causalidad.", { x: 0.6, y: 5.75, w: 6.0, h: 0.6, fontSize: 14, italic: true, color: C.accent6 });
s.addNotes("[1 min] Variables: lo que más información aporta es quién participa, tipo de actor y de vehículo, mucho más que la localidad o la hora. Para contrastar con inferencia usé una regresión logística ordinal ajustada por clase, localidad, diseño y vehículos pesados. H1 se confirma: con peatón los momios de mayor gravedad se multiplican por varias veces y con motociclista también; el bloque de actor vulnerable es el que más aporta al modelo, por encima de clase y localidad. H2 se confirma con efecto pequeño: noche y fin de semana aumentan el riesgo pero mucho menos que el tipo de actor. H3 en parte: hay perfiles muy distintos en letalidad pero los separa el actor, no la localidad ni la franja. Matiz: peatón y atropello están muy ligados, es asociación y no causalidad.");

s = newSlide("CONTENIDO", "Interpretación y evaluación", "Valor para la toma de decisiones");
const cl = D.clusters.slice().sort((a, b) => b.fatales_x_mil - a.fatales_x_mil);
s.addChart(pres.charts.BAR, [
  { name: "% de los siniestros", labels: cl.map((c) => c.nombre), values: cl.map((c) => Math.round(c.pct * 10) / 10) },
  { name: "% de los fatales", labels: cl.map((c) => c.nombre), values: cl.map((c) => Math.round(c.pct_fatales * 10) / 10) },
], { x: 0.6, y: 1.4, w: 7.6, h: 4.4, barDir: "bar", chartColors: ["8D99AE", "C0392B"], showLegend: true, legendPos: "b", legendFontSize: 13, showValue: true, dataLabelFormatCode: '0"%"', dataLabelFontSize: 12,
  catAxisLabelFontSize: 12, valAxisHidden: true, valGridLine: { style: "none" }, catAxisOrientation: "maxMin", showTitle: true, title: "Siniestros y fatales por perfil", titleFontSize: 14, barGapWidthPct: 60 });
const top = cl[0];
card(s, "valor-fondo", 8.5, 1.4, 4.2, 2.3, THEME.colors.dk1);
txt(s, "valor-cifra", pc(top.pct_fatales / 100, 0), { x: 8.7, y: 1.5, w: 3.8, h: 0.9, fontSize: 48, bold: true, color: C.accent1, valign: "middle" });
txt(s, "valor-texto", "de los fatales están en el perfil «" + top.nombre + "», que es el " + pc(top.pct / 100, 0) + " de los siniestros", { x: 8.7, y: 2.45, w: 3.8, h: 1.2, fontSize: 15, color: C.background1 });
txt(s, "valor-lista", [
  { text: "Focalizar por actor: cruces seguros, velocidad y campañas donde está la letalidad", options: { bullet: true, breakLine: true } },
  { text: "Priorizar operativos con el nivel de riesgo, no para predecir un evento individual", options: { bullet: true, breakLine: true } },
  { text: "Dentro de cada perfil, focalizar por territorio", options: { bullet: true } },
], { x: 8.5, y: 3.95, w: 4.2, h: 2.9, fontSize: 15, paraSpaceAfter: 8 });
cap(s, "fuente-cl", "k-medias sobre componentes principales de Train; perfiles descritos con variables originales", 0.6, 5.85, 7.6);
s.addNotes("[1 min] Valor para decidir. El agrupamiento k-medias sobre el espacio PCA separa " + D.k + " perfiles; el de atropellos a peatones es una fracción pequeña de los siniestros pero concentra una proporción enorme de los fatales. Eso se traduce en focalizar por tipo de actor, con cruces seguros, control de velocidad y campañas; y dentro de cada perfil focalizar por territorio. El nivel de riesgo sirve para priorizar el trabajo de análisis y de operativos, no para predecir un evento individual.");

// =========================== 8-9. DESPLIEGUE ===========================
pres.addSection({ title: "Despliegue" });
s = newSlide("CONTENIDO", "Despliegue", "Despliegue: cómo funciona el artefacto");
const etapas = ["Entrada del usuario", "Validación", "Variables del modelo", "Transformación con parámetros de Train", "Modelo guardado (.rds)", "Resultado en lenguaje claro"];
etapas.forEach((e, i) => {
  const x = 0.6 + i * 2.05;
  s.addShape(pres.shapes.ROUNDED_RECTANGLE, { x, y: 1.5, w: 1.85, h: 1.35, rectRadius: 0.08, fill: { color: i === 4 ? THEME.colors.dk1 : THEME.colors.lt2 }, line: { color: i === 4 ? THEME.colors.dk1 : THEME.colors.lt2, width: 0 }, objectName: "etapa-fondo-" + (i + 1) });
  txt(s, "etapa-texto-" + (i + 1), e, { x: x + 0.1, y: 1.55, w: 1.65, h: 1.25, fontSize: 14, bold: true, align: "center", valign: "middle", color: i === 4 ? C.background1 : C.text1 });
  if (i < 5) txt(s, "flecha-" + (i + 1), "→", { x: x + 1.82, y: 1.9, w: 0.25, h: 0.5, fontSize: 20, bold: true, color: C.accent2, align: "center" });
});
table(s, "tabla-puertas", [
  [hdr("Puerta de entrada"), hdr("Quién la usa"), hdr("Qué hace")],
  [cell("App Shiny", { bold: true, fontSize: 14 }), cell("Analistas de movilidad y tránsito", { fontSize: 14 }), cell("Formulario, resultado visual, lotes CSV y monitoreo", { fontSize: 14 })],
  [cell("API REST (plumber)", { bold: true, fontSize: 14 }), cell("Equipos técnicos", { fontSize: 14 }), cell("POST /predict con JSON; valida y responde con códigos HTTP", { fontSize: 14 })],
  [cell("Función en R", { bold: true, fontSize: 14 }), cell("Analistas que usan R", { fontSize: 14 }), cell("predecir_gravedad(csv, A) sobre archivos nuevos", { fontSize: 14 })],
], { x: 0.6, y: 3.2, w: 7.6, colW: [2.3, 2.5, 2.8], rowH: [0.45, 0.65, 0.65, 0.65] });
card(s, "lectura-fondo", 8.5, 3.2, 4.2, 2.4, THEME.colors.dk1);
txt(s, "lectura", [{ text: "Cómo se lee la salida", options: { bold: true, color: C.accent1, breakLine: true } },
  { text: "«6 % de víctimas fatales» = de 100 siniestros parecidos entre 2015 y 2020, unos 6 terminaron con muertos. El nivel Bajo / Medio / Alto ordena los casos.", options: { color: C.background1 } }], { x: 8.7, y: 3.3, w: 3.8, h: 2.2, fontSize: 15, valign: "middle" });
code(s, "codigo-carga", ["A <- cargar_artefactos()   # modelo ya entrenado", "predecir_gravedad(casos, A) # no reentrena"], 0.6, 5.8, 7.6, 0.95);
s.addNotes("[1,5 min] Diseño: es un artefacto con tres puertas sobre el mismo núcleo, que carga el modelo ya entrenado y los parámetros de Train; no reentrena. El flujo: valido la entrada, construyo las variables del modelo a partir de lo que el usuario sabe, aplico la transformación con los parámetros de Train, predigo con el modelo guardado y traduzco a lenguaje claro: probabilidad, nivel de riesgo, perfil y una recomendación orientativa. Lo usan analistas de movilidad con la app, equipos técnicos con la API y analistas de R con la función. Cómo se lee: seis por ciento de víctimas fatales significa que de cada cien siniestros parecidos, unos seis terminaron con muertos.");

s = newSlide("CONTENIDO", "Despliegue", "Demostración en vivo");
const casoTxt = (c) => { const x = D.casos.find((k) => k.caso.toLowerCase().includes(c)); return x; };
const filasDemo = [["Atropello nocturno", "atropello nocturno", "Caso normal: probabilidad alta"], ["Choque entre dos autos", "dos autos", "Caso normal: probabilidad baja"], ["Moto y bus, madrugada", "moto y bus", "Interacción moto + vehículo pesado"],
                   ["25 vehículos", "limite", "Caso límite: valor acotado + advertencia"], ["Hora 30, edad −5", "invalida", "Entrada inválida: se rechaza"]];
table(s, "tabla-demo", [[hdr("Caso"), hdr("P(fatal)"), hdr("Nivel"), hdr("Qué demuestra")]].concat(filasDemo.map(([n, k, q]) => { const c = casoTxt(k); const ok = c && c.valido;
  return [cell(n, { bold: true, fontSize: 14 }), cell(ok ? nf(100 * c.p_fatal, c.p_fatal < 0.01 ? 2 : 1) + " %" : "—", { fontSize: 14 }), cell(ok ? c.nivel : "rechazado", { fontSize: 14 }), cell(q, { fontSize: 14 })]; })),
  { x: 0.6, y: 1.4, w: 7.8, colW: [2.5, 1.2, 1.2, 2.9], rowH: [0.45, 0.62, 0.62, 0.62, 0.62, 0.62] });
cap(s, "fuente-demo", "Valores esperados con el modelo guardado (los mismos que ve la aplicación)", 0.6, 5.0, 7.8);
txt(s, "guion-demo", [
  { text: "Qué mostrar, en orden", options: { bold: true, breakLine: true } },
  { text: "1. Abrir la app y cargar un ejemplo", options: { breakLine: true } },
  { text: "2. Conectar con las métricas de Test", options: { breakLine: true } },
  { text: "3. Ingresar el caso del docente", options: { breakLine: true } },
  { text: "4. Caso límite y entrada inválida", options: { breakLine: true } },
  { text: "5. Subir un CSV nuevo", options: { breakLine: true } },
  { text: "6. (Opcional) API con curl", options: {} }], { x: 8.8, y: 1.4, w: 3.9, h: 3.2, fontSize: 15, paraSpaceAfter: 4 });
card(s, "conexion-fondo", 0.6, 5.45, 12.1, 1.35, THEME.colors.dk1);
txt(s, "conexion", [{ text: "Conexión con las métricas: ", options: { bold: true, color: C.accent1 } }, { text: "un nivel «Alto» corresponde en Test a " + nf(nivAlto.fatales_x_mil, 0) + " fatales por mil (el promedio es " + nf(1000 * D.prevalencia_fatal, 0) + "); el modelo detecta " + pc(D.test.recall[2], 0) + " de los fatales con " + pc(D.test.precision[2], 0) + " de precisión. Plan B: capturas y video en sustentacion_final/plan_b.", options: { color: C.background1 } }],
  { x: 0.85, y: 5.5, w: 11.6, h: 1.25, fontSize: 15, valign: "middle" });
s.addNotes("[4,5 min — demostración en vivo en la app Shiny]. 1) Abrir despliegue/app.R con Run App. Cargar «Atropello nocturno (Kennedy)» y pulsar Estimar: mostrar la probabilidad, el nivel de riesgo, el perfil y la recomendación; leerlo como lo leería una persona sin formación técnica. 2) Conectarlo con las métricas: en Test, el nivel alto concentra la letalidad (cifra en la diapositiva); el modelo detecta una parte de los fatales con la precisión indicada, sirve para ordenar. 3) Pedir al docente un caso y escribirlo en el formulario. 4) Caso límite de 25 vehículos: se evalúa con advertencia; entrada inválida de hora 30 y edad negativa: se rechaza con mensaje claro. 5) Pestaña Lote: subir casos_ejemplo.csv. 6) Opcional: la API con curl. Plan B: capturas y video en sustentacion_final/plan_b.");

// =========================== 10-11. MONITOREO Y CIERRE ===========================
pres.addSection({ title: "Monitoreo y cierre" });
s = newSlide("CONTENIDO", "Monitoreo y cierre", "Monitoreo y mantenimiento del modelo");
const psi = D.psi_2020.slice().sort((a, b) => b.psi - a.psi).slice(0, 5);
table(s, "tabla-psi", [[hdr("Variable"), hdr("PSI 2020 vs 2015–2019"), hdr("Estado")]].concat(psi.map((p) => [cell(p.variable, { fontSize: 14 }), cell(nf(p.psi, 3), { fontSize: 14 }), cell(p.estado, { fontSize: 14, bold: p.estado !== "Estable", color: p.estado === "Estable" ? C.text1 : C.accent2 })])),
  { x: 0.6, y: 1.4, w: 6.2, colW: [2.4, 2.4, 1.4], rowH: 0.52 });
cap(s, "fuente-psi", "PSI < 0,10 estable · 0,10–0,25 vigilar · > 0,25 deriva importante", 0.6, 4.6, 6.2);
txt(s, "triggers", [
  { text: "Qué se vigila", options: { bold: true, breakLine: true } },
  { text: "Deriva de las entradas: PSI trimestral", options: { bullet: true, breakLine: true } },
  { text: "Desempeño con etiquetas reales: recall fatal y F1 macro", options: { bullet: true, breakLine: true } },
  { text: "Alerta: recall fatal cae más de 10 puntos o el nivel «Alto» deja de concentrar los fatales", options: { bullet: true, breakLine: true } },
  { text: "Reentrenar con deriva (PSI > 0,25), caída de desempeño o datos posteriores a 2020", options: { bullet: true } }], { x: 0.6, y: 5.0, w: 6.2, h: 1.9, fontSize: 14, paraSpaceAfter: 3 });
card(s, "etica-fondo", 7.1, 1.4, 5.6, 5.4);
txt(s, "etica", [
  { text: "Ética, privacidad y escalabilidad", options: { bold: true, color: C.accent2, breakLine: true, fontSize: 18 } },
  { text: "Variables agregadas por siniestro: no identifica personas", options: { bullet: true, breakLine: true } },
  { text: "No usarlo para decidir sobre individuos (sanciones, perfilamiento)", options: { bullet: true, breakLine: true } },
  { text: "Sesgo de registro y territorial: usar el riesgo para priorizar, con revisión humana", options: { bullet: true, breakLine: true } },
  { text: "La probabilidad es una estimación, no una certeza", options: { bullet: true, breakLine: true } },
  { text: "Escalar: publicar la API en contenedor; Shiny atiende pocos usuarios", options: { bullet: true } }], { x: 7.35, y: 1.55, w: 5.1, h: 5.1, fontSize: 15, paraSpaceAfter: 9 });
s.addNotes("[1 min] Monitoreo: vigilo tres cosas. La deriva de las entradas con el PSI, que ya implementé: comparado 2020 con 2015–2019 se ven variables fuera del rango estable, justo lo que activaría una revisión. El desempeño cuando llegan las etiquetas reales: recall de la clase fatal y F1 macro, con alerta si el recall cae más de 10 puntos. Y reentrenar ante deriva, caída de desempeño o datos nuevos. Ética: el modelo describe siniestros, no personas; no debe usarse para sancionar ni perfilar individuos; hay sesgo de registro y territorial; la probabilidad no es certeza. Escalabilidad: Shiny atiende pocos usuarios; para uso institucional publicaría la API en un contenedor.");

s = newSlide("OSCURO", "Monitoreo y cierre", "Conclusiones y trabajo futuro");
card(s, "concl-fondo", 0.6, 1.9, 6.0, 4.9, THEME.colors.dk2);
txt(s, "concl-titulo", "Conclusiones", { x: 0.85, y: 2.0, w: 5.5, h: 0.5, fontSize: 22, bold: true, color: C.accent1 });
txt(s, "concl-lista", [
  { text: "La preparación de datos importó más que el algoritmo (fuga por pasajeros, edad 118, gravedad inconsistente)", options: { bullet: true, breakLine: true } },
  { text: "El modelo ordena bien, no «adivina» fatales: su valor es priorizar", options: { bullet: true, breakLine: true } },
  { text: "Domina el tipo de actor y de vehículo sobre la localidad y la hora", options: { bullet: true, breakLine: true } },
  { text: "Artefacto funcional, validado y con plan de monitoreo", options: { bullet: true } }], { x: 0.85, y: 2.6, w: 5.5, h: 4.1, fontSize: 16, color: C.background1, paraSpaceAfter: 9 });
card(s, "fut-fondo", 6.9, 1.9, 5.8, 2.4, THEME.colors.dk2);
txt(s, "lim-titulo", "Limitaciones", { x: 7.15, y: 2.0, w: 5.3, h: 0.45, fontSize: 20, bold: true, color: C.accent1 });
txt(s, "lim-lista", [{ text: "Datos 2015–2020 (pandemia); sin velocidad, vía, clima ni casco", options: { bullet: true, breakLine: true } }, { text: "Subregistro y sesgos territoriales; sin datos de exposición", options: { bullet: true } }], { x: 7.15, y: 2.5, w: 5.3, h: 1.7, fontSize: 15, color: C.background1, paraSpaceAfter: 6 });
card(s, "fut2-fondo", 6.9, 4.5, 5.8, 2.3, THEME.colors.dk2);
txt(s, "fut-titulo", "Trabajo futuro", { x: 7.15, y: 4.6, w: 5.3, h: 0.45, fontSize: 20, bold: true, color: C.accent1 });
txt(s, "fut-lista", [{ text: "Datos 2021+ con velocidad, clima y flujo vehicular", options: { bullet: true, breakLine: true } }, { text: "Validación temporal y calibración explícita", options: { bullet: true, breakLine: true } }, { text: "API en contenedor y tablero de monitoreo automático", options: { bullet: true } }], { x: 7.15, y: 5.1, w: 5.3, h: 1.6, fontSize: 15, color: C.background1, paraSpaceAfter: 6 });
s.addNotes("[1 min] Conclusiones: lo más valioso fue la preparación de los datos; el modelo ordena bien pero no adivina fatales, su valor está en priorizar; el tipo de actor y de vehículo domina sobre la localidad y la hora; y el artefacto funciona con datos nuevos, valida entradas y tiene plan de monitoreo. Limitaciones: datos hasta 2020, sin velocidad, vía, clima ni casco, y subregistro. Trabajo futuro: datos nuevos con más variables, validación temporal y calibración, y llevar la API a un contenedor con monitoreo automático. Muchas gracias; quedo atento a las preguntas.");

// =========================== 12. PLAN B ===========================
s = newSlide("CONTENIDO", "Monitoreo y cierre", "Plan B: capturas de la demostración");
const caps = [["02_atropello_nocturno.png", "Atropello nocturno"], ["05_caso_limite.png", "Caso límite (25 vehículos)"], ["06_entrada_invalida.png", "Entrada inválida"], ["08_lote_csv.png", "Lote CSV"]];
caps.forEach(([f, t], i) => {
  const x = 0.6 + (i % 2) * 6.15, y = 1.4 + Math.floor(i / 2) * 2.8;
  if (fs.existsSync(CAP(f))) s.addImage({ path: CAP(f), x, y, w: 5.9, h: 2.45, sizing: { type: "contain", w: 5.9, h: 2.45 }, altText: t });
  cap(s, "plan-b-" + (i + 1), t, x, y + 2.47, 5.9);
});
s.addNotes("Diapositiva de respaldo: usar solo si falla la demostración en vivo (el criterio de demostración quedaría como máximo en nivel Básico). También hay un video en sustentacion_final/plan_b/demo.mp4.");

pres.writeFile({ fileName: path.join(__dirname, "sustentacion_final.pptx") }).then(async (f) => {
  const { applyTheme } = require(process.env.SKILL_DIR + "/scripts/apply_theme.js");
  await applyTheme(f, THEME);
  console.log("OK", f);
});
