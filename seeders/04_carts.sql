INSERT INTO carts (id, user_id, created_at, updated_at)
SELECT md5('seed:cart:' || n)::uuid, u.id, as_of - interval '1 minute', as_of
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_carts) AS g(n)
JOIN users u ON u.id = md5('seed:user:' || n)::uuid;

INSERT INTO cart_items (id, cart_id, product_variant_id, quantity)
SELECT md5('seed:cart_item:' || n || ':' || v)::uuid, md5('seed:cart:' || n)::uuid,
       md5('seed:variant:' || (1 + (n * 31 + v) % n_products) || ':' || v)::uuid, (1 + (n + v) % 3)::int
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_carts) AS g(n)
CROSS JOIN LATERAL generate_series(1, n % 4) AS variants(v);
