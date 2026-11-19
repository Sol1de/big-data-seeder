SELECT b.id AS brand_id,
       b.name AS brand_name,
       SUM(i.quantity) AS quantite_vendue,
       ROUND(SUM(i.quantity * i.unit_price * (1 - i.discount_percent / 100)), 2) AS chiffre_affaires
FROM order_items i
JOIN orders o ON o.id = i.order_id
JOIN product_variants v ON v.id = i.product_variant_id
JOIN products p ON p.id = v.product_id
JOIN brands b ON b.id = p.brand_id
WHERE o.status = 'paid'
GROUP BY b.id, b.name
ORDER BY chiffre_affaires DESC;
