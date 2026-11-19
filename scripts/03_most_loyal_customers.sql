WITH paid_orders AS (
  SELECT o.id,
         o.user_id,
         SUM(i.quantity * i.unit_price * (1 - i.discount_percent / 100)) AS order_total
  FROM orders o
  JOIN order_items i ON i.order_id = o.id
  WHERE o.status = 'paid'
    AND o.user_id IS NOT NULL
    AND o.created_at >= now() - interval '12 months'
  GROUP BY o.id, o.user_id
)
SELECT u.id,
       u.email,
       u.username,
       u.first_name,
       u.last_name,
       COUNT(*) AS nb_commandes,
       ROUND(SUM(p.order_total), 2) AS depense_totale
FROM paid_orders p
JOIN users u ON u.id = p.user_id
GROUP BY u.id, u.email, u.username, u.first_name, u.last_name
ORDER BY nb_commandes DESC, depense_totale DESC
LIMIT 50;
