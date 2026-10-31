

CREATE DATABASE control_inventario WITH TEMPLATE = template0;

-- =============================================================================
-- 0. LIMPIEZA PREVIA
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

DROP PROCEDURE IF EXISTS prc_registrar_factura(VARCHAR, INT, INT, INT, INT, INT);
DROP PROCEDURE IF EXISTS prc_registrar_compra(INT, INT, INT, NUMERIC);

DROP FUNCTION IF EXISTS fn_trg_calcular_total_factura() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_calcular_total_compra() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_control_stock_preventivo() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_control_stock_venta() CASCADE;
DROP FUNCTION IF EXISTS fn_trg_control_stock_compra() CASCADE;

-- =============================================================================
-- 1. ESTRUCTURA FÍSICA (DDL)
-- =============================================================================

-- Catálogos
CREATE TABLE ROLES (
    id_rol SERIAL PRIMARY KEY,
    nombre_rol VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE CATEGORIAS (
    id_categoria SERIAL PRIMARY KEY,
    nombre_categoria VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE FORMAS_PAGO (
    id_forma_pago SERIAL PRIMARY KEY,
    nombre_forma_pago VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE TIPOS_DOCUMENTO (
    id_tipo_documento SERIAL PRIMARY KEY,
    nombre_tipo VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE ESTADOS_OPERACION (
    id_estado SERIAL PRIMARY KEY,
    nombre_estado VARCHAR(50) UNIQUE NOT NULL,
    CONSTRAINT chk_estados_permitidos
        CHECK (nombre_estado IN ('PENDIENTE', 'PAGADO', 'ANULADO'))
);

-- Entidades maestras
CREATE TABLE USUARIOS (
    id_usuario SERIAL PRIMARY KEY,
    nombre_usuario VARCHAR(100) NOT NULL,
    correo_electronico VARCHAR(100) UNIQUE NOT NULL,
    id_rol INT NOT NULL REFERENCES ROLES(id_rol)
);

CREATE TABLE CLIENTES (
    id_cliente SERIAL PRIMARY KEY,
    id_tipo_documento INT NOT NULL REFERENCES TIPOS_DOCUMENTO(id_tipo_documento),
    numero_documento VARCHAR(30) UNIQUE NOT NULL,
    nombre_cliente VARCHAR(150) NOT NULL,
    correo_cliente VARCHAR(100) UNIQUE NULL
);

CREATE TABLE PROVEEDORES (
    id_proveedor SERIAL PRIMARY KEY,
    nit_proveedor VARCHAR(20) UNIQUE NOT NULL,
    razon_social VARCHAR(150) NOT NULL,
    telefono VARCHAR(20) NULL
);

CREATE TABLE PRODUCTOS (
    id_producto SERIAL PRIMARY KEY,
    codigo_barras VARCHAR(50) UNIQUE NOT NULL,
    nombre_producto VARCHAR(100) NOT NULL,
    id_categoria INT NOT NULL REFERENCES CATEGORIAS(id_categoria),
    precio_unitario NUMERIC(12,2) NOT NULL CHECK (precio_unitario > 0),
    stock_actual INT NOT NULL CHECK (stock_actual >= 0),
    stock_minimo INT NOT NULL CHECK (stock_minimo >= 0)
);

-- Operaciones transaccionales
CREATE TABLE COMPRAS (
    id_compra SERIAL PRIMARY KEY,
    id_proveedor INT NOT NULL REFERENCES PROVEEDORES(id_proveedor),
    fecha_compra TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    id_estado INT NOT NULL REFERENCES ESTADOS_OPERACION(id_estado)
);

CREATE TABLE DETALLE_COMPRAS (
    id_detalle_compra SERIAL PRIMARY KEY,
    id_compra INT NOT NULL REFERENCES COMPRAS(id_compra) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_costo NUMERIC(12,2) NOT NULL CHECK (precio_costo > 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal > 0),
    CONSTRAINT uq_detalle_compra_producto UNIQUE (id_compra, id_producto)
);

CREATE TABLE FACTURAS (
    id_factura SERIAL PRIMARY KEY,
    numero_factura_correlativo VARCHAR(50) UNIQUE NOT NULL,
    id_cliente INT NOT NULL REFERENCES CLIENTES(id_cliente),
    id_usuario INT NOT NULL REFERENCES USUARIOS(id_usuario),
    id_forma_pago INT NOT NULL REFERENCES FORMAS_PAGO(id_forma_pago),
    fecha_emision TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
    id_estado INT NOT NULL REFERENCES ESTADOS_OPERACION(id_estado)
);

CREATE TABLE DETALLE_FACTURAS (
    id_detalle_factura SERIAL PRIMARY KEY,
    id_factura INT NOT NULL REFERENCES FACTURAS(id_factura) ON DELETE CASCADE,
    id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    precio_venta NUMERIC(12,2) NOT NULL CHECK (precio_venta > 0),
    subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal > 0),
    CONSTRAINT uq_detalle_factura_producto UNIQUE (id_factura, id_producto)
);

-- Kárdex. El tipo de referencia se conserva como entero para mantener
-- compatibilidad con el diseño original; el origen se identifica por tipo.
CREATE TABLE MOVIMIENTOS_INVENTARIO (
    id_movimiento SERIAL PRIMARY KEY,
    id_producto INT NOT NULL REFERENCES PRODUCTOS(id_producto),
    tipo_movimiento VARCHAR(10) NOT NULL CHECK (tipo_movimiento IN ('ENTRADA', 'SALIDA')),
    cantidad INT NOT NULL CHECK (cantidad > 0),
    fecha_movimiento TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_referencia_origen INT NOT NULL
);

CREATE INDEX idx_facturas_fecha_estado ON FACTURAS (fecha_emision, id_estado);
CREATE INDEX idx_compras_fecha_estado ON COMPRAS (fecha_compra, id_estado);
CREATE INDEX idx_detalle_facturas_factura ON DETALLE_FACTURAS (id_factura);
CREATE INDEX idx_detalle_compras_compra ON DETALLE_COMPRAS (id_compra);
CREATE INDEX idx_movimientos_producto_fecha
    ON MOVIMIENTOS_INVENTARIO (id_producto, fecha_movimiento DESC);

-- =============================================================================
-- 2. DATOS DE PRUEBA
-- =============================================================================

INSERT INTO ROLES (nombre_rol) VALUES
('Administrador'), ('Vendedor'), ('Cajero'), ('Supervisor'), ('Auditor');

INSERT INTO CATEGORIAS (nombre_categoria) VALUES
('Lubricantes'), ('Llantas'), ('Baterías'), ('Frenos'), ('Filtros'), ('Motor');

INSERT INTO FORMAS_PAGO (nombre_forma_pago) VALUES
('Efectivo'), ('Tarjeta de Crédito'), ('Tarjeta de Débito'), ('Transferencia'), ('Cheque');

INSERT INTO TIPOS_DOCUMENTO (nombre_tipo) VALUES
('NIT'), ('DPI'), ('Pasaporte'), ('Extranjero'), ('Consumidor Final');

INSERT INTO ESTADOS_OPERACION (nombre_estado) VALUES
('PENDIENTE'), ('PAGADO'), ('ANULADO');

INSERT INTO USUARIOS (nombre_usuario, correo_electronico, id_rol) VALUES
('Carlos Gómez', 'carlos@mail.com', 1),
('Ana Pérez', 'ana@mail.com', 2),
('Luis Mérida', 'luis@mail.com', 3),
('Marta Vega', 'marta@mail.com', 4),
('Jorge Ruiz', 'jorge@mail.com', 5),
('Sofia Paz', 'sofia@mail.com', 2),
('Pedro Lyon', 'pedro@mail.com', 3),
('Elena Cruz', 'elena@mail.com', 2),
('Ramiro Sol', 'ramiro@mail.com', 2),
('Lucia Díaz', 'lucia@mail.com', 3),
('Hugo Mora', 'hugo@mail.com', 1),
('Mario King', 'mario@mail.com', 4),
('Olga Soto', 'olga@mail.com', 2),
('David Gil', 'david@mail.com', 3),
('Iris Roca', 'iris@mail.com', 2);

INSERT INTO CLIENTES (id_tipo_documento, numero_documento, nombre_cliente, correo_cliente) VALUES
(1, '982734-1', 'Talleres Centeno', 'centeno@mail.com'),
(2, '2345678900101', 'Juan Marroquín', 'juan@mail.com'),
(1, '129384-K', 'Inversiones Globales', 'global@mail.com'),
(5, 'CF-1002', 'Consumidor Final A', NULL),
(2, '3456789010202', 'María Andrade', 'maria@mail.com'),
(1, '774635-2', 'Logística Express', 'log@mail.com'),
(2, '4567890120303', 'Roberto Sosa', 'roberto@mail.com'),
(2, '5678901230404', 'Carmen Ortiz', 'carmen@mail.com'),
(1, '883746-5', 'Rentacar S.A.', 'renta@mail.com'),
(5, 'CF-1003', 'Consumidor Final B', NULL),
(2, '6789012340505', 'Julio Estévez', 'julio@mail.com'),
(2, '7890123450606', 'Dina Méndez', 'dina@mail.com'),
(1, '443526-7', 'Distribuidora Alfa', 'alfa@mail.com'),
(2, '8901234560707', 'Arturo Prat', 'arturo@mail.com'),
(1, '554637-8', 'Constructora Beta', 'beta@mail.com');

INSERT INTO PROVEEDORES (nit_proveedor, razon_social, telefono) VALUES
('1111-1', 'Corporación Shell Guatemala', '22001100'),
('2222-2', 'Llantas del Atlántico', '23002200'),
('3333-3', 'Baterías Willard S.A.', '24003300'),
('4444-4', 'Frenos Seguros S.A.', '25004400'),
('5555-5', 'Filtros Web S.A.', '26005500'),
('6666-6', 'Repuestos El Amigo', '27006600'),
('7777-7', 'Motores de Centroamérica', '28007700'),
('8888-8', 'MultiPartes S.A.', '29008800'),
('9999-9', 'Importadora El Sol', '30009900'),
('1010-1', 'TecnoFrenos', '31001010'),
('1212-2', 'Lubricantes Premium', '32001212'),
('1313-3', 'Hilos e Inyecciones', '33001313'),
('1414-4', 'Acumuladores Iberia', '34001414'),
('1515-5', 'Cauchos Industriales', '35001515'),
('1616-6', 'AutoPartes Tuercas', '36001616');

-- Corrección: todos los productos están en una sola sentencia INSERT.
INSERT INTO PRODUCTOS
(codigo_barras, nombre_producto, id_categoria, precio_unitario, stock_actual, stock_minimo)
VALUES
('P001', 'Aceite Helix 20W50 1GL', 1, 185.00, 50, 10),
('P002', 'Llanta Rin 15 Michelin', 2, 650.00, 4, 8),
('P003', 'Batería Magna 12V V6', 3, 780.00, 12, 5),
('P004', 'Pastillas de Freno Delanteras', 4, 220.00, 2, 5),
('P005', 'Filtro de Aceite Universal', 5, 45.00, 100, 20),
('P006', 'Filtro de Aire Deportivo', 5, 115.00, 15, 10),
('P007', 'Líquido de Frenos Dot4', 4, 35.00, 40, 15),
('P008', 'Batería Bosch Recargable', 3, 950.00, 1, 4),
('P009', 'Llanta Rin 14 Bridgestone', 2, 480.00, 25, 6),
('P010', 'Aceite Sintético 5W30 1GL', 1, 320.00, 30, 8),
('P011', 'Bomba de Agua Motor 1.6', 6, 425.00, 8, 3),
('P012', 'Faja de Tiempo Gates', 6, 175.00, 14, 5),
('P013', 'Discos de Freno Ventilados', 4, 550.00, 6, 4),
('P014', 'Candelas de Iridium (Set 4)', 6, 240.00, 3, 8),
('P015', 'Aditivo de Combustible', 1, 60.00, 80, 15);

-- =============================================================================
-- 3. FUNCIONES Y TRIGGERS
-- =============================================================================

-- Recalcular total de factura. En UPDATE de id_factura recalcula ambos encabezados.
CREATE OR REPLACE FUNCTION fn_trg_calcular_total_factura()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE FACTURAS f
           SET total = COALESCE(
               (SELECT SUM(df.subtotal)
                  FROM DETALLE_FACTURAS df
                 WHERE df.id_factura = OLD.id_factura), 0)
         WHERE f.id_factura = OLD.id_factura;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE FACTURAS f
           SET total = COALESCE(
               (SELECT SUM(df.subtotal)
                  FROM DETALLE_FACTURAS df
                 WHERE df.id_factura = OLD.id_factura), 0)
         WHERE f.id_factura = OLD.id_factura;

        IF NEW.id_factura IS DISTINCT FROM OLD.id_factura THEN
            UPDATE FACTURAS f
               SET total = COALESCE(
                   (SELECT SUM(df.subtotal)
                      FROM DETALLE_FACTURAS df
                     WHERE df.id_factura = NEW.id_factura), 0)
             WHERE f.id_factura = NEW.id_factura;
        END IF;
        RETURN NEW;
    ELSE
        UPDATE FACTURAS f
           SET total = COALESCE(
               (SELECT SUM(df.subtotal)
                  FROM DETALLE_FACTURAS df
                 WHERE df.id_factura = NEW.id_factura), 0)
         WHERE f.id_factura = NEW.id_factura;
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trg_total_factura
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_FACTURAS
FOR EACH ROW EXECUTE FUNCTION fn_trg_calcular_total_factura();

CREATE OR REPLACE FUNCTION fn_trg_calcular_total_compra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE COMPRAS c
           SET total = COALESCE(
               (SELECT SUM(dc.subtotal)
                  FROM DETALLE_COMPRAS dc
                 WHERE dc.id_compra = OLD.id_compra), 0)
         WHERE c.id_compra = OLD.id_compra;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        UPDATE COMPRAS c
           SET total = COALESCE(
               (SELECT SUM(dc.subtotal)
                  FROM DETALLE_COMPRAS dc
                 WHERE dc.id_compra = OLD.id_compra), 0)
         WHERE c.id_compra = OLD.id_compra;

        IF NEW.id_compra IS DISTINCT FROM OLD.id_compra THEN
            UPDATE COMPRAS c
               SET total = COALESCE(
                   (SELECT SUM(dc.subtotal)
                      FROM DETALLE_COMPRAS dc
                     WHERE dc.id_compra = NEW.id_compra), 0)
             WHERE c.id_compra = NEW.id_compra;
        END IF;
        RETURN NEW;
    ELSE
        UPDATE COMPRAS c
           SET total = COALESCE(
               (SELECT SUM(dc.subtotal)
                  FROM DETALLE_COMPRAS dc
                 WHERE dc.id_compra = NEW.id_compra), 0)
         WHERE c.id_compra = NEW.id_compra;
        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trg_total_compra
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_COMPRAS
FOR EACH ROW EXECUTE FUNCTION fn_trg_calcular_total_compra();

-- Validación de stock y movimiento de Kárdex para INSERT/UPDATE/DELETE de detalle.
-- Los procedimientos almacenados no deben volver a registrar el movimiento.
-- Para mantener el stock correcto en operaciones directas sobre detalles, el trigger
-- también aplica la diferencia de inventario. En UPDATE/DELETE se revierte el efecto
-- anterior antes de aplicar el nuevo.
CREATE OR REPLACE FUNCTION fn_trg_control_stock_venta()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_delta INT;
    v_stock INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Bloqueo de la fila del producto para evitar sobreventas concurrentes.
        SELECT stock_actual INTO v_stock
          FROM PRODUCTOS
         WHERE id_producto = NEW.id_producto
         FOR UPDATE;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No existe el producto ID %.', NEW.id_producto;
        END IF;

        IF v_stock < NEW.cantidad THEN
            RAISE EXCEPTION
                'Stock insuficiente para producto ID %. Solicitado: %, disponible: %.',
                NEW.id_producto, NEW.cantidad, v_stock;
        END IF;

        UPDATE PRODUCTOS
           SET stock_actual = stock_actual - NEW.cantidad
         WHERE id_producto = NEW.id_producto;

        INSERT INTO MOVIMIENTOS_INVENTARIO
            (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
        VALUES (NEW.id_producto, 'SALIDA', NEW.cantidad, NEW.id_factura);

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- Devolver al inventario la cantidad de la línea eliminada.
        UPDATE PRODUCTOS
           SET stock_actual = stock_actual + OLD.cantidad
         WHERE id_producto = OLD.id_producto;

        INSERT INTO MOVIMIENTOS_INVENTARIO
            (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
        VALUES (OLD.id_producto, 'ENTRADA', OLD.cantidad, OLD.id_factura);

        RETURN OLD;

    ELSE
        -- Revertir la línea anterior; si cambia de producto, bloquear ambos productos
        -- en orden ascendente para reducir el riesgo de deadlocks.
        IF OLD.id_producto = NEW.id_producto THEN
            v_delta := NEW.cantidad - OLD.cantidad;

            IF v_delta > 0 THEN
                SELECT stock_actual INTO v_stock
                  FROM PRODUCTOS
                 WHERE id_producto = NEW.id_producto
                 FOR UPDATE;

                IF v_stock < v_delta THEN
                    RAISE EXCEPTION
                        'Stock insuficiente para actualizar producto ID %. Adicional requerido: %, disponible: %.',
                        NEW.id_producto, v_delta, v_stock;
                END IF;
            END IF;

            UPDATE PRODUCTOS
               SET stock_actual = stock_actual - v_delta
             WHERE id_producto = NEW.id_producto;

            IF v_delta > 0 THEN
                INSERT INTO MOVIMIENTOS_INVENTARIO
                    (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
                VALUES (NEW.id_producto, 'SALIDA', v_delta, NEW.id_factura);
            ELSIF v_delta < 0 THEN
                INSERT INTO MOVIMIENTOS_INVENTARIO
                    (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
                VALUES (NEW.id_producto, 'ENTRADA', ABS(v_delta), NEW.id_factura);
            END IF;
        ELSE
            -- Devolver el stock de la línea anterior.
            UPDATE PRODUCTOS
               SET stock_actual = stock_actual + OLD.cantidad
             WHERE id_producto = OLD.id_producto;

            SELECT stock_actual INTO v_stock
              FROM PRODUCTOS
             WHERE id_producto = NEW.id_producto
             FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'No existe el producto ID %.', NEW.id_producto;
            END IF;

            IF v_stock < NEW.cantidad THEN
                RAISE EXCEPTION
                    'Stock insuficiente para producto ID %. Solicitado: %, disponible: %.',
                    NEW.id_producto, NEW.cantidad, v_stock;
            END IF;

            UPDATE PRODUCTOS
               SET stock_actual = stock_actual - NEW.cantidad
             WHERE id_producto = NEW.id_producto;

            INSERT INTO MOVIMIENTOS_INVENTARIO
                (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
            VALUES
                (OLD.id_producto, 'ENTRADA', OLD.cantidad, OLD.id_factura),
                (NEW.id_producto, 'SALIDA', NEW.cantidad, NEW.id_factura);
        END IF;

        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trg_control_stock_venta
BEFORE INSERT OR UPDATE OR DELETE ON DETALLE_FACTURAS
FOR EACH ROW EXECUTE FUNCTION fn_trg_control_stock_venta();

-- En compras, las cantidades de detalle también mantienen el stock y el Kárdex.
CREATE OR REPLACE FUNCTION fn_trg_control_stock_compra()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_delta INT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE PRODUCTOS
           SET stock_actual = stock_actual + NEW.cantidad
         WHERE id_producto = NEW.id_producto;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'No existe el producto ID %.', NEW.id_producto;
        END IF;

        INSERT INTO MOVIMIENTOS_INVENTARIO
            (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
        VALUES (NEW.id_producto, 'ENTRADA', NEW.cantidad, NEW.id_compra);

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        -- No permitir que la eliminación de un detalle deje stock negativo.
        UPDATE PRODUCTOS
           SET stock_actual = stock_actual - OLD.cantidad
         WHERE id_producto = OLD.id_producto
           AND stock_actual >= OLD.cantidad;

        IF NOT FOUND THEN
            RAISE EXCEPTION
                'No se puede eliminar el detalle de compra: el stock actual del producto ID % no permite revertir la entrada.',
                OLD.id_producto;
        END IF;

        INSERT INTO MOVIMIENTOS_INVENTARIO
            (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
        VALUES (OLD.id_producto, 'SALIDA', OLD.cantidad, OLD.id_compra);

        RETURN OLD;

    ELSE
        IF OLD.id_producto = NEW.id_producto THEN
            v_delta := NEW.cantidad - OLD.cantidad;

            IF v_delta > 0 THEN
                UPDATE PRODUCTOS
                   SET stock_actual = stock_actual + v_delta
                 WHERE id_producto = NEW.id_producto;

                INSERT INTO MOVIMIENTOS_INVENTARIO
                    (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
                VALUES (NEW.id_producto, 'ENTRADA', v_delta, NEW.id_compra);
            ELSIF v_delta < 0 THEN
                UPDATE PRODUCTOS
                   SET stock_actual = stock_actual - ABS(v_delta)
                 WHERE id_producto = NEW.id_producto
                   AND stock_actual >= ABS(v_delta);

                IF NOT FOUND THEN
                    RAISE EXCEPTION
                        'No se puede reducir la compra: stock insuficiente para revertir % unidades del producto ID %.',
                        ABS(v_delta), NEW.id_producto;
                END IF;

                INSERT INTO MOVIMIENTOS_INVENTARIO
                    (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
                VALUES (NEW.id_producto, 'SALIDA', ABS(v_delta), NEW.id_compra);
            END IF;
        ELSE
            UPDATE PRODUCTOS
               SET stock_actual = stock_actual - OLD.cantidad
             WHERE id_producto = OLD.id_producto
               AND stock_actual >= OLD.cantidad;

            IF NOT FOUND THEN
                RAISE EXCEPTION
                    'No se puede cambiar el producto del detalle: stock insuficiente para revertir producto ID %.',
                    OLD.id_producto;
            END IF;

            UPDATE PRODUCTOS
               SET stock_actual = stock_actual + NEW.cantidad
             WHERE id_producto = NEW.id_producto;

            INSERT INTO MOVIMIENTOS_INVENTARIO
                (id_producto, tipo_movimiento, cantidad, id_referencia_origen)
            VALUES
                (OLD.id_producto, 'SALIDA', OLD.cantidad, OLD.id_compra),
                (NEW.id_producto, 'ENTRADA', NEW.cantidad, NEW.id_compra);
        END IF;

        RETURN NEW;
    END IF;
END;
$$;

CREATE TRIGGER trg_control_stock_compra
BEFORE INSERT OR UPDATE OR DELETE ON DETALLE_COMPRAS
FOR EACH ROW EXECUTE FUNCTION fn_trg_control_stock_compra();

-- =============================================================================
-- 4. VISTAS
-- =============================================================================

CREATE OR REPLACE VIEW VISTA_HISTORIAL_CONSOLIDADO AS
SELECT
    'COMPRA A PROVEEDOR'::TEXT AS tipo_operacion,
    p.razon_social AS entidad_nombre,
    COUNT(DISTINCT c.id_compra) AS cantidad_transacciones,
    COALESCE(SUM(c.total), 0)::NUMERIC(12,2) AS monto_total_acumulado
FROM PROVEEDORES p
LEFT JOIN COMPRAS c
    ON c.id_proveedor = p.id_proveedor
   AND c.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
GROUP BY p.id_proveedor, p.razon_social

UNION ALL

SELECT
    'VENTA A CLIENTE'::TEXT AS tipo_operacion,
    cl.nombre_cliente AS entidad_nombre,
    COUNT(DISTINCT f.id_factura) AS cantidad_transacciones,
    COALESCE(SUM(f.total), 0)::NUMERIC(12,2) AS monto_total_acumulado
FROM CLIENTES cl
LEFT JOIN FACTURAS f
    ON f.id_cliente = cl.id_cliente
   AND f.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
GROUP BY cl.id_cliente, cl.nombre_cliente;

CREATE OR REPLACE VIEW VISTA_INVENTARIO_CRITICO AS
SELECT
    p.id_producto,
    p.codigo_barras,
    p.nombre_producto,
    cat.nombre_categoria,
    p.stock_actual,
    p.stock_minimo,
    GREATEST(p.stock_minimo - p.stock_actual, 0) AS cantidad_a_reabastecer
FROM PRODUCTOS p
JOIN CATEGORIAS cat ON cat.id_categoria = p.id_categoria
WHERE p.stock_actual <= p.stock_minimo;

-- =============================================================================
-- 5. PROCEDIMIENTOS ALMACENADOS
-- =============================================================================

CREATE OR REPLACE PROCEDURE prc_registrar_factura(
    p_correlativo VARCHAR,
    p_id_cliente INT,
    p_id_usuario INT,
    p_id_forma_pago INT,
    p_id_producto INT,
    p_cantidad INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_factura INT;
    v_precio_venta NUMERIC(12,2);
    v_subtotal NUMERIC(12,2);
    v_id_estado_pagado INT;
    v_stock INT;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad a facturar debe ser mayor que cero.';
    END IF;

    SELECT id_estado INTO v_id_estado_pagado
      FROM ESTADOS_OPERACION
     WHERE nombre_estado = 'PAGADO';

    IF v_id_estado_pagado IS NULL THEN
        RAISE EXCEPTION 'No existe el estado PAGADO en ESTADOS_OPERACION.';
    END IF;

    -- Bloquear y validar el producto antes de crear el encabezado.
    SELECT precio_unitario, stock_actual
      INTO v_precio_venta, v_stock
      FROM PRODUCTOS
     WHERE id_producto = p_id_producto
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No existe el producto ID %.', p_id_producto;
    END IF;

    IF v_stock < p_cantidad THEN
        RAISE EXCEPTION
            'Stock insuficiente para producto ID %. Solicitado: %, disponible: %.',
            p_id_producto, p_cantidad, v_stock;
    END IF;

    v_subtotal := ROUND(v_precio_venta * p_cantidad, 2);

    INSERT INTO FACTURAS
        (numero_factura_correlativo, id_cliente, id_usuario, id_forma_pago, total, id_estado)
    VALUES
        (p_correlativo, p_id_cliente, p_id_usuario, p_id_forma_pago, 0, v_id_estado_pagado)
    RETURNING id_factura INTO v_id_factura;

    -- El trigger del detalle descuenta el stock y registra una salida en Kárdex.
    INSERT INTO DETALLE_FACTURAS
        (id_factura, id_producto, cantidad, precio_venta, subtotal)
    VALUES
        (v_id_factura, p_id_producto, p_cantidad, v_precio_venta, v_subtotal);

    RAISE NOTICE 'Factura % creada correctamente. ID: %, total: %.',
        p_correlativo, v_id_factura, v_subtotal;
END;
$$;

CREATE OR REPLACE PROCEDURE prc_registrar_compra(
    p_id_proveedor INT,
    p_id_producto INT,
    p_cantidad INT,
    p_precio_costo NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_compra INT;
    v_subtotal NUMERIC(12,2);
    v_id_estado_pagado INT;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE EXCEPTION 'La cantidad comprada debe ser mayor que cero.';
    END IF;

    IF p_precio_costo IS NULL OR p_precio_costo <= 0 THEN
        RAISE EXCEPTION 'El precio de costo debe ser mayor que cero.';
    END IF;

    SELECT id_estado INTO v_id_estado_pagado
      FROM ESTADOS_OPERACION
     WHERE nombre_estado = 'PAGADO';

    IF v_id_estado_pagado IS NULL THEN
        RAISE EXCEPTION 'No existe el estado PAGADO en ESTADOS_OPERACION.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM PRODUCTOS WHERE id_producto = p_id_producto) THEN
        RAISE EXCEPTION 'No existe el producto ID %.', p_id_producto;
    END IF;

    v_subtotal := ROUND(p_precio_costo * p_cantidad, 2);

    INSERT INTO COMPRAS (id_proveedor, total, id_estado)
    VALUES (p_id_proveedor, 0, v_id_estado_pagado)
    RETURNING id_compra INTO v_id_compra;

    -- El trigger del detalle incrementa el stock y registra entrada en Kárdex.
    INSERT INTO DETALLE_COMPRAS
        (id_compra, id_producto, cantidad, precio_costo, subtotal)
    VALUES
        (v_id_compra, p_id_producto, p_cantidad, p_precio_costo, v_subtotal);

    RAISE NOTICE 'Compra registrada correctamente. ID: %, producto: %, unidades: %.',
        v_id_compra, p_id_producto, p_cantidad;
END;
$$;

-- =============================================================================
-- 6. REPORTES
-- =============================================================================

-- 6.1 Top 5 de productos más vendidos en un período.
-- Parámetros de ejemplo: desde 2026-01-01 inclusive hasta 2027-01-01 exclusive.
SELECT
    p.id_producto,
    p.codigo_barras,
    p.nombre_producto,
    SUM(df.cantidad) AS volumen_total_vendido,
    SUM(df.subtotal) AS monto_total_generado,
    MAX(df.precio_venta) AS precio_maximo_vendido,
    MIN(df.precio_venta) AS precio_minimo_vendido
FROM DETALLE_FACTURAS df
JOIN PRODUCTOS p ON p.id_producto = df.id_producto
JOIN FACTURAS f ON f.id_factura = df.id_factura
WHERE f.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
  AND f.fecha_emision >= TIMESTAMP '2026-01-01 00:00:00'
  AND f.fecha_emision <  TIMESTAMP '2027-01-01 00:00:00'
GROUP BY p.id_producto, p.codigo_barras, p.nombre_producto
ORDER BY volumen_total_vendido DESC, p.nombre_producto
LIMIT 5;

-- 6.2 Reporte consolidado por cliente.
SELECT
    cl.id_cliente,
    cl.numero_documento,
    cl.nombre_cliente,
    COUNT(f.id_factura) AS frecuencia_de_compra,
    COALESCE(SUM(f.total), 0) AS total_acumulado_gastado,
    ROUND(AVG(f.total), 2) AS promedio_de_compra_por_ticket
FROM CLIENTES cl
JOIN FACTURAS f ON f.id_cliente = cl.id_cliente
WHERE f.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
GROUP BY cl.id_cliente, cl.numero_documento, cl.nombre_cliente
ORDER BY total_acumulado_gastado DESC;

-- 6.3 Compras por proveedor y categoría.
SELECT
    pr.id_proveedor,
    pr.razon_social AS proveedor,
    cat.nombre_categoria AS categoria_producto,
    COUNT(DISTINCT c.id_compra) AS total_pedidos_realizados,
    SUM(dc.cantidad) AS unidades_compradas,
    SUM(dc.subtotal) AS inversion_total_acumulada
FROM PROVEEDORES pr
JOIN COMPRAS c ON c.id_proveedor = pr.id_proveedor
JOIN DETALLE_COMPRAS dc ON dc.id_compra = c.id_compra
JOIN PRODUCTOS p ON p.id_producto = dc.id_producto
JOIN CATEGORIAS cat ON cat.id_categoria = p.id_categoria
WHERE c.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
GROUP BY pr.id_proveedor, pr.razon_social, cat.nombre_categoria
ORDER BY pr.razon_social, inversion_total_acumulada DESC;

-- 6.4 Kárdex / historial de movimientos.
SELECT
    m.id_movimiento,
    m.fecha_movimiento,
    p.codigo_barras,
    p.nombre_producto,
    m.tipo_movimiento,
    m.cantidad AS cantidad_movida,
    m.id_referencia_origen AS id_documento_origen,
    CASE
        WHEN m.tipo_movimiento = 'ENTRADA' THEN 'ID de Compra Asociada'
        WHEN m.tipo_movimiento = 'SALIDA' THEN 'ID de Factura Asociada'
    END AS descripcion_origen
FROM MOVIMIENTOS_INVENTARIO m
JOIN PRODUCTOS p ON p.id_producto = m.id_producto
ORDER BY m.fecha_movimiento DESC, m.id_movimiento DESC;

-- 6.5 Cierre de caja por forma de pago. El filtro de fecha está en el JOIN
-- para conservar las formas de pago sin facturas durante el período.
SELECT
    fp.id_forma_pago,
    fp.nombre_forma_pago AS metodo_pago,
    COUNT(f.id_factura) AS cantidad_facturas_cobradas,
    COALESCE(SUM(f.total), 0) AS monto_total_recaudado,
    ROUND(AVG(f.total), 2) AS ticket_promedio_metodo
FROM FORMAS_PAGO fp
LEFT JOIN FACTURAS f
    ON f.id_forma_pago = fp.id_forma_pago
   AND f.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
   AND f.fecha_emision >= CURRENT_DATE
   AND f.fecha_emision < CURRENT_DATE + INTERVAL '1 day'
GROUP BY fp.id_forma_pago, fp.nombre_forma_pago
ORDER BY monto_total_recaudado DESC, fp.nombre_forma_pago;

-- 6.6 Cliente con mayor gasto acumulado.
SELECT
    cl.id_cliente,
    cl.numero_documento,
    cl.nombre_cliente,
    cl.correo_cliente,
    COUNT(f.id_factura) AS facturas_emitidas,
    SUM(f.total) AS total_dinero_gastado
FROM CLIENTES cl
JOIN FACTURAS f ON f.id_cliente = cl.id_cliente
WHERE f.id_estado = (SELECT id_estado FROM ESTADOS_OPERACION WHERE nombre_estado = 'PAGADO')
GROUP BY cl.id_cliente, cl.numero_documento, cl.nombre_cliente, cl.correo_cliente
ORDER BY total_dinero_gastado DESC
LIMIT 1;

-- =============================================================================
-- 7. VALIDACIONES Y PRUEBAS
-- =============================================================================

-- Tablas creadas.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Conteos básicos.
SELECT 'PRODUCTOS' AS tabla, COUNT(*) AS cantidad FROM PRODUCTOS
UNION ALL SELECT 'CLIENTES', COUNT(*) FROM CLIENTES
UNION ALL SELECT 'PROVEEDORES', COUNT(*) FROM PROVEEDORES
UNION ALL SELECT 'USUARIOS', COUNT(*) FROM USUARIOS;

-- Productos en inventario crítico.
SELECT * FROM VISTA_INVENTARIO_CRITICO ORDER BY id_producto;

-- PRUEBAS TRANSACCIONALES OPCIONALES:
-- Ejecutar cada CALL por separado. La factura debe usar un correlativo único.
-- Venta de 2 unidades del producto P001:
-- CALL prc_registrar_factura('FACT-2026-001', 1, 2, 1, 1, 2);
--
-- Compra de 50 unidades del producto P005:
-- CALL prc_registrar_compra(1, 5, 50, 30.00);
--
-- Prueba negativa: debe fallar y revertir toda la llamada porque no hay 500
-- unidades disponibles de P002:
-- CALL prc_registrar_factura('FACT-FALLIDA', 1, 2, 1, 2, 500);
--
-- Verificación de factura:
-- SELECT id_factura, numero_factura_correlativo, total
-- FROM FACTURAS
-- WHERE numero_factura_correlativo = 'FACT-2026-001';
--
-- Verificación de stock y Kárdex:
-- SELECT id_producto, codigo_barras, nombre_producto, stock_actual
-- FROM PRODUCTOS
-- ORDER BY id_producto;
--
-- SELECT *
-- FROM MOVIMIENTOS_INVENTARIO
-- ORDER BY fecha_movimiento DESC, id_movimiento DESC;
