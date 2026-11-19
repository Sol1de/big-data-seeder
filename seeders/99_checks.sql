-- Run after the seed inserts, in the same transaction as seed_config.
SET LOCAL plpgsql.check_asserts = on;
-- Fresh inserts do not yet have statistics for choosing bulk join plans.
ANALYZE users, addresses, products, product_categories, product_variants, product_prices,
        carts, cart_items, promotions, promo_codes, orders, order_items;
-- Prefer bulk joins for full-table checks, including temporal joins with equality keys.
SET LOCAL enable_nestloop = off;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM users u CROSS JOIN pg_temp.seed_config cfg
        WHERE u.username LIKE 'seed-client-%'
          AND (u.created_at < cfg.as_of - interval '3 years' OR u.created_at >= cfg.as_of)
    ), 'Seeded user enrollment must fall within the three years before as_of';
END; $$;

DO $$ BEGIN
    ASSERT (SELECT count(*) = count(DISTINCT email)
                   AND count(*) = count(DISTINCT username)
                   AND count(*) = count(DISTINCT phone)
            FROM users WHERE username LIKE 'seed-client-%'),
        'Seeded users must have unique email, username and non-null phone';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM users u
        LEFT JOIN (SELECT user_id, count(*) AS total FROM addresses GROUP BY user_id) a ON a.user_id = u.id
        WHERE u.username LIKE 'seed-client-%' AND coalesce(a.total, 0) NOT BETWEEN 1 AND 3
    ), 'Each seeded user must have one to three addresses';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM addresses a JOIN users u ON u.id = a.user_id
        WHERE u.username LIKE 'seed-client-%' AND a.created_at <= u.created_at
    ), 'Seeded addresses must be created strictly after their users';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM users WHERE username LIKE 'seed-client-%' AND updated_at < created_at
        UNION ALL
        SELECT 1 FROM addresses a JOIN users u ON u.id = a.user_id
        WHERE u.username LIKE 'seed-client-%' AND a.updated_at < a.created_at
    ), 'Seeded users and addresses must not be updated before creation';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        WITH RECURSIVE seed_categories AS (
            SELECT id, parent_id FROM categories WHERE name LIKE 'Seed Mobilier %'
        ), tree AS (
            SELECT id, 1 AS depth FROM seed_categories WHERE parent_id IS NULL
            UNION ALL
            SELECT c.id, t.depth + 1 FROM tree t JOIN seed_categories c ON c.parent_id = t.id
            WHERE t.depth < 3
        )
        SELECT 1 WHERE (SELECT count(*) FROM tree WHERE depth = 1) <> 1
            OR (SELECT count(*) FROM tree) <> (SELECT count(*) FROM seed_categories)
        UNION ALL
        SELECT 1 FROM tree t WHERE t.depth < 3
          AND NOT EXISTS (SELECT 1 FROM seed_categories c WHERE c.parent_id = t.id)
    ), 'Seeded categories must form one tree whose leaves are all at level three';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        WITH seed_categories AS (
            SELECT id, parent_id FROM categories WHERE name LIKE 'Seed Mobilier %'
        ), leaves AS (
            SELECT c.id FROM seed_categories c
            WHERE NOT EXISTS (SELECT 1 FROM categories child WHERE child.parent_id = c.id)
        )
        SELECT 1
        FROM products p JOIN brands b ON b.id = p.brand_id
        LEFT JOIN product_categories pc ON pc.product_id = p.id
        LEFT JOIN leaves l ON l.id = pc.category_id
        WHERE b.commercial_name LIKE 'Seed Atelier %' AND l.id IS NULL
    ), 'Each seeded product must link to at least one category and only to seeded leaves';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM product_variants WHERE reference LIKE 'SEED-%'
        GROUP BY reference HAVING count(*) > 1
    ), 'Seeded variant references must be unique';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM product_variants v LEFT JOIN product_prices p ON p.product_variant_id = v.id
        WHERE v.reference LIKE 'SEED-%'
        GROUP BY v.id
        HAVING count(p.id) NOT BETWEEN 1 AND 4 OR count(p.id) <> count(DISTINCT p.valid_from)
    ), 'Each seeded variant must have one to four prices with distinct effective timestamps';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM product_variants v
        JOIN (SELECT product_variant_id, min(valid_from) AS first_price FROM product_prices GROUP BY product_variant_id) p
            ON p.product_variant_id = v.id
        WHERE v.reference LIKE 'SEED-%'
          AND p.first_price >= (SELECT min(created_at) FROM orders WHERE public_id LIKE 'SEED-ORDER-%')
    ), 'Every seeded variant must have a price strictly before the earliest seeded order';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM promotions WHERE name LIKE 'Seed promo %'
          AND ends_at <= starts_at
    ), 'Seeded promotions must have a positive duration';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM promotions WHERE name LIKE 'Seed promo %'
          AND (percent <= 0 OR percent > 100)
    ), 'Seeded promotions must have a percent in (0, 100]';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM promotions p WHERE p.name LIKE 'Seed promo %'
          AND ((p.scope = 'products') <> EXISTS (SELECT 1 FROM promotion_products pp WHERE pp.promotion_id = p.id)
            OR (p.scope = 'categories') <> EXISTS (SELECT 1 FROM promotion_categories pc WHERE pc.promotion_id = p.id))
    ), 'Seeded promotions must have links only to their declared scope, or no links for order scope';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM promo_codes c JOIN users u ON u.id = c.user_id
        WHERE c.code LIKE 'SEED-PROMO-%' AND c.created_at <= u.created_at
    ), 'Seeded nominative codes must be created strictly after the attached user';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM carts c JOIN users u ON u.id = c.user_id
        WHERE u.username LIKE 'seed-client-%'
        GROUP BY c.user_id HAVING count(*) > 1
    ), 'A seeded user must have at most one cart';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM cart_items i JOIN carts c ON c.id = i.cart_id JOIN users u ON u.id = c.user_id
        WHERE u.username LIKE 'seed-client-%' AND i.quantity <= 0
    ), 'Seeded cart items must have positive quantities';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM cart_items i JOIN carts c ON c.id = i.cart_id JOIN users u ON u.id = c.user_id
        WHERE u.username LIKE 'seed-client-%'
        GROUP BY i.cart_id, i.product_variant_id HAVING count(*) > 1
    ), 'Seeded carts must not have duplicate variants';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o JOIN users u ON u.id = o.user_id
        WHERE o.public_id LIKE 'SEED-ORDER-%' AND o.created_at <= u.created_at
    ), 'Seeded registered orders must be created strictly after the user';
END; $$;

DO $$ BEGIN
    ASSERT (SELECT abs(count(*) FILTER (WHERE user_id IS NULL) - count(*) / 10.0) <= 1
            FROM orders WHERE public_id LIKE 'SEED-ORDER-%'),
        'Seeded guest orders must be within one order of ten percent';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o
        WHERE o.public_id LIKE 'SEED-ORDER-%' AND o.user_id IS NOT NULL
          AND NOT EXISTS (
              SELECT 1 FROM addresses a
              WHERE a.user_id = o.user_id AND a.created_at < o.created_at
                AND a.address = o.address AND a.city = o.city
                AND a.state IS NOT DISTINCT FROM o.state
                AND a.postal_code = o.postal_code AND a.country_code = o.country_code
          )
    ), 'Seeded registered orders must copy an existing saved address from their user';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o LEFT JOIN order_items i ON i.order_id = o.id
        WHERE o.public_id LIKE 'SEED-ORDER-%'
        GROUP BY o.id HAVING count(i.id) <> 3 OR min(i.quantity) <= 0
    ), 'Every seeded order must have three items with positive quantities';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM order_items i JOIN orders o ON o.id = i.order_id
        JOIN product_variants v ON v.id = i.product_variant_id
        WHERE o.public_id LIKE 'SEED-ORDER-%'
        GROUP BY o.id, v.product_id HAVING count(*) > 1
    ), 'Every seeded order must contain three distinct products';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        WITH price_bands AS (
            SELECT p.id, p.product_variant_id, p.price, p.currency, p.valid_from,
                   lead(p.valid_from, 1, TIMESTAMP 'infinity') OVER (
                       PARTITION BY p.product_variant_id ORDER BY p.valid_from
                   ) AS valid_until
            FROM product_prices p JOIN product_variants v ON v.id = p.product_variant_id
            WHERE v.reference LIKE 'SEED-%'
        )
        SELECT 1 FROM order_items i JOIN orders o ON o.id = i.order_id
        LEFT JOIN price_bands p ON p.product_variant_id = i.product_variant_id
            AND o.created_at >= p.valid_from AND o.created_at < p.valid_until
        WHERE o.public_id LIKE 'SEED-ORDER-%'
          AND (p.id IS NULL OR i.unit_price <> p.price OR i.currency <> p.currency)
    ), 'Seeded order items must copy the price and currency in effect at checkout';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o JOIN promo_codes c ON c.id = o.promo_code_id
        JOIN promotions p ON p.id = c.promotion_id
        WHERE o.public_id LIKE 'SEED-ORDER-%'
          AND (o.created_at < p.starts_at OR o.created_at >= p.ends_at OR o.created_at < c.created_at)
    ), 'Attached promo codes and their promotions must be valid at checkout';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        WITH discounted_orders AS MATERIALIZED (
            SELECT o.id, p.id AS promotion_id, p.scope, p.percent
            FROM orders o LEFT JOIN promo_codes c ON c.id = o.promo_code_id
            LEFT JOIN promotions p ON p.id = c.promotion_id
            WHERE o.public_id LIKE 'SEED-ORDER-%'
        ), used_promotions AS (
            SELECT DISTINCT promotion_id, scope FROM discounted_orders WHERE promotion_id IS NOT NULL
        ), qualifying_products AS (
            SELECT pp.promotion_id, pp.product_id
            FROM promotion_products pp JOIN used_promotions p USING (promotion_id)
            WHERE p.scope = 'products'
            UNION
            SELECT pc.promotion_id, link.product_id
            FROM promotion_categories pc JOIN used_promotions p USING (promotion_id)
            JOIN product_categories link ON link.category_id = pc.category_id
            WHERE p.scope = 'categories'
        )
        SELECT 1 FROM order_items i JOIN discounted_orders o ON o.id = i.order_id
        JOIN product_variants v ON v.id = i.product_variant_id
        LEFT JOIN qualifying_products q ON q.promotion_id = o.promotion_id AND q.product_id = v.product_id
        WHERE i.discount_percent <> CASE WHEN o.scope = 'order' OR q.product_id IS NOT NULL
                                         THEN o.percent ELSE 0 END
    ), 'Seeded order items must receive the promotion percent only when their line qualifies';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        -- max_uses counts orders across every code of the promotion.
        SELECT 1 FROM promotions p LEFT JOIN promo_codes c ON c.promotion_id = p.id
        LEFT JOIN orders o ON o.promo_code_id = c.id
        WHERE p.max_uses IS NOT NULL
        GROUP BY p.id HAVING count(o.id) > p.max_uses
    ), 'All orders using a seeded promotion must stay within its shared max_uses';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o JOIN promo_codes c ON c.id = o.promo_code_id
        WHERE c.once_per_customer
        GROUP BY c.id, o.user_id
        HAVING o.user_id IS NULL OR count(*) > 1
    ), 'Once-per-customer codes must not be used by guests or reused by the same customer';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM orders o JOIN promo_codes c ON c.id = o.promo_code_id
        WHERE o.public_id LIKE 'SEED-ORDER-%'
          AND c.user_id IS NOT NULL AND o.user_id IS DISTINCT FROM c.user_id
    ), 'Nominative codes must be used only by the nominated customer';
END; $$;

DO $$ BEGIN
    ASSERT NOT EXISTS (
        SELECT 1 FROM (
            SELECT status, (SELECT as_of FROM pg_temp.seed_config) - created_at AS age
            FROM orders WHERE public_id LIKE 'SEED-ORDER-%'
        ) o
        WHERE CASE WHEN status = 'cancelled' THEN age < interval '1 day'
                   ELSE status <> CASE WHEN age < interval '1 day' THEN 'pending'::order_status
                                       WHEN age < interval '3 days' THEN 'paid'::order_status
                                       WHEN age < interval '7 days' THEN 'shipped'::order_status
                                       ELSE 'delivered'::order_status END
              END
    ), 'Seeded order status must match its age at as_of';
END; $$;
