# Diccionario de Datos Exhaustivo

### 1. Tabla: CATEGORIAS
*   `id_categoria` (SERIAL, PK): Identificador único secuencial y llave primaria de la categoría.
*   `nombre_categoria` (VARCHAR(50), UNIQUE, NOT NULL): Nombre descriptivo de la agrupación.
*   `descripcion` (VARCHAR(255), NULL): Detalles sobre la categoría.

### 2. Tabla: PROVEEDORES
*   `id_proveedor` (SERIAL, PK): Identificador único secuencial y llave primaria del proveedor.
*   `nit_proveedor` (VARCHAR(20), UNIQUE, NOT NULL): Número de Identificación Tributaria oficial.
*   `razon_social` (VARCHAR(150), NOT NULL): Nombre legal de la empresa.
*   `telefono` (VARCHAR(20), NULL): Número telefónico.

### 3. Tabla: CLIENTES
*   `id_cliente` (SERIAL, PK): Identificador único secuencial.
*   `id_tipo_documento` (INT, FK -> TIPOS_DOCUMENTO).
*   `numero_documento` (VARCHAR(30), UNIQUE, NOT NULL).
*   `nombre_cliente` (VARCHAR(150), NOT NULL).
*   `correo_cliente` (VARCHAR(100), UNIQUE, NULL).

### 4. Tabla: PRODUCTOS
*   `id_producto` (SERIAL, PK).
*   `codigo_barras` (VARCHAR(50), UNIQUE, NOT NULL).
*   `nombre_producto` (VARCHAR(100), NOT NULL).
*   `id_categoria` (INT, FK -> CATEGORIAS).
*   `precio_unitario` (NUMERIC(12,2), NOT NULL CHECK > 0).
*   `stock_actual` (INT, NOT NULL CHECK >= 0).
*   `stock_minimo` (INT, NOT NULL CHECK >= 0).

### 5. Tabla: FACTURAS (Encabezado)
*   `id_factura` (SERIAL, PK).
*   `numero_factura_correlativo` (VARCHAR(50), UNIQUE, NOT NULL).
*   `id_cliente` (INT, FK -> CLIENTES).
*   `id_usuario` (INT, FK -> USUARIOS).
*   `id_forma_pago` (INT, FK -> FORMAS_PAGO).
*   `fecha_emision` (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP).
*   `total` (NUMERIC(12,2), DEFAULT 0).
*   `id_estado` (INT, FK -> ESTADOS_OPERACION).

### 6. Tabla: DETALLE_FACTURAS (Tabla Puente / Relación M:N)
*   `id_detalle_factura` (SERIAL, PK).
*   `id_factura` (INT, FK -> FACTURAS ON DELETE CASCADE).
*   `id_producto` (INT, FK -> PRODUCTOS).
*   `cantidad` (INT, CHECK > 0).
*   `precio_venta` (NUMERIC(12,2), CHECK > 0).
*   `subtotal` (NUMERIC(12,2), CHECK > 0).
