SELECT u.id,
       u.email,
       u.username,
       u.first_name,
       u.last_name,
       MAX(o.created_at) AS derniere_commande,
       (now()::date - MAX(o.created_at)::date) AS jours_depuis_achat
FROM users u
JOIN orders o ON o.user_id = u.id AND o.status IN ('paid', 'shipped', 'delivered')
WHERE NOT EXISTS (
        SELECT 1 FROM orders r
        WHERE r.user_id = u.id AND r.created_at >= now() - interval '180 days'
      )
GROUP BY u.id, u.email, u.username, u.first_name, u.last_name
ORDER BY derniere_commande;
