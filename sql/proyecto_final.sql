-- FASE 1---------------------
CREATE DATABASE proyecto_final;
USE proyecto_final;
CREATE TABLE clientes (
	id_cliente INT PRIMARY KEY,
	nombre VARCHAR(100),
    email VARCHAR(150),
    ciudad VARCHAR(100),
    segmento VARCHAR(20),
    fecha_registro DATE
);
CREATE TABLE productos (
    id_producto INT PRIMARY KEY,
    nombre VARCHAR(150),
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    precio DECIMAL(10,2),
    costo DECIMAL(10,2),
    stock INT
);
CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY,
    id_cliente INT,
    fecha DATE,
    estado VARCHAR(30),
    canal VARCHAR(50),

    FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente)
);
CREATE TABLE detalle_pedido (
    id_detalle INT PRIMARY KEY,
    id_pedido INT,
    id_producto INT,
    cantidad INT,
    precio_unit DECIMAL(10,2),
    subtotal DECIMAL(10,2),

    FOREIGN KEY (id_pedido)
        REFERENCES pedidos(id_pedido),

    FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto)
);

-- FASE 3-------------------
-- Consulta 1: Calcula los ingresos totales agrupados por categoria de producto.
-- Sumamos los subtotales de cada detalle de pedido y se agrupan por la categoria del producto.
-- Esto nos permite identificar que categorias generan más ingresos en el negocio.
SELECT p.categoria, SUM(d.subtotal) AS ingresos_totales
FROM detalle_pedido d
JOIN productos p ON d.id_producto = p.id_producto
GROUP BY p.categoria
ORDER BY ingresos_totales DESC;

-- Consulta 2: Obtiene los 10 clientes con mayor gasto total.
-- Sumamos los subtotales de todos los pedidos realizados por cada cliente.
-- El resultado nos muestra el ranking de los clientes más valiosos.
SELECT c.id_cliente, c.nombre, SUM(d.subtotal) AS gasto_total
FROM clientes c
JOIN pedidos pe ON c.id_cliente = pe.id_cliente
JOIN detalle_pedido d ON pe.id_pedido = d.id_pedido
GROUP BY c.id_cliente, c.nombre
ORDER BY gasto_total DESC
LIMIT 10;


-- Consulta 3: Calcula las ventas por canal de venta (Web, App, Tienda física)  y su % del total.
-- Se relacionan pedidos con detalle_pedido para obtener los subtotales por canal.
-- Se agrupan los registros por canal y se calcula la suma de ventas.
-- Además, se calcula el porcentaje de cada canal respecto al total de ventas usando una subconsulta.
SELECT pe.canal,
       SUM(d.subtotal) AS ventas_totales,
       ROUND(SUM(d.subtotal) * 100 / (SELECT SUM(subtotal) FROM detalle_pedido), 2) AS porcentaje
FROM pedidos pe
JOIN detalle_pedido d ON pe.id_pedido = d.id_pedido
GROUP BY pe.canal
ORDER BY ventas_totales DESC;
-- Consulta 4: Lista los clientes VIP que no han comprado en los últimos 60 días.
-- Tomamos la ultima fecha de compra registrada y se compara con la fecha actual,
-- El HAVING nos ayuda a filtrar aquellos cuya última compra fue hace más de 60 días o que no tienen compras registradas.
SELECT 
    c.id_cliente,
    c.nombre,
    MAX(pe.fecha) AS ultima_compra
FROM clientes c
LEFT JOIN pedidos pe 
    ON c.id_cliente = pe.id_cliente
WHERE c.segmento = 'VIP'
GROUP BY c.id_cliente, c.nombre
HAVING MAX(pe.fecha) < (
    SELECT MAX(fecha) - INTERVAL 60 DAY
    FROM pedidos
)
OR MAX(pe.fecha) IS NULL;

-- Consulta 5: Identifica productos con stock bajo (menos de 10 unidades) que han tenido ventas.
-- Se agrupan las ventas por producto y se filtran aquellos con stock bajo.
-- El HAVING filtra productos con stock menor a 10 y que tengan al menos una venta registrada.
SELECT 
    p.id_producto,
    p.nombre,
    p.stock,
    SUM(d.cantidad) AS total_vendido
FROM productos p
JOIN detalle_pedido d 
    ON p.id_producto = d.id_producto
WHERE p.stock < 10
GROUP BY p.id_producto, p.nombre, p.stock
ORDER BY total_vendido DESC;