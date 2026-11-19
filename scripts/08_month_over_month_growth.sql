WITH months AS (
  SELECT generate_series(
           date_trunc('month', MIN(created_at)),
           date_trunc('month', MAX(created_at)),
           interval '1 month'
         )::date AS mois
  FROM orders
),
revenue AS (
  SELECT o.country_code,
         date_trunc('month', o.created_at)::date AS mois,
         SUM(i.quantity * i.unit_price * (1 - i.discount_percent / 100)) AS ca
  FROM orders o
  JOIN order_items i ON i.order_id = o.id
  WHERE o.status IN ('paid', 'shipped', 'delivered')
  GROUP BY o.country_code, date_trunc('month', o.created_at)
),
countries AS (
  SELECT DISTINCT country_code FROM orders
),
grid AS (
  SELECT c.country_code,
         m.mois,
         COALESCE(r.ca, 0) AS ca
  FROM countries c
  CROSS JOIN months m
  LEFT JOIN revenue r ON r.country_code = c.country_code AND r.mois = m.mois
)
SELECT country_code,
       mois,
       ROUND(ca, 2) AS chiffre_affaires,
       ROUND(ca - LAG(ca) OVER w, 2) AS variation_euros,
       ROUND(100 * (ca - LAG(ca) OVER w) / NULLIF(LAG(ca) OVER w, 0), 2) AS variation_pct
FROM grid
WINDOW w AS (PARTITION BY country_code ORDER BY mois)
ORDER BY country_code, mois;
