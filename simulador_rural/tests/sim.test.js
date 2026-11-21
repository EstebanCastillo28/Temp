// Pruebas del motor: ejecutar con `node tests/sim.test.js`
const assert = require('assert'); const S = require('../js/sim.js');
let n = 0; const t = (name, fn) => { fn(); n++; console.log('✔', name); };
const silvoRot = s => { if (s.month === 0) { s.cells.filter(c => c.type === 'pasto').slice(0, 5).forEach(c => S.act(s, 'silvo', c.id)); S.act(s, 'pastoreo', 'rotacional'); } };

t('estado inicial válido', () => { const s = S.create(); assert.strictEqual(s.cells.length, 48); assert.strictEqual(s.month, 0); assert(s.money > 0 && s.cattle > 0); });
t('reproducible con la misma semilla', () => { const a = S.run(S.create({ seed: 7 }), 60), b = S.run(S.create({ seed: 7 }), 60); assert.strictEqual(a.money, b.money); });
t('indicadores siempre en rango', () => { const s = S.create(); for (let i = 0; i < 120 && !s.over; i++) { S.step(s); [s.water, s.wq, s.bio, s.cond].forEach(v => assert(v >= 0 && v <= 100 && !isNaN(v))); s.cells.forEach(c => { assert(c.soil >= 0 && c.soil <= 100); assert(c.grass >= 0 && c.grass <= 100); assert(c.trees >= 0 && c.trees <= 100); }); } });
t('sobrepastoreo sin gestión degrada y quiebra', () => { const s = S.run(S.create(), 120); assert(s.over && S.metrics(s).soil < 40); assert(s.final.total < 30); });
t('manejo sostenible supera al tradicional', () => { const a = S.run(S.create(), 120), b = S.run(S.create(), 120, silvoRot); assert(b.final.total > a.final.total + 30); assert(b.final.soil > a.final.soil); assert(b.final.water > a.final.water); assert(b.money > a.money); });
t('sembrar árboles cuesta dinero y cambia el tipo', () => { const s = S.create(); const c = s.cells.find(c => c.type === 'pasto'), m = s.money; assert(S.act(s, 'silvo', c.id).ok); assert.strictEqual(c.type, 'silvo'); assert(s.money < m); });
t('no se puede actuar sin dinero', () => { const s = S.create(); s.money = 0; assert(!S.act(s, 'silvo', s.cells.find(c => c.type === 'pasto').id).ok); });
t('quemar y talar dan beneficio inmediato pero cuestan ambiente', () => { const s = S.create(); const b = s.cells.find(c => c.type === 'bosque'), m = s.money, bio0 = s.bio; S.act(s, 'deforestar', b.id); assert(s.money > m); assert.strictEqual(b.type, 'pasto'); S.run(s, 24); assert(s.bio < bio0); });
t('regeneración consolida bosque', () => { const s = S.create(); const c = s.cells.find(c => c.type === 'pasto'); S.act(s, 'regen', c.id); S.run(s, 60); assert.strictEqual(c.type, 'bosque'); });
t('El Niño reduce el caudal', () => { const s = S.create(); S.run(s, 29); const w0 = s.water; S.run(s, 10); assert(s.water < w0); });
t('vender/comprar animales', () => { const s = S.create(); const c0 = s.cattle; assert(S.act(s, 'vender', 5).ok); assert.strictEqual(s.cattle, c0 - 5); assert(!S.act(s, 'vender', 999).ok); });
console.log('\n' + n + ' pruebas OK');
