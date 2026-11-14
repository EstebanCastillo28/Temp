// Genera el Plan B de la demostración: capturas de pantalla de la app Shiny (el video se arma con ffmpeg a partir de ellas).
// Uso (desde la raíz del proyecto): inicie la app (shiny::runApp("despliegue", port = 3838)) y ejecute
//   NODE_PATH=<node_modules con playwright-core> CHROME=<ruta al chrome> node sustentacion_final/capturar_demo.js
const { chromium } = require("playwright-core");
const path = require("path");
const OUT = path.join(__dirname, "plan_b");
const URL = process.env.APP_URL || "http://127.0.0.1:3838";
const esperar = (ms) => new Promise((r) => setTimeout(r, ms));

async function elegir(page, id, texto) {
  await page.click(`#${id} + .selectize-control .selectize-input`);
  await page.click(`div.selectize-dropdown-content div.option:text-is("${texto}")`);
  await esperar(500);
}
async function caso(page, nombre, archivo, esperarResultado = true) {
  await elegir(page, "ejemplo", nombre);
  await page.click("#go"); await esperar(esperarResultado ? 2500 : 1500);
  await page.screenshot({ path: path.join(OUT, archivo), fullPage: false });
}

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome", args: ["--no-sandbox"] });
  const ctx = await browser.newContext({ viewport: { width: 1366, height: 800 } });
  const page = await ctx.newPage();
  await page.goto(URL); await esperar(3500);
  await page.screenshot({ path: path.join(OUT, "01_inicio.png") });
  await caso(page, "Atropello nocturno (Kennedy)", "02_atropello_nocturno.png");
  await caso(page, "Choque entre dos autos (día hábil)", "03_choque_autos.png");
  await caso(page, "Moto y bus (sábado de madrugada)", "04_moto_bus.png");
  await caso(page, "Caso límite: 25 vehículos", "05_caso_limite.png");
  await caso(page, "Entrada inválida (hora 30, edad -5)", "06_entrada_invalida.png");
  await page.click('a:has-text("Cómo interpretarlo")'); await esperar(1500);
  await page.screenshot({ path: path.join(OUT, "07_como_interpretarlo.png") });
  await page.click('a:has-text("Lote de casos")'); await esperar(1000);
  await page.setInputFiles("#csv", path.join(__dirname, "..", "despliegue", "ejemplos", "casos_ejemplo.csv")); await esperar(3500);
  await page.screenshot({ path: path.join(OUT, "08_lote_csv.png") });
  await ctx.close(); await browser.close();
  console.log("Capturas listas en", OUT, "(el video se arma con ffmpeg a partir de las capturas; ver README)");
})();
