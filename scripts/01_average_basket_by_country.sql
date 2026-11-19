WITH paid_orders AS (
  SELECT o.id,
         o.country_code,
         SUM(i.quantity * i.unit_price * (1 - i.discount_percent / 100)) AS order_total
  FROM orders o
  JOIN order_items i ON i.order_id = o.id
  WHERE o.status = 'paid'
  GROUP BY o.id, o.country_code
)
SELECT country_code,
       COUNT(*) AS nb_commandes,
       ROUND(SUM(order_total), 2) AS chiffre_affaires,
       ROUND(AVG(order_total), 2) AS panier_moyen
FROM paid_orders
GROUP BY country_code
ORDER BY chiffre_affaires DESC;
