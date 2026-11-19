WITH samples AS (
    SELECT n, as_of, n_products, customer, guest, campaign, md5('seed:order:' || n)::uuid AS order_id,
           md5('seed:promo_code:' || campaign || ':' || slot)::uuid AS candidate
    FROM seed_config CROSS JOIN LATERAL generate_series(1, n_orders) AS g(n)
    CROSS JOIN LATERAL (VALUES (1 + (n - 1) % n_users, n % 10 = 0)) AS who(customer, guest)
    CROSS JOIN LATERAL (VALUES (CASE WHEN customer <= n_campaigns AND NOT guest THEN customer
                                     WHEN n % 7 < 3 THEN 1 + (n - 1) % n_campaigns END,
                                CASE WHEN customer <= n_campaigns AND NOT guest THEN 2 ELSE 1 END)) AS code(campaign, slot)
), checkouts AS MATERIALIZED (
    SELECT s.*, u.id AS customer_id, u.email, u.phone, u.first_name, u.last_name,
           a.address, a.city, a.state, a.postal_code, a.country_code,
           u.created_at + interval '4 hours' + (as_of - u.created_at - interval '4 hours')
               * ((n * 7919 % 10001) / 10000.0) AS ordered_at
    FROM samples s
    JOIN users u ON u.id = md5('seed:user:' || customer)::uuid
    JOIN addresses a ON a.id = md5('seed:address:' || customer || ':' || (1 + n % (1 + (customer - 1) % 3)))::uuid
), eligible AS (
    SELECT o.n, c.id AS code_id, c.promotion_id, p.max_uses,
           row_number() OVER (PARTITION BY c.id, o.customer_id ORDER BY o.ordered_at, o.n) AS customer_use,
           c.once_per_customer, o.ordered_at
    FROM checkouts o JOIN promo_codes c ON c.id = o.candidate
    JOIN promotions p ON p.id = c.promotion_id
    WHERE o.ordered_at >= greatest(c.created_at, p.starts_at) AND o.ordered_at < p.ends_at
      AND (NOT c.once_per_customer OR NOT o.guest)
      AND (c.user_id IS NULL OR (NOT o.guest AND c.user_id = o.customer_id))
), ranked AS (
    SELECT n, code_id, max_uses,
           row_number() OVER (PARTITION BY promotion_id ORDER BY ordered_at, n) AS promotion_use
    FROM eligible WHERE NOT once_per_customer OR customer_use = 1
), new_orders AS (
    INSERT INTO orders (id, public_id, user_id, promo_code_id, status, email, phone, first_name, last_name,
                        address, city, state, postal_code, country_code, created_at, updated_at)
    SELECT order_id, 'SEED-ORDER-' || o.n, CASE WHEN NOT guest THEN customer_id END, r.code_id,
           (CASE WHEN ordered_at > as_of - interval '1 day' THEN 'pending'
                 WHEN o.n % 19 = 0 THEN 'cancelled'
                 WHEN ordered_at > as_of - interval '3 days' THEN 'paid'
                 WHEN ordered_at > as_of - interval '7 days' THEN 'shipped' ELSE 'delivered' END)::order_status,
           CASE WHEN guest THEN 'invite' || o.n || '@example.test' ELSE email END,
           CASE WHEN NOT guest THEN phone END,
           CASE WHEN guest THEN 'Invité' ELSE first_name END,
           CASE WHEN guest THEN 'Test ' || o.n ELSE last_name END,
           CASE WHEN guest THEN o.n || ' rue des Invités' ELSE address END,
           city, state, postal_code, country_code, ordered_at, least(as_of, ordered_at + interval '1 day')
    FROM checkouts o LEFT JOIN ranked r ON r.n = o.n AND (r.max_uses IS NULL OR r.promotion_use <= r.max_uses)
    RETURNING id, promo_code_id, created_at
), price_bands AS (
    SELECT product_variant_id, price, currency, valid_from,
           lead(valid_from, 1, TIMESTAMP 'infinity') OVER (PARTITION BY product_variant_id ORDER BY valid_from) AS valid_until
    FROM product_prices
), lines AS (
    SELECT o.id, o.created_at, pc.promotion_id, v, n,
           md5('seed:variant:' || product || ':' || (1 + (n + v) % 4))::uuid AS variant_id
    FROM new_orders o JOIN checkouts c ON c.order_id = o.id
    LEFT JOIN promo_codes pc ON pc.id = o.promo_code_id
    CROSS JOIN generate_series(1, 3) AS slots(v)
    CROSS JOIN LATERAL (VALUES (1 + CASE WHEN v = 1 AND pc.id IS NOT NULL
         THEN (campaign - 1) % n_products
         ELSE (n * 43 + v * 31) % n_products END)) AS selection(product)
), qualifying_products AS (
    SELECT promotion_id, product_id FROM promotion_products
    UNION
    SELECT pc.promotion_id, link.product_id FROM promotion_categories pc
    JOIN product_categories link ON link.category_id = pc.category_id
)
INSERT INTO order_items (id, order_id, product_variant_id, quantity, unit_price, currency, discount_percent)
SELECT md5('seed:order_item:' || l.n || ':' || l.v)::uuid, l.id, l.variant_id,
       (1 + (l.n + l.v) % 3)::int, price.price, price.currency,
       CASE WHEN p.scope = 'order' OR q.product_id IS NOT NULL THEN p.percent ELSE 0 END
FROM lines l
JOIN product_variants v ON v.id = l.variant_id
JOIN price_bands price ON price.product_variant_id = l.variant_id
    AND l.created_at >= price.valid_from AND l.created_at < price.valid_until
LEFT JOIN promotions p ON p.id = l.promotion_id
LEFT JOIN qualifying_products q ON q.promotion_id = p.id AND q.product_id = v.product_id;
