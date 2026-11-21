(function () {
  'use strict';
  const S = Sim, T = S.T;
  const MESES = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  const NOMBRES = { pasto: 'Pasto (extensivo)', silvo: 'Silvopastoril', bosque: 'Bosque', regen: 'Regeneración', forraje: 'Banco forrajero', agua: 'Quebrada' };
  const ICON = { pasto: '🌾', silvo: '🌳', bosque: '🌲', regen: '🌱', forraje: '🥬', agua: '💧' };
  const COLOR = { pasto: '#b9d86b', silvo: '#6fae4d', bosque: '#1e5a2b', regen: '#4f8f5a', forraje: '#e6c84a', agua: '#4aa3df' };
  const $ = id => document.getElementById(id);
  let sim = S.create(), sel = null, timer = null;

  const SERIES = [['money', 'Capital', '#8d6e00', 300], ['soil', 'Suelo', '#795548', 100], ['water', 'Caudal', '#1e88e5', 100], ['bio', 'Biodiversidad', '#2e7d32', 100], ['cattle', 'Hato', '#7b1fa2', 80]];

  function toast(msg) { const t = $('toast'); t.textContent = msg; t.classList.add('show'); clearTimeout(toast.h); toast.h = setTimeout(() => t.classList.remove('show'), 2400); }

  function lerpColor(v, a, b) { // v 0-100: a (bajo) -> b (alto), colores [r,g,b]
    const k = Math.max(0, Math.min(1, v / 100)); return 'rgb(' + a.map((x, i) => Math.round(x + (b[i] - x) * k)).join(',') + ')';
  }
  function cellColor(c, layer) {
    if (c.type === T.AGUA) return COLOR.agua;
    if (layer === 'uso') return COLOR[c.type];
    if (c.type === T.BOSQUE && layer === 'grass') return '#ddd';
    const v = layer === 'grass' ? c.grass : layer === 'soil' ? c.soil : c.trees;
    return layer === 'soil' ? lerpColor(v, [196, 160, 120], [90, 60, 30]) : lerpColor(v, [240, 235, 190], [30, 120, 50]);
  }

  function renderGrid() {
    const g = $('grid'), layer = $('layer').value; g.innerHTML = '';
    sim.cells.forEach(c => {
      const b = document.createElement('button');
      b.className = 'cell' + (c.ribera ? ' rib' : '') + (sel === c.id ? ' sel' : '');
      b.style.background = cellColor(c, layer);
      b.title = NOMBRES[c.type] + ' · potrero ' + (c.id + 1);
      b.setAttribute('aria-label', NOMBRES[c.type] + ' potrero ' + (c.id + 1));
      b.innerHTML = ICON[c.type] + (c.burnt > 0 ? '🔥' : '') + (c.type !== T.AGUA ? '<small>' + Math.round(layer === 'soil' ? c.soil : layer === 'trees' ? c.trees : c.grass) + '</small>' : '');
      b.onclick = () => { sel = c.id; renderGrid(); renderCell(); };
      g.appendChild(b);
    });
    $('legend').innerHTML = Object.keys(NOMBRES).map(k => '<span><i style="background:' + COLOR[k] + '"></i>' + NOMBRES[k] + '</span>').join('') + '<span>┄ ronda hídrica</span>';
  }

  function renderCell() {
    const info = $('cellInfo'), box = $('cellActions'); box.innerHTML = '';
    if (sel == null) return;
    const c = sim.cells[sel];
    if (c.type === T.AGUA) { info.textContent = 'Quebrada: fuente de agua de la finca. Su caudal depende de la cobertura arbórea, del suelo y de la lluvia.'; return; }
    info.innerHTML = '<b>Potrero ' + (c.id + 1) + ' · ' + NOMBRES[c.type] + '</b>' + (c.ribera ? ' (ronda hídrica)' : '') + '<br>Pasto ' + c.grass.toFixed(0) + ' · Suelo ' + c.soil.toFixed(0) + ' · Árboles ' + c.trees.toFixed(0) + '%' + (c.burnt > 0 ? ' · 🔥 quemado' : '');
    const A = (name, label, cost, cls) => {
      const b = document.createElement('button'); b.className = cls || ''; b.innerHTML = label + (cost ? ' <small>($' + cost + ' M)</small>' : '');
      b.onclick = () => { const r = S.act(sim, name, c.id); toast(r.msg); refresh(); }; box.appendChild(b);
    };
    const P = S.P.costos;
    if (c.type === T.PASTO) { A('silvo', '🌳 Sembrar árboles (silvopastoril)', P.silvo); A('forraje', '🥬 Banco forrajero', P.forraje); }
    if ([T.PASTO, T.SILVO, T.FORRAJE].includes(c.type)) { A('regen', '🌱 Regenerar / restaurar', P.regen); A('compost', '♻ Abono orgánico', P.compost); }
    if ([T.PASTO, T.FORRAJE].includes(c.type)) A('fert', '🧪 Fertilizante químico', P.fert, 'bad');
    if ([T.PASTO, T.SILVO].includes(c.type)) A('quemar', '🔥 Quemar', 0, 'bad');
    if (c.type === T.BOSQUE || (c.type === T.REGEN && c.trees >= 40)) A('deforestar', '🪓 Talar y pasturizar', 0, 'bad');
    if (c.type === T.BOSQUE) box.insertAdjacentHTML('beforeend', '<small>El bosque recibe PSA (pago por servicios ambientales) y protege el agua.</small>');
  }

  function bar(label, v, color, txt) {
    return '<div class="kpi"><span>' + label + '</span><div class="meter"><div style="width:' + Math.max(0, Math.min(100, v)) + '%;background:' + color + '"></div></div><b>' + txt + '</b></div>';
  }
  function renderKpis() {
    const k = S.metrics(sim), L = sim.last || {};
    const col = v => v >= 60 ? '#2e7d32' : v >= 35 ? '#e6a700' : '#c62828';
    $('kpis').innerHTML =
      bar('Capital', sim.money / 3, '#8d6e00', '$' + sim.money.toFixed(0) + ' M') +
      bar('Suelo', k.soil, col(k.soil), k.soil.toFixed(0)) +
      bar('Pasto', k.grass, col(k.grass), k.grass.toFixed(0)) +
      bar('Caudal quebrada', sim.water, col(sim.water), sim.water.toFixed(0)) +
      bar('Calidad del agua', sim.wq, col(sim.wq), sim.wq.toFixed(0)) +
      bar('Biodiversidad', sim.bio, col(sim.bio), sim.bio.toFixed(0)) +
      bar('Condición hato', sim.cond, col(sim.cond), sim.cond.toFixed(0)) +
      '<div class="info">Carbono neto: <b>' + k.carbonNet.toFixed(0) + ' tCO₂e</b> · Ingreso mes: $' + (L.ingreso || 0).toFixed(1) + ' M + PSA $' + (L.psa || 0).toFixed(1) + ' M − costos $' + (L.costo || 0).toFixed(1) + ' M' + (L.premium > 1 ? ' · 🏅 prima de mercado sostenible' : '') + '</div>';
  }

  function renderChart() {
    const cv = $('chart'), x = cv.getContext('2d'), w = cv.width, h = cv.height, H = sim.history;
    x.clearRect(0, 0, w, h); x.strokeStyle = '#d6e2d3'; x.lineWidth = 1;
    for (let i = 0; i <= 4; i++) { x.beginPath(); x.moveTo(30, 10 + i * (h - 30) / 4); x.lineTo(w - 6, 10 + i * (h - 30) / 4); x.stroke(); }
    x.fillStyle = '#5b6b5b'; x.font = '10px sans-serif'; x.fillText('0', 14, h - 18); x.fillText('Año 0', 30, h - 4); x.fillText('Año 10', w - 44, h - 4);
    SERIES.forEach(([key, , color, max]) => {
      x.strokeStyle = color; x.lineWidth = 2; x.beginPath();
      H.forEach((p, i) => { const px = 30 + (w - 36) * p.m / S.MONTHS, py = 10 + (h - 30) * (1 - Math.max(0, Math.min(1, p[key] / max))); i ? x.lineTo(px, py) : x.moveTo(px, py); });
      x.stroke();
    });
    $('chartLegend').innerHTML = SERIES.map(s => '<span><i style="background:' + s[2] + '"></i>' + s[1] + '</span>').join('');
  }

  function renderClock() {
    const m = sim.month;
    $('year').textContent = 'Año ' + (Math.min(9, Math.floor(m / 12)) + 1); $('monthName').textContent = MESES[m % 12];
    $('monthNum').textContent = '(mes ' + m + '/' + S.MONTHS + ')';
    const cl = $('climate'); cl.textContent = sim.climate + ' · ' + sim.rain.toFixed(0) + ' mm';
    cl.className = 'badge' + (sim.climate.startsWith('El') ? ' sequia' : sim.climate.startsWith('La') ? ' lluvia' : '');
    $('cattle').textContent = Math.floor(sim.cattle);
    $('grazing').value = sim.grazing; $('supp').checked = sim.suplemento;
    $('log').innerHTML = sim.log.map(l => '<li class="' + l.tipo + '"><b>M' + l.m + ':</b> ' + l.text + '</li>').join('');
    ['btnStep', 'btnYear', 'btnPlay', 'buy1', 'buy5', 'sell1', 'sell5'].forEach(id => $(id).disabled = sim.over && id !== 'x');
  }

  function showEnd() {
    const f = sim.final; if (!f) return;
    const row = (n, v) => '<tr><td>' + n + '</td><td>' + v.toFixed(0) + ' / 100</td></tr>';
    const msg = f.total >= 70 ? 'Lograste conciliar producción y conservación: la finca es rentable y resiliente.' : f.total >= 50 ? 'Vas por buen camino; revisa qué indicador quedó más bajo.' : 'El manejo actual degrada los recursos de los que depende la producción. Prueba rotación, árboles en potrero y protección del agua.';
    $('endBody').innerHTML = '<h2>Fin de la simulación</h2><p>' + sim.endReason + '</p><table class="doc" style="width:100%"><tr><th>Componente</th><th>Puntaje</th></tr>' +
      row('Económico (patrimonio $' + f.patrimonio.toFixed(0) + ' M)', f.eco) + row('Suelo', f.soil) + row('Caudal', f.water) + row('Calidad del agua', f.wq) + row('Biodiversidad', f.bio) + row('Carbono', f.carbonIdx) +
      '</table><h3>Puntaje total: ' + f.total.toFixed(0) + ' / 100</h3><p><b>' + f.nivel + '</b></p><p>' + msg + '</p><p><small>Ahora diligencia la pestaña "Retroalimentación" (puntaje final: ' + f.total.toFixed(0) + ').</small></p>';
    $('endDlg').showModal();
    const inp = document.querySelector('#fbForm [name=puntaje]'); if (inp) inp.value = f.total.toFixed(0);
  }

  function refresh() { renderGrid(); renderCell(); renderKpis(); renderChart(); renderClock(); if (sim.over) { stop(); showEnd(); } }
  function stop() { clearInterval(timer); timer = null; $('btnPlay').textContent = '▶ Auto'; }

  $('btnStep').onclick = () => { S.step(sim); refresh(); };
  $('btnYear').onclick = () => { for (let i = 0; i < 12 && !sim.over; i++) S.step(sim); refresh(); };
  $('btnPlay').onclick = () => { if (timer) return stop(); $('btnPlay').textContent = '⏸ Pausa'; timer = setInterval(() => { S.step(sim); refresh(); }, 450); };
  $('btnReset').onclick = () => { stop(); sim = S.create(); sel = null; refresh(); };
  $('layer').onchange = renderGrid;
  $('grazing').onchange = e => { toast(S.act(sim, 'pastoreo', e.target.value).msg); };
  $('supp').onchange = e => { toast(S.act(sim, 'suplemento', e.target.checked).msg); };
  [['buy1', 'comprar', 1], ['buy5', 'comprar', 5], ['sell1', 'vender', 1], ['sell5', 'vender', 5]].forEach(([id, a, n]) => $(id).onclick = () => { toast(S.act(sim, a, n).msg); refresh(); });

  // Pestañas
  document.querySelectorAll('#tabs button').forEach(b => b.onclick = () => {
    document.querySelectorAll('#tabs button').forEach(x => x.classList.toggle('on', x === b));
    ['sim', 'learn', 'fb'].forEach(t => $('tab-' + t).hidden = t !== b.dataset.tab);
  });
  $('learnDoc').innerHTML = window.LEARN_HTML;

  // Retroalimentación (localStorage)
  const KEY = 'simFincaFeedback';
  const load = () => { try { return JSON.parse(localStorage.getItem(KEY) || '[]'); } catch (e) { return []; } };
  document.querySelectorAll('#fbForm select').forEach(s => { for (let i = 1; i <= 5; i++) s.add(new Option(i, i)); s.value = 4; });
  function renderFb() {
    const d = load(); $('fbN').textContent = d.length;
    if (!d.length) { $('fbSummary').textContent = 'Aún no hay respuestas.'; return; }
    const avg = k => (d.reduce((a, r) => a + Number(r[k]), 0) / d.length).toFixed(2);
    $('fbSummary').innerHTML = '<table><tr><th>Criterio</th><th>Promedio (1-5)</th></tr><tr><td>Facilidad de uso</td><td>' + avg('uso') + '</td></tr><tr><td>Interfaz</td><td>' + avg('ui') + '</td></tr><tr><td>Realismo</td><td>' + avg('real') + '</td></tr><tr><td>Aprendizaje</td><td>' + avg('aprend') + '</td></tr></table>';
  }
  $('fbForm').onsubmit = e => {
    e.preventDefault(); const d = load(); const r = Object.fromEntries(new FormData(e.target)); r.fecha = new Date().toISOString();
    d.push(r); try { localStorage.setItem(KEY, JSON.stringify(d)); toast('¡Gracias! Respuesta guardada.'); } catch (x) { toast('No se pudo guardar en este navegador.'); }
    e.target.reset(); renderFb();
  };
  $('fbExport').onclick = () => {
    const a = document.createElement('a'); a.href = URL.createObjectURL(new Blob([JSON.stringify(load(), null, 2)], { type: 'application/json' })); a.download = 'retroalimentacion.json'; a.click();
  };
  $('fbClear').onclick = () => { if (confirm('¿Borrar todas las respuestas guardadas?')) { try { localStorage.removeItem(KEY); } catch (e) { } renderFb(); } };

  renderFb(); refresh();
})();
