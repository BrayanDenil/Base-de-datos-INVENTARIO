# Alcance del Sistema y Reglas de Negocio

## 🏬 Enfoque Comercial del Negocio
El sistema está diseñado a medida para un comercio enfocado en la **compra-venta y distribución de repuestos automotrices, partes de motor, lubricantes, baterías y llantas**. Su objetivo primordial es unificar el flujo transaccional de entrada de mercancía (compras a proveedores) con el flujo de salida hacia los consumidores finales y corporativos (facturación), controlando en tiempo real las variaciones de existencias y los movimientos logísticos a través de un histórico integralizado (Kárdex).

## 📌 Reglas de Negocio Críticas
1.  **Unicidad de Identificadores:** El Código de Barras de cada producto, el NIT de los proveedores, el número de documento de identificación de los clientes y el número correlativo de las facturas son estrictamente únicos (`UNIQUE`).
2.  **Restricción de Stock en Venta:** No se permite bajo ninguna circunstancia facturar una cantidad de producto superior al `stock_actual` disponible. Si la cantidad solicitada excede la existencia, la transacción se aborta lanzando una excepción controlada.
3.  **Integridad de Costos y Precios:** Los precios de venta de los detalles de las facturas, los precios de costo de los detalles de las compras y los precios unitarios de catálogo deben ser estrictamente positivos y mayores a cero (`CHECK > 0`).
4.  **Flujos de Inventario Automatizados:** Cada venta procesada en estado 'PAGADO' disminuye automáticamente las existencias en la tabla `PRODUCTOS` y genera un registro de 'SALIDA' en el Kárdex (`MOVIMIENTOS_INVENTARIO`). Cada compra recibida en estado 'PAGADO' incrementa las existencias.
5.  **Cálculo Automatizado de Valores:** El campo `subtotal` en las líneas de detalle de compras y ventas se calcula de manera automática multiplicando la cantidad por el precio respectivo.
