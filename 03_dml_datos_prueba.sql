-- =============================================================================
-- SCRIPT 03: DML - DATOS DE PRUEBA
-- =============================================================================
INSERT INTO ROLES (nombre_rol) VALUES ('Administrador'), ('Vendedor'), ('Cajero'), ('Supervisor'), ('Auditor');
INSERT INTO CATEGORIAS (nombre_categoria, descripcion) VALUES ('Lubricantes', 'Aceites'), ('Llantas', 'Neumáticos'), ('Baterías', 'Acumuladores'), ('Frenos', 'Pastillas'), ('Filtros', 'Filtros varios'), ('Motor', 'Partes internas');
INSERT INTO FORMAS_PAGO (nombre_forma_pago) VALUES ('Efectivo'), ('Tarjeta'), ('Transferencia'), ('Cheque'), ('Otro');
INSERT INTO TIPOS_DOCUMENTO (nombre_tipo) VALUES ('NIT'), ('DPI'), ('Pasaporte'), ('Extranjero'), ('CF');
INSERT INTO ESTADOS_OPERACION (nombre_estado) VALUES ('PENDIENTE'), ('PAGADO'), ('ANULADO');

INSERT INTO USUARIOS (nombre_usuario, correo_electronico, id_rol) VALUES ('Carlos Gomez', 'carlos@mail.com', 1), ('Ana Perez', 'ana@mail.com', 2), ('Luis Merida', 'luis@mail.com', 3);
INSERT INTO CLIENTES (id_tipo_documento, numero_documento, nombre_cliente, correo_cliente) VALUES (1, '982734-1', 'Talleres Centeno', 'centeno@mail.com'), (2, '2345678900101', 'Juan Marroquin', 'juan@mail.com'), (5, 'CF-1002', 'Consumidor Final', NULL);
INSERT INTO PROVEEDORES (nit_proveedor, razon_social, telefono) VALUES ('112233-4', 'Distribuidora Automotriz', '2233-4455'), ('556677-8', 'Llantas del Atlantico', '2334-5566');

INSERT INTO PRODUCTOS (codigo_barras, nombre_producto, id_categoria, precio_unitario, stock_actual, stock_minimo) VALUES
('LUB001', 'Aceite Motor 20W50', 1, 185.00, 50, 10),
('LUB002', 'Aceite Motor 10W30', 1, 320.00, 5, 10),
('LLA001', 'Llanta R13 Economica', 2, 375.00, 12, 4),
('BAT001', 'Bateria 12V NS40', 3, 550.00, 15, 5),
('FRE001', 'Pastillas Freno Toyota', 4, 220.00, 14, 5);

INSERT INTO FACTURAS (numero_factura_correlativo, id_cliente, id_usuario, id_forma_pago, id_estado) VALUES ('FAC-001', 1, 2, 1, 2);
INSERT INTO DETALLE_FACTURAS (id_factura, id_producto, cantidad, precio_venta, subtotal) VALUES (1, 1, 2, 185.00, 1);
