INSERT INTO promotions (id, name, percent, scope, starts_at, ends_at, max_uses, created_at, updated_at)
SELECT md5('seed:promotion:' || n)::uuid, 'Seed promo ' || n, 5 + n % 26,
       ((ARRAY['order', 'products', 'categories'])[1 + (n - 1) % 3])::promotion_scope,
       as_of - interval '3 years' + interval '1 day' * (n % 180),
       as_of + CASE WHEN n % 4 = 0 THEN interval '-6 months' ELSE interval '1 day' END,
       CASE WHEN n % 4 <> 0 THEN least(ceil(n_orders / 2000.0), 2147483647)::int END,
       as_of - interval '3 years', as_of - interval '3 years'
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_campaigns) AS g(n);

INSERT INTO promotion_products (id, promotion_id, product_id)
SELECT md5('seed:promotion_product:' || n)::uuid, md5('seed:promotion:' || n)::uuid,
       md5('seed:product:' || (1 + (n - 1) % n_products))::uuid
FROM seed_config CROSS JOIN LATERAL generate_series(2, n_campaigns, 3) AS g(n);

INSERT INTO promotion_categories (id, promotion_id, category_id)
SELECT md5('seed:promotion_category:' || n)::uuid, md5('seed:promotion:' || n)::uuid,
       md5('seed:category:leaf:' || (1 + ((n - 1) % n_products) % (n_branches * 4)))::uuid
FROM seed_config CROSS JOIN LATERAL generate_series(3, n_campaigns, 3) AS g(n);

INSERT INTO promo_codes (id, promotion_id, code, user_id, once_per_customer, created_at, updated_at)
SELECT md5('seed:promo_code:' || n || ':' || slot)::uuid, md5('seed:promotion:' || n)::uuid,
       'SEED-PROMO-' || n || '-' || slot, CASE WHEN slot = 2 THEN u.id END,
       slot = 2 OR n % 2 = 0, issued_at, issued_at
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_campaigns) AS g(n)
JOIN users u ON u.id = md5('seed:user:' || (1 + (n - 1) % n_users))::uuid
CROSS JOIN generate_series(1, 2) AS slots(slot)
CROSS JOIN LATERAL (VALUES (CASE WHEN slot = 2 THEN u.created_at + interval '1 hour'
                                 ELSE as_of - interval '3 years' END)) AS dates(issued_at);
