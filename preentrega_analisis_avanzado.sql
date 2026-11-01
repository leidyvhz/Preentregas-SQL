-- 1. Primera CTE: Limpieza y agregación inicial por mes y categoría en formato MySQL
WITH ventas_mensuales AS (
    SELECT 
        DATE_FORMAT(v.fecha, '%Y-%m-01') AS mes_venta,
        p.categoria AS categoria_producto,
        SUM(v.cantidad * (COALESCE(p.precio_lista, 0) - (COALESCE(p.precio_lista, 0) * COALESCE(p.descuento_promocional, 0)))) AS venta_total_mes
    FROM ventas v
    INNER JOIN productos p ON v.id_producto = p.id_producto
    GROUP BY DATE_FORMAT(v.fecha, '%Y-%m-01'), p.categoria
),

-- 2. Segunda CTE: Aplicación de funciones de ventana (Ranking y Running Total)
metricas_ventana AS (
    SELECT 
        mes_venta,
        categoria_producto,
        venta_total_mes,
        -- Ranking de la categoría con mayores ventas dentro de cada mes
        RANK() OVER (PARTITION BY mes_venta ORDER BY venta_total_mes DESC) AS ranking_categoria_mes,
        -- Total acumulado (Running Total) de ventas por categoría a lo largo del tiempo
        SUM(venta_total_mes) OVER (PARTITION BY categoria_producto ORDER BY mes_venta) AS acumulado_categoria
    FROM ventas_mensuales
),

-- 3. Tercera CTE: Cálculo del promedio histórico de ventas por cada categoría
promedio_categorias AS (
    SELECT 
        categoria_producto,
        AVG(venta_total_mes) AS promedio_historico
    FROM ventas_mensuales
    GROUP BY categoria_producto
)

-- 4. Consulta Final (SELECT Principal): Integración de métricas y lógica de negocio (CASE WHEN)
SELECT 
    m.mes_venta,
    m.categoria_producto,
    m.venta_total_mes,
    m.ranking_categoria_mes,
    m.acumulado_categoria,
    ROUND(p.promedio_historico, 2) AS promedio_historico_categoria,
    -- Comparativa condicional con el promedio histórico de la categoría
    CASE 
        WHEN m.venta_total_mes >= p.promedio_historico THEN 'Por encima'
        ELSE 'Por debajo'
    END AS comparativa_promedio
FROM metricas_ventana m
INNER JOIN promedio_categorias p ON m.categoria_producto = p.categoria_producto
ORDER BY m.mes_venta DESC, m.ranking_categoria_mes ASC;