# Simulador "Finca La Esperanza" — Ganadería sostenible en el sector rural colombiano

Proyecto final · Electiva CMD: Ingeniería y Desarrollo Regional (Uniminuto, 2026-60).

## Ejecutar
Abre `index.html` en el navegador (no requiere servidor ni instalación).

## Pruebas
```bash
node tests/sim.test.js
```

## Estructura
- `index.html`, `css/styles.css` — interfaz
- `js/sim.js` — motor de simulación (reglas y algoritmos)
- `js/app.js` — interacción y gráficas · `js/content.js` — contenido educativo
- `docs/INFORME.md` — investigación, diseño, requerimientos, desarrollo, pruebas y conclusiones

## Despliegue
- **GitHub Pages:** Settings → Pages → Source: *GitHub Actions* (el workflow `.github/workflows/pages.yml` publica la carpeta).
- **Vercel / Netlify:** importar el repositorio, *Root Directory* = `simulador_rural`, sin comando de build.

Autor: Juan Esteban Castillo Baquero (ID 852500).
