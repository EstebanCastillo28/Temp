# Guion de sustentación (≈ 10–12 min)

1. **Problema (1 min).** Plan Distrital de Seguridad Vial 2023–2032: reducir 50 % las víctimas fatales. Solo 1,5 % de los siniestros son fatales → el evento clave es el más raro; el análisis actual es descriptivo, no anticipa gravedad.
2. **Preguntas e hipótesis (1 min).** H1 actores vulnerables, H2 noche y fin de semana, H3 perfiles de riesgo. Objetivo: clasificar gravedad en 3 clases.
3. **Fuente y selección (2 min).** Consolidado oficial (SINIESTROS, ACTOR_VIAL, VEHICULOS, DICCIONARIO). Qué se descartó y por qué: `HIPOTESIS` (posterior al hecho), `OBJETO_FIJO` (96,6 % de vacíos estructurales), `MODALIDAD` (61 % estructural), `DIRECCION` (solo `via_avenida`).
4. **Decisión clave: fuga de objetivo (2 min).** Los pasajeros solo se registran si resultan lesionados (2 ilesos de 27.365); el `ESTADO` define la gravedad. Se excluyen de los predictores. El peatón se conserva por H1 pero se advierte su relación mecánica con la gravedad.
5. **Limpieza (2 min).**
   * Gravedad inconsistente con víctimas: 175 reconciliados.
   * Edad 118 (282 veces) = centinela; conductores < 10 años; ≥ 110 años → NA.
   * 148 siniestros sin detalle eliminados; 58 duplicados semánticos.
   * Faltantes: la mayoría estructurales; la edad es MAR y además **informativa** (6,3 % vs 1,5 % de fatales; 65 % de esos casos tienen un vehículo en fuga) → mediana de Train + indicador `edad_imputada`.
   * Outliers: IQR inservible en conteos (marca el 22 %) → winsorización P99,5 de Train en conteos, se conservan edades altas plausibles.
6. **Transformación (1,5 min).** Variables derivadas (franja, festivos de Colombia, hora cíclica, vulnerables, heterogeneidad Gini-Simpson, mezcla vulnerable × pesado), one-hot k−1 con categorías raras agrupadas, Z-score, PCA (7 componentes ≥ 95 %). Antes/después en figuras 1–3.
7. **Anti-fuga (1 min).** Partición estratificada 70/30 con semilla; parámetros solo de Train, guardados en `.rds`; función idempotente; 4 pruebas automáticas dentro del informe.
8. **Hallazgos exploratorios y limitaciones (1 min).** Noche 26,9 ‰ vs día 12,2 ‰; peatón 68 ‰ vs 1,2 ‰ sin vulnerables. Limitaciones: datos hasta 2020 (pandemia), sin exposición, subregistro.
9. **Próximos pasos.** 3 clasificadores con validación cruzada y manejo del desbalance solo en Train, clustering sobre PCA, SHAP, despliegue en Plumber/Shiny reutilizando `parametros_transformacion.rds`.

**Preguntas probables:** ¿por qué no imputar con KNN? (faltante < 1 %, señal informativa); ¿por qué no eliminar atípicos? (son eventos reales); ¿cómo evitan la fuga? (Train-only + idempotencia + pruebas); ¿por qué se reclasificó la gravedad? (la evidencia a nivel de víctima es la fuente primaria).
