WITH paires AS (
  SELECT DISTINCT i1.order_id,
         i1.product_variant_id AS variante_a,
         i2.product_variant_id AS variante_b
  FROM order_items i1
  JOIN order_items i2 ON i2.order_id = i1.order_id
                     AND i2.product_variant_id > i1.product_variant_id
  JOIN orders o ON o.id = i1.order_id
  WHERE o.status IN ('paid', 'shipped', 'delivered')
)
SELECT va.reference AS reference_a,
       pa.name AS produit_a,
       vb.reference AS reference_b,
       pb.name AS produit_b,
       COUNT(*) AS commandes
FROM paires p
JOIN product_variants va ON va.id = p.variante_a
JOIN products pa ON pa.id = va.product_id
JOIN product_variants vb ON vb.id = p.variante_b
JOIN products pb ON pb.id = vb.product_id
GROUP BY va.reference, pa.name, vb.reference, pb.name
ORDER BY commandes DESC
LIMIT 50;
