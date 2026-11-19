WITH RECURSIVE tree AS (
  SELECT id, name, parent_id, name::text AS path
  FROM categories
  WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.name, c.parent_id, t.path || ' > ' || c.name
  FROM categories c
  JOIN tree t ON c.parent_id = t.id
),
sales AS (
  SELECT o.country_code,
         c.id AS category_id,
         c.name AS category_name,
         t.path AS category_path,
         SUM(i.quantity) AS quantite_vendue,
         SUM(i.quantity * i.unit_price * (1 - i.discount_percent / 100)) AS chiffre_affaires
  FROM order_items i
  JOIN orders o ON o.id = i.order_id
  JOIN product_variants v ON v.id = i.product_variant_id
  JOIN product_categories pc ON pc.product_id = v.product_id
  JOIN categories c ON c.id = pc.category_id
  JOIN tree t ON t.id = c.id
  WHERE o.status IN ('paid', 'shipped', 'delivered')
  GROUP BY o.country_code, c.id, c.name, t.path
)
SELECT DISTINCT ON (country_code)
       country_code,
       category_id,
       category_name,
       category_path,
       quantite_vendue,
       ROUND(chiffre_affaires, 2) AS chiffre_affaires
FROM sales
ORDER BY country_code, chiffre_affaires DESC, quantite_vendue DESC, category_name;
