-- =============================================================================
-- SCRIPT 02: DDL - TABLAS, ÍNDICES Y TRIGGERS (POSTGRESQL)
-- =============================================================================
DROP VIEW IF EXISTS VISTA_HISTORIAL_CONSOLIDADO CASCADE;
DROP VIEW IF EXISTS VISTA_INVENTARIO_CRITICO CASCADE;
DROP TABLE IF EXISTS MOVIMIENTOS_INVENTARIO CASCADE;
DROP TABLE IF EXISTS DETALLE_FACTURAS CASCADE;
DROP TABLE IF EXISTS FACTURAS CASCADE;
DROP TABLE IF EXISTS DETALLE_COMPRAS CASCADE;
DROP TABLE IF EXISTS COMPRAS CASCADE;
DROP TABLE IF EXISTS PRODUCTOS CASCADE;
DROP TABLE IF EXISTS PROVEEDORES CASCADE;
DROP TABLE IF EXISTS CLIENTES CASCADE;
DROP TABLE IF EXISTS USUARIOS CASCADE;
DROP TABLE IF EXISTS ESTADOS_OPERACION CASCADE;
DROP TABLE IF EXISTS TIPOS_DOCUMENTO CASCADE;
DROP TABLE IF EXISTS FORMAS_PAGO CASCADE;
DROP TABLE IF EXISTS CATEGORIAS CASCADE;
DROP TABLE IF EXISTS ROLES CASCADE;

CREATE TABLE ROLES (id_rol SERIAL PRIMARY KEY, nombre_rol VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE CATEGORIAS (id_categoria SERIAL PRIMARY KEY, nombre_categoria VARCHAR(50) UNIQUE NOT NULL, descripcion VARCHAR(255));
CREATE TABLE FORMAS_PAGO (id_forma_pago SERIAL PRIMARY KEY, nombre_forma_pago VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE TIPOS_DOCUMENTO (id_tipo_documento SERIAL PRIMARY KEY, nombre_tipo VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE ESTADOS_OPERACION (id_estado SERIAL PRIMARY KEY, nombre_estado VARCHAR(50) UNIQUE NOT NULL CHECK (nombre_estado IN ('PENDIENTE', 'PAGADO', 'ANULADO')));

CREATE TABLE USUARIOS (id_usuario SERIAL PRIMARY KEY, nombre_usuario VARCHAR(100) NOT NULL, correo_electronico VARCHAR(100) UNIQUE NOT NULL, id_rol INT NOT NULL REFERENCES ROLES(id_rol));
CREATE TABLE CLIENTES (id_cliente SERIAL PRIMARY KEY, id_tipo_documento INT NOT NULL REFERENCES TIPOS_DOCUMENTO(id_tipo_documento), numero_documento VARCHAR(30) UNIQUE NOT NULL, nombre_cliente VARCHAR(150) NOT NULL, correo_cliente VARCHAR(100) UNIQUE NULL);
CREATE TABLE PROVEEDORES (id_proveedor SERIAL PRIMARY KEY, nit_proveedor VARCHAR(20) UNIQUE NOT NULL, razon_social VARCHAR(150) NOT NULL, telefono VARCHAR(20));
CREATE TABLE PRODUCTOS (id_producto SERIAL PRIMARY KEY, codigo_barras VARCHAR(50) UNIQUE NOT NULL, nombre_producto VARCHAR(100) NOT NULL, id_categoria INT NOT NULL REFERENCES CATEGORIAS(id_categoria), precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario > 0), stock_actual INT NOT NULL CHECK (stock_actual >= 0), stock_minimo INT NOT NULL CHECK (stock_minimo >= 0));

CREATE TABLE COMPRAS (id_compra SERIAL PRIMARY KEY, id_proveedor INT NOT NULL REFERENCES PROVEEDORES(id_proveedor), fecha_compra TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, total NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0), id_estado INT NOT NULL REFERENCES ESTADOS_OPERACION(id_estado));
CREATE TABLE DETALLE_COMPRAS (id_detalle_compra SERIAL PRIMARY KEY, id_compra INT NOT NULL REFERENCES COMPRAS(id_compra) ON DELETE CASCADE, id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto), cantidad INT NOT NULL CHECK (cantidad > 0), precio_costo NUMERIC(12,2) NOT NULL CHECK (precio_costo > 0), subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal > 0), CONSTRAINT uq_detalle_compra_producto UNIQUE (id_compra, id_producto));

CREATE TABLE FACTURAS (id_factura SERIAL PRIMARY KEY, numero_factura_correlativo VARCHAR(50) UNIQUE NOT NULL, id_cliente INT NOT NULL REFERENCES CLIENTES(id_cliente), id_usuario INT NOT NULL REFERENCES USUARIOS(id_usuario), id_forma_pago INT NOT NULL REFERENCES FORMAS_PAGO(id_forma_pago), fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, total NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0), id_estado INT NOT NULL REFERENCES ESTADOS_OPERACION(id_estado));
CREATE TABLE DETALLE_FACTURAS (id_detalle_factura SERIAL PRIMARY KEY, id_factura INT NOT NULL REFERENCES FACTURAS(id_factura) ON DELETE CASCADE, id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto), cantidad INT NOT NULL CHECK (cantidad > 0), precio_venta NUMERIC(12,2) NOT NULL CHECK (precio_venta > 0), subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal > 0), CONSTRAINT uq_detalle_factura_producto UNIQUE (id_factura, id_producto));

CREATE TABLE MOVIMIENTOS_INVENTARIO (id_movimiento SERIAL PRIMARY KEY, id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto), tipo_movimiento VARCHAR(10) NOT NULL CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA')), cantidad INT NOT NULL CHECK (cantidad > 0), fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, id_referencia_origen INT NOT NULL);

CREATE INDEX idx_facturas_fecha_estado ON FACTURAS (fecha_emision, id_estado);
CREATE INDEX idx_compras_fecha_estado ON COMPRAS (fecha_compra, id_estado);
CREATE INDEX idx_detalle_facturas_factura ON DETALLE_FACTURAS (id_factura);
CREATE INDEX idx_detalle_compras_compra ON DETALLE_COMPRAS (id_compra);
CREATE INDEX idx_movimientos_producto_fecha ON MOVIMIENTOS_INVENTARIO (id_producto, fecha_movimiento DESC);

-- TRIGGERS DE VENTA (STOCK Y SUBTONALES)
CREATE OR REPLACE FUNCTION fn_trg_control_stock_venta() RETURNS TRIGGER AS $$
DECLARE v_stock_disp INT;
BEGIN
    NEW.subtotal := NEW.cantidad * NEW.precio_venta;
    SELECT stock_actual INTO v_stock_disp FROM PRODUCTOS WHERE id_producto = NEW.id_producto;
    IF v_stock_disp < NEW.cantidad THEN
        RAISE EXCEPTION 'Existencias insuficientes para el Producto ID %', NEW.id_producto;
    END IF;
    UPDATE PRODUCTOS SET stock_actual = stock_actual - NEW.cantidad WHERE id_producto = NEW.id_producto;
    INSERT INTO MOVIMIENTOS_INVENTARIO (id_producto, tipo_movimiento, cantidad, id_referencia_origen) VALUES (NEW.id_producto, 'SALIDA', NEW.cantidad, NEW.id_factura);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_detalle_factura_alta BEFORE INSERT ON DETALLE_FACTURAS FOR EACH ROW EXECUTE FUNCTION fn_trg_control_stock_venta();

CREATE OR REPLACE FUNCTION fn_trg_calcular_total_factura() RETURNS TRIGGER AS $$
BEGIN
    UPDATE FACTURAS SET total = COALESCE((SELECT SUM(subtotal) FROM DETALLE_FACTURAS WHERE id_factura = COALESCE(NEW.id_factura, OLD.id_factura)), 0) WHERE id_factura = COALESCE(NEW.id_factura, OLD.id_factura);
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER trg_factura_total_actualiza AFTER INSERT OR UPDATE OR DELETE ON DETALLE_FACTURAS FOR EACH ROW EXECUTE FUNCTION fn_trg_calcular_total_factura();
