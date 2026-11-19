INSERT INTO brands (id, name, commercial_name, created_at, updated_at)
SELECT md5('seed:brand:' || n)::uuid, 'Atelier ' || n, 'Seed Atelier ' || n, as_of - interval '3 years 1 day', as_of - interval '3 years 1 day'
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_brands) AS g(n);

INSERT INTO categories (id, name)
VALUES (md5('seed:category:root')::uuid, 'Seed Mobilier racine');

INSERT INTO categories (id, name, parent_id)
SELECT md5('seed:category:branch:' || n)::uuid, 'Seed Mobilier famille ' || n, md5('seed:category:root')::uuid
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_branches) AS g(n);

INSERT INTO categories (id, name, parent_id)
SELECT md5('seed:category:leaf:' || n)::uuid, 'Seed Mobilier gamme ' || n,
       md5('seed:category:branch:' || (1 + (n - 1) / 4))::uuid
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_branches * 4) AS g(n);

INSERT INTO products (id, name, brand_id, created_at, updated_at)
SELECT md5('seed:product:' || n)::uuid,
       (ARRAY['Chaise', 'Table', 'Étagère', 'Bureau'])[1 + (n - 1) % 4] || ' modèle ' || n,
       md5('seed:brand:' || (1 + (n - 1) / 4 % n_brands))::uuid,
       as_of - interval '3 years 1 day', as_of - interval '3 years 1 day'
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_products) AS g(n);

INSERT INTO product_categories (id, product_id, category_id)
SELECT md5('seed:product_category:' || n)::uuid, md5('seed:product:' || n)::uuid,
       md5('seed:category:leaf:' || (1 + (n - 1) % (n_branches * 4)))::uuid
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_products) AS g(n);

INSERT INTO product_variants (id, product_id, reference, height, color, created_at, updated_at)
SELECT md5('seed:variant:' || n || ':' || v)::uuid, md5('seed:product:' || n)::uuid,
       'SEED-' || n || '-' || v, (70 + n % 50) || ' cm', (ARRAY['Naturel', 'Noir', 'Blanc', 'Bleu'])[v],
       as_of - interval '3 years 1 day', as_of - interval '3 years 1 day'
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_products) AS g(n)
CROSS JOIN generate_series(1, 4) AS variants(v);

INSERT INTO product_prices (id, product_variant_id, price, currency, valid_from)
SELECT md5('seed:price:' || n || ':' || v || ':' || p)::uuid,
       md5('seed:variant:' || n || ':' || v)::uuid, 19.90 + n % 200 + 5 * v + 4 * (p - 1), 'EUR',
       as_of - interval '3 years 1 day' + interval '9 months' * (p - 1)
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_products) AS g(n)
CROSS JOIN generate_series(1, 4) AS variants(v)
CROSS JOIN LATERAL generate_series(1, (ARRAY[1, 3, 4, 4])[v]) AS prices(p);
