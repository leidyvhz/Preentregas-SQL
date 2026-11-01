create database retail_project;

create table clientes(
	id_cliente integer primary key,
	nombre varchar(150) not null,
	email varchar(100) not null unique,
	edad integer check (edad >= 18) not null
);

create table productos(
	id_producto serial primary key,
	nombre varchar(100) not null,
	precio_lista NUMERIC(10, 2),
	descuento_promocional NUMERIC(10, 2),
	categoria varchar(50)
);

create table ventas(
	id_venta serial primary key,
	id_cliente integer not null references clientes,
	id_producto integer not null references productos,
	cantidad integer check (cantidad > 0) not null,
	fecha date not null
);

insert into clientes(id_cliente, nombre, email, edad)
values
	(123, 'Leidy Herrera', 'leidy.herrera@correo.com', 33),
	(456, 'Violetta Tovar', 'violetta.tovar@correo.com', 19),
	(789, 'Laura Gómez', 'laura.gomez@correo.com', 28),
	(012, 'Carlos Pérez', 'carlos.perez@correo.com', 35),
	(345, 'Julian Jaramillo', 'julian.jaramillo@correo.com', 27);

insert into productos(nombre, precio_lista, descuento_promocional, categoria)
values
	('Camiseta Algodón', 15000, 0.25,'Prenda superior'),
	('Pantalón Jean', 70000, 0.10, 'Prenda inferior'),
	('Blusa lino', 37500, 0.20, 'Prenda superior'),
	('Short denim', 65000, 0.05, 'Prenda inferior'),
	('Vestido poliester', 35000, 0.03, 'Prenda superior'),
	('Camisa poliester', 25000, 0.01, 'Prenda superior');

insert into ventas(id_cliente, id_producto, cantidad, fecha)
values
	(123, 2, 3, '2026-07-05'),
	(12, 1, 1, '2026-06-25'),
	(345, 5, 6, '2025-08-20'),
	(123, 1, 5, '2025-12-07'),
	(456, 3, 10, '2026-03-02');

/* 1. Rentabilidad por categoría
Evaluar el rendimiento comercial por cada categoría de
productos para identificar cuáles generan mayores ingresos y volumen de ventas,
filtrando aquellas que superan un umbral estratégico definido (ej. ingreso total > 100000). */

SELECT
p.categoria AS nombre_categoria,
SUM(v.cantidad) AS unidades_vendidas,
SUM(v.cantidad * (COALESCE(p.precio_lista, 0) - (COALESCE(p.precio_lista, 0) * COALESCE(p.descuento_promocional, 0)))) AS ingreso_total
FROM ventas v
INNER JOIN productos p ON v.id_producto = p.id_producto
GROUP BY p.categoria
HAVING SUM(v.cantidad * (COALESCE(p.precio_lista, 0) - (COALESCE(p.precio_lista, 0) * COALESCE(p.descuento_promocional, 0)))) > 100000;

/* 2. Clientes sin compras
Identificar clientes registrados que aún no han realizado
ninguna transacción para enfocar campañas de marketing y activación comercial,
manejando valores nulos adecuadamente con COALESCE. */

SELECT 
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.email,
    'Sin Compras' AS estado_compras
FROM clientes c
LEFT JOIN ventas v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL;

/* 3. Top de compras por cliente
Conocer las preferencias de compra individuales de cada
cliente activo, identificando cuál es el producto que más unidades ha adquirido
y la fecha exacta de su última transacción en la plataforma. */

WITH ranking_compras AS (
SELECT
c.id_cliente,
c.nombre AS nombre_cliente,
p.nombre AS nombre_producto,
v.cantidad,
v.fecha,
ROW_NUMBER() OVER (PARTITION BY c.id_cliente ORDER BY v.cantidad DESC, v.fecha DESC) as rn
FROM clientes c
INNER JOIN ventas v ON c.id_cliente = v.id_cliente
INNER JOIN productos p ON v.id_producto = p.id_producto
)
SELECT
nombre_cliente,
nombre_producto AS producto_mas_comprado,
fecha AS fecha_ultima_transaccion
FROM ranking_compras
WHERE rn = 1;