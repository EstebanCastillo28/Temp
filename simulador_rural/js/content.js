/* Contenido de la pestaña "Aprende": resumen de la investigación (detalle completo en docs/INFORME.md) */
window.LEARN_HTML = `
<h2>El problema: ganadería extensiva y degradación ambiental en Colombia</h2>
<p>Gran parte de la ganadería colombiana se practica de forma <b>extensiva</b>: pocos animales por hectárea, pastoreo continuo, potreros sin árboles y sin descanso. Colombia destina a pasturas una superficie muy superior a la que tiene vocación ganadera (cifras citadas por IGAC y Fedegán: ~34 M ha en pasturas frente a ~15 M ha aptas; ver informe para fuentes).</p>
<h3>Causas</h3>
<ul><li>Ampliación de la frontera ganadera sobre bosques (praderización) y acaparamiento de tierras.</li>
<li>Sobrepastoreo y carga animal superior a la capacidad del potrero.</li>
<li>Quemas para "rebrotar" el pasto, uso intensivo de agroquímicos y falta de asistencia técnica.</li>
<li>Baja rentabilidad por hectárea, que empuja a "abrir más potrero".</li></ul>
<h3>Impactos</h3>
<table><tr><th>Componente</th><th>Impacto</th><th>En el simulador</th></tr>
<tr><td>Suelo</td><td>Compactación, erosión, pérdida de materia orgánica</td><td>Indicador <i>Suelo</i></td></tr>
<tr><td>Agua</td><td>Menor infiltración, sequía de quebradas, contaminación por sedimentos y estiércol</td><td><i>Caudal</i> y <i>Calidad del agua</i></td></tr>
<tr><td>Biodiversidad</td><td>Fragmentación y pérdida de hábitat, desaparición de polinizadores y aves</td><td><i>Biodiversidad</i></td></tr>
<tr><td>Clima</td><td>Emisiones de CH₄ y CO₂ (deforestación, quemas), mayor vulnerabilidad a El Niño/La Niña</td><td><i>Carbono neto</i> y eventos climáticos</td></tr>
<tr><td>Economía rural</td><td>Menor productividad, endeudamiento, abandono de tierras</td><td><i>Capital</i> y condición del hato</td></tr></table>
<h3>Soluciones de manejo del ecosistema</h3>
<ul><li><b>Pastoreo rotacional</b>: dividir en potreros, ocupar pocos a la vez y dar descanso para que el pasto se recupere.</li>
<li><b>Sistemas silvopastoriles</b>: árboles y arbustos forrajeros (leucaena, botón de oro, matarratón) dentro del potrero: sombra, forraje extra, fijación de nitrógeno, suelo y agua.</li>
<li><b>Bancos forrajeros</b> de corte para épocas secas.</li>
<li><b>Protección de rondas hídricas</b> (franja punteada azul en el mapa): cercas y reforestación junto a la quebrada.</li>
<li><b>Restauración y regeneración natural</b> de áreas degradadas y conectividad con el bosque.</li>
<li><b>Abonos orgánicos</b> en lugar de depender de fertilizantes químicos.</li>
<li><b>Incentivos</b>: pago por servicios ambientales (PSA) y mercados de carne/leche sostenible.</li></ul>
<h3>Cómo jugar</h3>
<ol><li>Selecciona un potrero y aplica acciones (silvopastoril, regenerar, forraje, abono…).</li>
<li>Define el pastoreo (continuo o rotacional) y ajusta el tamaño del hato a la capacidad de carga.</li>
<li>Avanza los meses. Habrá un <b>El Niño</b> (año 3-4) y una <b>La Niña</b> (año 7): prepara la finca.</li>
<li>Al mes 120 se calcula el puntaje: 40 % económico + 60 % sostenibilidad (suelo, caudal, calidad del agua, biodiversidad, carbono).</li></ol>
<p><i>Reto:</i> ¿puedes superar 70 puntos? Prueba también la "mala práctica" (quemar, talar, fertilizar) y compara.</p>
<h3>Supuestos del modelo</h3>
<p>Es un modelo educativo simplificado (potreros de 1 ha, paso mensual, parámetros calibrados cualitativamente, no con datos de campo). Las tendencias son realistas; los valores numéricos no deben usarse para decisiones reales. Detalles en <code>docs/INFORME.md</code>.</p>`;
