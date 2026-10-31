# Manual de Despliegue y Reproducción

## 🔄 Secuencia Crítica de Ejecución de los Scripts
1.  **`sql/01_ddl_crear_base_datos.sql`**: Limpieza previa.
2.  **`sql/02_ddl_crear_tablas.sql`**: Creación física del esquema, índices y triggers automatizados.
3.  **`sql/03_dml_datos_prueba.sql`**: Carga masiva inicial (catálogos, 30+ productos, clientes y transacciones).
4.  **`sql/04_consultas_reportes.sql`**: Ejecución de las consultas analíticas del negocio.
5.  **`sql/05_extras_opcional.sql`**: Vistas adicionales de control operativo.
