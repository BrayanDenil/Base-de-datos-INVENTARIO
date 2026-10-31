-- =============================================================================
-- SCRIPT 04: REPORTES REQUERIDOS
-- =============================================================================
-- Bajo stock
SELECT codigo_barras, nombre_producto, stock_actual, stock_minimo FROM PRODUCTOS WHERE stock_actual <= stock_minimo;

-- Categorias JOIN
SELECT p.nombre_producto, c.nombre_categoria FROM PRODUCTOS p INNER JOIN CATEGORIAS c ON p.id_categoria = c.id_categoria;
