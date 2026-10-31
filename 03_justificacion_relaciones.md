# Justificación Técnico-Relacional del Modelo

## El Problema de la Cardinalidad Muchos a Muchos (M:N)
Se establece una relación de cardinalidad compleja de tipo **Muchos a Muchos (M:N)** entre las entidades **FACTURAS** y **PRODUCTOS**. Un solo documento de factura comercial puede contener e integrar muchos productos. A su vez, un mismo producto puede ser comercializado e incluirse en múltiples facturas a lo largo del tiempo.

## Resolución Mediante la Tabla Puente: DETALLE_FACTURAS
Para solventar esto, el modelo descompone e implementa la relación M:N transformándola en dos relaciones lineales de tipo **Uno a Muchos (1:N)** interconectadas mediante la tabla puente asociativa **DETALLE_FACTURAS**. Esta guarda la llave foránea de ambas tablas y contiene atributos propios del momento de la venta (`cantidad`, `precio_venta` congelado históricamente, y `subtotal`).
