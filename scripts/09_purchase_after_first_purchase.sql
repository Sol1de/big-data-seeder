WITH first_orders AS (
  SELECT user_id,
         MIN(created_at) AS premier_achat
  FROM orders
  WHERE status IN ('paid', 'shipped', 'delivered')
    AND user_id IS NOT NULL
  GROUP BY user_id
  HAVING MIN(created_at) <= now() - interval '90 days'
),
next_order AS (
  SELECT f.user_id,
         MIN(o.created_at) AS rachat
  FROM first_orders f
  JOIN orders o ON o.user_id = f.user_id
               AND o.status IN ('paid', 'shipped', 'delivered')
               AND o.created_at > f.premier_achat
  GROUP BY f.user_id
),
cohort AS (
  SELECT f.user_id,
         (n.rachat::date - f.premier_achat::date) AS jours_avant_rachat
  FROM first_orders f
  LEFT JOIN next_order n ON n.user_id = f.user_id
)
SELECT w.fenetre,
       COUNT(*) AS clients,
       COUNT(*) FILTER (WHERE c.jours_avant_rachat <= w.jours) AS reacheteurs,
       ROUND(100.0 * COUNT(*) FILTER (WHERE c.jours_avant_rachat <= w.jours) / COUNT(*), 2) AS taux_pct
FROM cohort c
CROSS JOIN (VALUES ('30 jours', 30), ('60 jours', 60), ('90 jours', 90)) AS w(fenetre, jours)
GROUP BY w.fenetre, w.jours
ORDER BY w.jours;
