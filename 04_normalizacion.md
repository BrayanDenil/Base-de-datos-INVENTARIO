# Evidencia Analítica de Normalización (Hasta 3FN)

## 1. Primera Forma Normal (1FN)
*   **Atomicidad total:** Cada intersección almacena un único valor simple. No existen listas ni arreglos.
*   Se eliminaron grupos repetitivos llevando las líneas a filas verticales en `DETALLE_FACTURAS`.

## 2. Segunda Forma Normal (2FN)
*   Cumple con la 1FN.
*   **Dependencia Funcional Completa:** Los atributos no clave dependen de la clave primaria completa (y de ambas claves compuestas en las tablas puente).

## 3. Tercera Forma Normal (3FN)
*   Cumple con la 2FN.
*   **Sin Dependencias Transitivas:** Ningún campo no clave depende de forma indirecta de la PK. Los catálogos están correctamente desacoplados en tablas independientes (`CATEGORIAS`, `PROVEEDORES`, `ROLES`).
