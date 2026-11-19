SELECT p.id AS product_id,
       p.name AS product_name,
       v.id AS variant_id,
       v.reference,
       v.color,
       v.height
FROM product_variants v
JOIN products p ON p.id = v.product_id
WHERE EXISTS (
        SELECT 1 FROM product_prices pp WHERE pp.product_variant_id = v.id
      )
  AND NOT EXISTS (
        SELECT 1
        FROM order_items i
        JOIN orders o ON o.id = i.order_id
        WHERE i.product_variant_id = v.id
          AND o.status = 'paid'
      )
ORDER BY p.name, v.reference;
