/* Motor de simulación - Finca ganadera (Ingeniería y Desarrollo Regional)
   Sin dependencias del DOM: funciona en navegador y en Node (pruebas). */
(function (root) {
  'use strict';
  const COLS = 8, ROWS = 6, MONTHS = 120;
  const T = { AGUA: 'agua', PASTO: 'pasto', SILVO: 'silvo', BOSQUE: 'bosque', REGEN: 'regen', FORRAJE: 'forraje' };
  const P = {
    demandaAnimal: 14,      // unidades de forraje / animal / mes
    ingresoAnimal: 0.30,    // millones COP / animal / mes (leche + ganancia de peso) con condición 100%
    costoFijo: 3.0, costoAnimal: 0.04, costoSuplemento: 0.06,
    precioVenta: 2.5, precioCompra: 2.8,
    costos: { silvo: 4.0, regen: 0.6, forraje: 2.5, compost: 0.8, fert: 0.7 },
    quiebra: -25
  };
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));

  function rand(s) { // mulberry32 con estado en el objeto (reproducible)
    s.rs = (s.rs + 0x6D2B79F5) >>> 0;
    let t = s.rs;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }

  function create(opts) {
    opts = opts || {};
    const s = {
      rs: (opts.seed == null ? 2026 : opts.seed) >>> 0,
      month: 0, over: false, endReason: '', final: null,
      money: 20, cattle: 32, cond: 65,
      grazing: 'continuo', suplemento: false,
      rain: 110, climate: 'Normal',
      water: 70, wq: 80, bio: 0, emis: 0, cumIncome: 0,
      cells: [], log: [], history: [], last: {}
    };
    const forest = { '6,0': 1, '7,0': 1, '6,1': 1, '7,1': 1 };
    for (let y = 0; y < ROWS; y++) for (let x = 0; x < COLS; x++) {
      const c = { id: y * COLS + x, x, y, type: T.PASTO, grass: 0, soil: 0, trees: 0, fert: 0, burnt: 0, ribera: x === 1 };
      if (x === 0) { c.type = T.AGUA; }
      else if (forest[x + ',' + y]) { c.type = T.BOSQUE; c.trees = 85; c.soil = 82; }
      else { c.grass = 50 + rand(s) * 12; c.soil = 48 + rand(s) * 10; c.trees = 3; }
      s.cells.push(c);
    }
    s.bio = targetBio(s);
    addLog(s, 'Bienvenido a la finca "La Esperanza". Decide cómo manejar 38 ha durante 10 años.');
    snapshot(s);
    return s;
  }

  function addLog(s, text, tipo) { s.log.unshift({ m: s.month, text, tipo: tipo || 'info' }); if (s.log.length > 80) s.log.pop(); }
  const land = s => s.cells.filter(c => c.type !== T.AGUA);

  function cellBio(c) {
    const base = { bosque: 1, regen: 0.7, silvo: 0.55, forraje: 0.35, pasto: 0.15 }[c.type] || 0;
    return clamp(base + (c.type === 'silvo' || c.type === 'pasto' ? c.trees * 0.002 : 0) - (c.burnt > 0 ? 0.15 : 0), 0, 1);
  }
  function targetBio(s) {
    const L = land(s); let sum = 0;
    for (const c of L) {
      let b = cellBio(c);
      // conectividad: bonus si vecino es bosque/regeneración
      const vec = neighbors(s, c);
      if (c.type !== T.BOSQUE && vec.some(v => v.type === T.BOSQUE || v.type === T.REGEN)) b += 0.06;
      sum += b;
    }
    const chem = L.filter(c => c.fert > 0).length / L.length;
    return clamp(100 * (sum / L.length) * (0.7 + 0.3 * s.wq / 100) * (1 - 0.5 * chem), 0, 100);
  }
  function neighbors(s, c) {
    const out = [];
    [[1, 0], [-1, 0], [0, 1], [0, -1]].forEach(d => {
      const x = c.x + d[0], y = c.y + d[1];
      if (x >= 0 && x < COLS && y >= 0 && y < ROWS) out.push(s.cells[y * COLS + x]);
    });
    return out;
  }

  /* ---------- Acciones del jugador ---------- */
  function pay(s, cost) { if (s.money < cost) return false; s.money -= cost; return true; }
  function act(s, name, arg) {
    if (s.over) return { ok: false, msg: 'La simulación terminó.' };
    const c = (typeof arg === 'number' && name !== 'comprar' && name !== 'vender') ? s.cells[arg] : null;
    const fail = m => ({ ok: false, msg: m });
    const need = (types) => c && types.includes(c.type);
    switch (name) {
      case 'silvo':
        if (!need([T.PASTO])) return fail('Solo se puede sembrar árboles en potreros de pasto.');
        if (!pay(s, P.costos.silvo)) return fail('Dinero insuficiente (' + P.costos.silvo + ' M).');
        c.type = T.SILVO; c.trees = Math.max(c.trees, 6); return { ok: true, msg: 'Sistema silvopastoril establecido (leucaena, botón de oro, nogal cafetero).' };
      case 'regen':
        if (!need([T.PASTO, T.SILVO, T.FORRAJE])) return fail('Solo en potreros productivos.');
        if (!pay(s, P.costos.regen)) return fail('Dinero insuficiente.');
        c.type = T.REGEN; c.grass = 0; c.trees = Math.max(c.trees, 8); return { ok: true, msg: 'Potrero aislado para regeneración natural / restauración.' };
      case 'forraje':
        if (!need([T.PASTO])) return fail('Solo se puede establecer banco forrajero en potreros de pasto.');
        if (!pay(s, P.costos.forraje)) return fail('Dinero insuficiente.');
        c.type = T.FORRAJE; c.grass = 30; return { ok: true, msg: 'Banco forrajero de corte establecido.' };
      case 'compost':
        if (!need([T.PASTO, T.SILVO, T.FORRAJE])) return fail('No aplica a esta celda.');
        if (!pay(s, P.costos.compost)) return fail('Dinero insuficiente.');
        c.soil = clamp(c.soil + 8, 0, 100); return { ok: true, msg: 'Abono orgánico aplicado: +8 de calidad de suelo.' };
      case 'fert':
        if (!need([T.PASTO, T.FORRAJE])) return fail('No aplica a esta celda.');
        if (!pay(s, P.costos.fert)) return fail('Dinero insuficiente.');
        c.fert = 3; return { ok: true, msg: 'Fertilizante químico: crecimiento rápido, pero acidifica el suelo y contamina el agua.' };
      case 'quemar':
        if (!need([T.PASTO, T.SILVO])) return fail('Solo se queman potreros.');
        c.grass = Math.min(c.type === T.SILVO ? 80 : 100, 85); c.soil = clamp(c.soil - 8, 0, 100); c.trees = c.type === T.SILVO ? c.trees * 0.3 : 0;
        c.burnt = 6; s.emis += 4; addLog(s, 'Quema en el potrero ' + (c.id + 1) + ': rebrote rápido, pero se pierde suelo, árboles y biodiversidad.', 'mal'); return { ok: true, msg: 'Quema ejecutada (práctica de alto impacto).' };
      case 'deforestar':
        if (!need([T.BOSQUE, T.REGEN])) return fail('Solo en bosque o rastrojo.');
        if (c.type === T.REGEN && c.trees < 40) return fail('El rastrojo aún no tiene madera aprovechable.');
        s.money += c.trees * 0.08; s.emis += c.trees * 1.2;
        c.type = T.PASTO; c.grass = 80; c.soil = c.soil * 0.9; c.trees = 0;
        addLog(s, 'Se taló el potrero ' + (c.id + 1) + ': ingreso inmediato por madera, pérdida de hábitat y carbono.', 'mal'); return { ok: true, msg: 'Deforestación: ingreso inmediato, costo ambiental alto.' };
      case 'comprar': {
        const n = Math.max(1, arg | 0); if (!pay(s, n * P.precioCompra)) return fail('Dinero insuficiente.'); s.cattle += n; s.cond = Math.max(40, s.cond - n * 0.2); return { ok: true, msg: 'Compraste ' + n + ' animales.' };
      }
      case 'vender': {
        const n = Math.max(1, arg | 0); if (s.cattle - n < 0) return fail('No tienes tantos animales.'); s.cattle -= n; s.money += n * P.precioVenta; return { ok: true, msg: 'Vendiste ' + n + ' animales.' };
      }
      case 'pastoreo': s.grazing = arg === 'rotacional' ? 'rotacional' : 'continuo'; return { ok: true, msg: 'Manejo del pastoreo: ' + s.grazing + '.' };
      case 'suplemento': s.suplemento = !!arg; return { ok: true, msg: 'Suplemento ' + (s.suplemento ? 'activado' : 'desactivado') + '.' };
    }
    return fail('Acción desconocida.');
  }

  /* ---------- Un mes de simulación ---------- */
  function step(s) {
    if (s.over) return s;
    const m = s.month, mo = m % 12, cells = s.cells, L = land(s);
    // Clima: bimodal andino + El Niño (meses 30-39) y La Niña (78-86): iguales en toda corrida para comparar estrategias
    let enso = 1; if (m >= 30 && m <= 39) enso = 0.55; else if (m >= 78 && m <= 86) enso = 1.35;
    s.rain = (110 + 55 * Math.cos(2 * Math.PI * (mo - 4) / 6)) * enso * (0.9 + 0.2 * rand(s));
    const prevClimate = s.climate;
    s.climate = enso < 1 ? 'El Niño (sequía)' : enso > 1 ? 'La Niña (lluvias fuertes)' : 'Normal';
    if (s.climate !== prevClimate) addLog(s, 'Clima: ' + s.climate + '.', enso === 1 ? 'info' : 'alerta');
    const rainEff = s.rain / 110;

    // --- Oferta de forraje ---
    const demand = s.cattle * P.demandaAnimal;
    let others = 0;
    for (const c of L) {
      if (c.type === T.SILVO) others += 0.15 * c.trees * Math.min(1, 0.4 + rainEff * 0.6);
      if (c.type === T.FORRAJE) { const cut = 0.4 * c.grass; c.grass -= cut; others += cut; }
    }
    if (s.suplemento) others += s.cattle * 4;
    const needG = Math.max(0, demand - others);
    const grazable = L.filter(c => c.type === T.PASTO || c.type === T.SILVO);
    let chosen = grazable, util = 0.4;
    if (s.grazing === 'rotacional') {
      const k = Math.max(1, Math.ceil(grazable.length / 3));
      chosen = grazable.slice().sort((a, b) => b.grass - a.grass).slice(0, k); util = 0.55;
    }
    const grazedIds = new Set(); let grassTaken = 0, overgrazed = 0, riberaAcceso = 0;
    if (chosen.length && needG > 0) {
      const load = needG / chosen.length;
      for (const c of chosen) {
        const take = Math.min(load, util * c.grass);
        c.grass -= take; grassTaken += take; grazedIds.add(c.id);
        if (c.grass < 20) { overgrazed++; c.soil = clamp(c.soil - 0.35, 0, 100); }
        if (c.ribera && c.trees < 30) riberaAcceso++;
      }
    }
    const supply = others + grassTaken;
    const ratio = demand > 0 ? supply / demand : 1;

    // --- Condición corporal y hato ---
    const gz = grazable.length ? grazable.reduce((a, c) => a + c.trees, 0) / grazable.length : 0;
    s.cond = clamp(s.cond + clamp((ratio - 0.85) * 28, -9, 5) + (rainEff < 0.8 ? 0.06 * gz : 0.02 * gz) - 0.8, 5, 100);
    if (s.cond < 25) s.cattle *= s.cond < 12 ? 0.9 : 0.96;
    s.cattle += s.cattle * 0.010 * s.cond / 100;
    if (s.cond < 25 && m % 3 === 0) addLog(s, 'Animales desnutridos: baja producción y mortalidad. Reduce el hato o mejora el forraje.', 'mal');
    if (overgrazed > 6 && m % 6 === 0) addLog(s, 'Sobrepastoreo en ' + overgrazed + ' potreros: el suelo se compacta y se erosiona.', 'mal');

    // --- Crecimiento de pasto, suelo y árboles ---
    let erosionTot = 0;
    for (const c of L) {
      const shade = c.trees / 100;
      if (c.type === T.PASTO || c.type === T.SILVO || c.type === T.FORRAJE) {
        const moist = Math.min(1.2, rainEff + (rainEff < 1 ? (1 - rainEff) * 0.65 * shade : 0));
        const soilF = 0.4 + 0.8 * c.soil / 100 + (c.fert > 0 ? 0.35 : 0);
        const rest = (c.type !== T.FORRAJE && !grazedIds.has(c.id)) ? 1.2 : 1;
        const rMax = c.type === T.FORRAJE ? 0.65 : c.type === T.SILVO ? 0.5 : 0.55;
        const K = c.type === T.SILVO ? 100 - 0.25 * c.trees : 100;
        c.grass = clamp(c.grass + rMax * moist * soilF * rest * c.grass * (1 - c.grass / K) + 1.0 * moist * soilF, 0, K);
        // erosión: poca cobertura + lluvia + sin sombra
        const eros = c.grass < 35 ? ((35 - c.grass) / 35) * Math.min(rainEff, 1.6) * 0.9 * (1 - 0.6 * shade) : 0;
        erosionTot += eros;
        let gain = 0.25 * shade + (c.grass > 60 ? 0.15 : 0) + (c.type === T.SILVO ? 0.15 : 0);
        if (c.fert > 0) { gain -= 0.5; c.fert--; }
        c.soil = clamp(c.soil - eros + gain, 0, 100);
        // árboles
        if (c.type === T.SILVO) c.trees = Math.min(60, c.trees + 0.9 * (1 - c.trees / 60) + 0.05);
        else c.trees += (3 - c.trees) * 0.05;
      } else if (c.type === T.REGEN) {
        c.trees = Math.min(100, c.trees + 1.4 * (0.5 + c.soil / 100));
        c.soil = clamp(c.soil + 0.3, 0, 100);
        if (c.trees >= 70) { c.type = T.BOSQUE; addLog(s, 'El potrero ' + (c.id + 1) + ' se consolidó como bosque.', 'bien'); }
      } else if (c.type === T.BOSQUE) {
        c.trees = Math.min(100, c.trees + 0.1); c.soil = Math.min(90, c.soil + 0.1);
      }
      if (c.burnt > 0) c.burnt--;
    }

    // --- Agua (cantidad y calidad) ---
    const soilAvg = L.reduce((a, c) => a + c.soil, 0) / L.length;
    const treeAvg = L.reduce((a, c) => a + c.trees, 0) / L.length;
    const rip = L.filter(c => c.ribera), ripTree = rip.reduce((a, c) => a + c.trees, 0) / rip.length;
    const infil = 0.5 * soilAvg / 100 + 0.5 * Math.min(1, treeAvg / 45);
    const targetW = clamp(100 * Math.min(rainEff, 1.3) * (0.35 + 0.65 * infil), 0, 100);
    const buf = 0.5 + 0.4 * infil;
    s.water = buf * s.water + (1 - buf) * targetW;
    const chemShare = L.filter(c => c.fert > 0).length;
    const contam = chemShare * 0.5 + riberaAcceso * 0.25 + erosionTot * 0.15;
    s.wq = clamp(s.wq + 0.6 + 1.6 * ripTree / 100 - contam, 0, 100);

    // --- Biodiversidad (respuesta lenta) y carbono ---
    s.bio += (targetBio(s) - s.bio) * 0.06;
    s.emis += s.cattle * 0.19;
    const stock = L.reduce((a, c) => a + c.trees * 2.4 + c.soil * 0.8, 0);

    // --- Economía ---
    const share = L.filter(c => c.type === T.SILVO || c.type === T.BOSQUE || c.type === T.REGEN).length / L.length;
    const premium = share >= 0.35 ? 1.12 : 1;
    const ingreso = s.cattle * P.ingresoAnimal * Math.pow(s.cond / 100, 1.3) * premium;
    const psa = 0.22 * L.filter(c => c.type === T.BOSQUE || c.type === T.REGEN).length + 0.08 * L.filter(c => c.type === T.SILVO && c.trees >= 25).length;
    const costo = P.costoFijo + P.costoAnimal * s.cattle + (s.suplemento ? P.costoSuplemento * s.cattle : 0);
    s.money += ingreso + psa - costo; s.cumIncome += ingreso + psa;
    s.last = { ingreso, psa, costo, ratio, grassTaken, share, premium };

    s.month++;
    snapshot(s, stock);
    if (s.money < P.quiebra) { s.over = true; s.endReason = 'Quiebra: la deuda superó el límite permitido.'; addLog(s, s.endReason, 'mal'); }
    else if (s.month >= MONTHS) { s.over = true; s.endReason = 'Se cumplieron los 10 años de simulación.'; }
    if (s.over) s.final = evaluar(s);
    return s;
  }

  function metrics(s, stock) {
    const L = land(s);
    const soil = L.reduce((a, c) => a + c.soil, 0) / L.length;
    const trees = L.reduce((a, c) => a + c.trees, 0) / L.length;
    const gp = L.filter(c => c.type === T.PASTO || c.type === T.SILVO);
    const grass = gp.length ? gp.reduce((a, c) => a + c.grass, 0) / gp.length : 0;
    if (stock == null) stock = L.reduce((a, c) => a + c.trees * 2.4 + c.soil * 0.8, 0);
    return { soil, trees, grass, stock, carbonNet: stock - s.emis, forest: L.filter(c => c.type === T.BOSQUE).length };
  }
  function snapshot(s, stock) {
    const k = metrics(s, stock);
    s.history.push({ m: s.month, money: s.money, soil: k.soil, water: s.water, wq: s.wq, bio: s.bio, carbon: k.carbonNet, cattle: s.cattle, grass: k.grass, cond: s.cond, trees: k.trees });
  }

  /* ---------- Evaluación final ---------- */
  function evaluar(s) {
    const k = metrics(s);
    const patrimonio = s.money + s.cattle * P.precioVenta;
    const eco = clamp((patrimonio - 20) / 250, 0, 1) * 100;
    const carbonIdx = clamp((k.carbonNet / 2800) * 50, 0, 100);
    const sost = (k.soil + s.water + s.wq + s.bio + carbonIdx) / 5;
    const total = 0.4 * eco + 0.6 * sost;
    let nivel = total >= 70 ? 'Excelente: finca regenerativa y rentable' : total >= 50 ? 'Bueno: avance hacia la sostenibilidad' : total >= 30 ? 'Regular: el modelo actual es frágil' : 'Crítico: degradación ambiental y económica';
    return { patrimonio, eco, soil: k.soil, water: s.water, wq: s.wq, bio: s.bio, carbonIdx, sost, total, nivel, carbonNet: k.carbonNet };
  }

  function run(s, meses, politica) { // utilidad para pruebas / estrategias automáticas
    for (let i = 0; i < meses && !s.over; i++) { if (politica) politica(s); step(s); }
    return s;
  }

  const api = { COLS, ROWS, MONTHS, T, P, create, step, act, metrics, evaluar, run, land };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.Sim = api;
})(typeof self !== 'undefined' ? self : this);
