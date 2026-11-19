SELECT setseed(0.42);

CREATE TEMP TABLE seed_config ON COMMIT DROP AS
SELECT now()::timestamp AS as_of,
       ceil(50000 * scale)::bigint AS n_users,
       ceil(5000 * scale)::bigint AS n_products,
       ceil(30000 * scale)::bigint AS n_carts,
       ceil(500000 * scale)::bigint AS n_orders,
       3 * ceil(20 * scale)::bigint AS n_campaigns,
       ceil(100 * scale)::bigint AS n_brands,
       ceil(20 * scale)::bigint AS n_branches
FROM (VALUES (:'scale'::numeric)) AS input(scale);
ALTER TABLE seed_config ADD CHECK (n_users > 0 AND n_users < 100000000000 AND n_orders > 0);

WITH signups AS (
    SELECT n, as_of - interval '3 years'
        + (as_of - (as_of - interval '3 years') - interval '4 hours') * random() AS created_at
    FROM seed_config CROSS JOIN LATERAL generate_series(1, n_users) AS g(n)
    ORDER BY n
)
INSERT INTO users (id, email, phone, password_hash, first_name, last_name, username, is_active, created_at, updated_at)
SELECT md5('seed:user:' || n)::uuid, 'client' || n || '@example.test', '+999' || lpad(n::text, 11, '0'), '!',
       (ARRAY['Camille', 'Sam', 'Lou', 'Alex'])[1 + n % 4], 'Test ' || n,
       'seed-client-' || n, n % 20 <> 0, created_at, created_at + interval '1 hour' * (n % 4)
FROM signups;

INSERT INTO addresses (id, user_id, name, address, city, state, postal_code, country_code, created_at, updated_at)
SELECT md5('seed:address:' || n || ':' || a)::uuid, u.id,
       (ARRAY['Domicile', 'Travail', 'Autre'])[a],
       n || (ARRAY[' rue des Exemples', ' Beispielstraße', ' calle de los Ejemplos'])[c] || ', adresse ' || a,
       (ARRAY[['Paris', 'Lyon', 'Nantes'], ['Berlin', 'München', 'Hamburg'], ['Madrid', 'Barcelona', 'Sevilla']])[c][a],
       CASE WHEN a = 2 THEN (ARRAY['Auvergne-Rhône-Alpes', 'Bayern', 'Cataluña'])[c] END,
       (ARRAY[['75001', '69001', '44000'], ['10115', '80331', '20095'], ['28001', '08001', '41001']])[c][a],
       (ARRAY['FR', 'DE', 'ES'])[c],
       u.created_at + interval '1 hour' * a, u.created_at + interval '1 hour' * a
FROM seed_config CROSS JOIN LATERAL generate_series(1, n_users) AS g(n)
JOIN users u ON u.id = md5('seed:user:' || n)::uuid
CROSS JOIN LATERAL (VALUES (1 + n / 3 % 3)) AS country(c) -- one country per user, decorrelated from address count, orders copy it from the address
CROSS JOIN LATERAL generate_series(1, 1 + (n - 1) % 3) AS slots(a);
